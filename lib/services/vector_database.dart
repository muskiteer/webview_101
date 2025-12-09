import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document.dart';
import 'embedding_service.dart';

class VectorDatabase {
  static VectorDatabase? _instance;
  static VectorDatabase get instance => _instance ??= VectorDatabase._();
  VectorDatabase._();

  Database? _database;
  final EmbeddingService _embeddingService = EmbeddingService.instance;

  Future<void> initialize() async {
    if (_database != null) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'rag_chatbot.db');

    _database = await openDatabase(
      path,
      version: 7, // Bump version to force recreation with new stop words
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop all tables and recreate
        await db.execute('DROP TABLE IF EXISTS embeddings');
        await db.execute('DROP TABLE IF EXISTS documents');
        await db.execute('DROP TABLE IF EXISTS qa_pairs');
        await _createTables(db, newVersion);
      },
    );

    await _embeddingService.initialize();
  }

  Future<void> _createTables(Database db, int version) async {
    // Documents table for raw content
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        source TEXT NOT NULL,
        metadata TEXT,
        created_at INTEGER
      )
    ''');

    // Vector embeddings table
    await db.execute('''
      CREATE TABLE embeddings (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        embedding TEXT NOT NULL,
        content_preview TEXT,
        FOREIGN KEY (document_id) REFERENCES documents (id)
      )
    ''');

    // QA pairs table
    await db.execute('''
      CREATE TABLE qa_pairs (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        context TEXT,
        source TEXT,
        embedding TEXT,
        created_at INTEGER
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_embeddings_document_id ON embeddings(document_id)');
    await db.execute('CREATE INDEX idx_qa_source ON qa_pairs(source)');
  }

  /// Add a document to the vector database
  Future<void> addDocument(Document document) async {
    if (_database == null) throw Exception('Database not initialized');

    // Generate embedding
    final embedding = _embeddingService.generateEmbedding(document.content);

    await _database!.transaction((txn) async {
      // Insert document
      await txn.insert('documents', {
        'id': document.id,
        'content': document.content,
        'source': document.source,
        'metadata': jsonEncode(document.metadata),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Insert embedding
      await txn.insert('embeddings', {
        'id': '${document.id}_emb',
        'document_id': document.id,
        'embedding': jsonEncode(embedding),
        'content_preview': document.content.length > 100 
            ? document.content.substring(0, 100) + '...'
            : document.content,
      });
    });
  }

  /// Add QA document to the database
  Future<void> addQADocument(QADocument qaDoc) async {
    if (_database == null) throw Exception('Database not initialized');

    final questionEmbedding = _embeddingService.generateEmbedding(qaDoc.question);

    await _database!.insert('qa_pairs', {
      'id': qaDoc.id,
      'question': qaDoc.question,
      'answer': qaDoc.answer,
      'context': qaDoc.context,
      'source': qaDoc.source,
      'embedding': jsonEncode(questionEmbedding),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Search for similar documents using vector similarity
  Future<List<VectorDocument>> searchSimilarDocuments(String query, {int limit = 5, double threshold = 0.3}) async {
    if (_database == null) throw Exception('Database not initialized');

    final queryEmbedding = _embeddingService.generateEmbedding(query);
    
    // Get all embeddings from database
    final results = await _database!.rawQuery('''
      SELECT e.document_id, e.embedding, e.content_preview, d.content, d.source, d.metadata
      FROM embeddings e
      JOIN documents d ON e.document_id = d.id
    ''');

    List<Map<String, dynamic>> similarities = [];

    for (final row in results) {
      try {
        final embedding = List<double>.from(jsonDecode(row['embedding'] as String));
        final similarity = _embeddingService.calculateSimilarity(queryEmbedding, embedding);
        
        if (similarity >= threshold) {
          similarities.add({
            'document_id': row['document_id'],
            'content': row['content'],
            'source': row['source'],
            'metadata': jsonDecode(row['metadata'] as String? ?? '{}'),
            'similarity': similarity,
            'embedding': embedding,
          });
        }
      } catch (e) {
        print('Error processing embedding for document ${row['document_id']}: $e');
      }
    }

    // Sort by similarity and take top results
    similarities.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
    
    return similarities.take(limit).map((item) => VectorDocument(
      id: item['document_id'],
      content: item['content'],
      embedding: item['embedding'],
      source: item['source'],
      metadata: item['metadata'],
    )).toList();
  }

  /// Search for similar QA pairs
  Future<List<QADocument>> searchSimilarQuestions(String query, {int limit = 3, double threshold = 0.4}) async {
    if (_database == null) throw Exception('Database not initialized');

    final queryEmbedding = _embeddingService.generateEmbedding(query);
    
    final results = await _database!.query('qa_pairs');
    List<Map<String, dynamic>> similarities = [];

    for (final row in results) {
      try {
        final embedding = List<double>.from(jsonDecode(row['embedding'] as String));
        final similarity = _embeddingService.calculateSimilarity(queryEmbedding, embedding);
        
        if (similarity >= threshold) {
          similarities.add({
            'id': row['id'],
            'question': row['question'],
            'answer': row['answer'],
            'context': row['context'],
            'source': row['source'],
            'similarity': similarity,
          });
        }
      } catch (e) {
        print('Error processing QA embedding: $e');
      }
    }

    similarities.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
    
    return similarities.take(limit).map((item) => QADocument(
      id: item['id'],
      question: item['question'],
      answer: item['answer'],
      context: item['context'],
      source: item['source'],
    )).toList();
  }

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    if (_database == null) throw Exception('Database not initialized');

    final docCount = Sqflite.firstIntValue(await _database!.rawQuery('SELECT COUNT(*) FROM documents')) ?? 0;
    final qaCount = Sqflite.firstIntValue(await _database!.rawQuery('SELECT COUNT(*) FROM qa_pairs')) ?? 0;
    final embCount = Sqflite.firstIntValue(await _database!.rawQuery('SELECT COUNT(*) FROM embeddings')) ?? 0;

    return {
      'documents': docCount,
      'qa_pairs': qaCount,
      'embeddings': embCount,
    };
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    if (_database == null) return;

    await _database!.transaction((txn) async {
      await txn.delete('embeddings');
      await txn.delete('qa_pairs');
      await txn.delete('documents');
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}