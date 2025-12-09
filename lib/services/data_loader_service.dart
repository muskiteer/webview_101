import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/document.dart';
import 'vector_database.dart';

class DataLoaderService {
  static DataLoaderService? _instance;
  static DataLoaderService get instance => _instance ??= DataLoaderService._();
  DataLoaderService._();

  final VectorDatabase _vectorDb = VectorDatabase.instance;
  bool _isLoaded = false;

  /// Load all data from JSONL files into the vector database
  Future<void> loadDataIntoDatabase() async {
    if (_isLoaded) return;

    print('🔄 Loading data into vector database...');
    await _vectorDb.initialize();

    // Check if data already exists
    final stats = await _vectorDb.getStats();
    if (stats['documents']! > 0 || stats['qa_pairs']! > 0) {
      print('📊 Data already exists in database: $stats');
      _isLoaded = true;
      return;
    }

    try {
      // Load chunks
      await _loadChunks();
      
      // Load QA pairs
      await _loadQAPairs();

      final finalStats = await _vectorDb.getStats();
      print('✅ Data loading completed: $finalStats');
      _isLoaded = true;
    } catch (e) {
      print('❌ Error loading data: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  Future<void> _loadChunks() async {
    try {
      final String chunksContent = await rootBundle.loadString('chunks.jsonl');
      final List<String> lines = chunksContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      print('📄 Processing ${lines.length} chunks...');

      int processedCount = 0;
      for (final line in lines) {
        try {
          final Map<String, dynamic> json = jsonDecode(line);
          
          final document = Document(
            id: json['id']?.toString() ?? 'chunk_${processedCount}',
            content: json['content']?.toString() ?? json['text']?.toString() ?? '',
            source: 'chunks.jsonl',
            metadata: {
              'type': 'chunk',
              'original_line': processedCount,
            },
          );

          if (document.content.isNotEmpty) {
            await _vectorDb.addDocument(document);
            processedCount++;
            
            if (processedCount % 50 == 0) {
              print('📄 Processed $processedCount chunks...');
            }
          }
        } catch (e) {
          print('⚠️ Error processing chunk line ${processedCount + 1}: $e');
        }
      }

      print('✅ Loaded $processedCount chunks successfully');
    } catch (e) {
      print('❌ Error loading chunks: $e');
    }
  }

  Future<void> _loadQAPairs() async {
    try {
      final String qaContent = await rootBundle.loadString('qa_synthetic.jsonl');
      final List<String> lines = qaContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      print('🤖 Processing ${lines.length} QA pairs...');

      int processedCount = 0;
      for (final line in lines) {
        try {
          final Map<String, dynamic> json = jsonDecode(line);
          
          final qaDoc = QADocument(
            id: 'qa_${processedCount}',
            question: json['instruction']?.toString() ?? '',
            answer: json['output']?.toString() ?? '',
            context: json['context']?.toString() ?? '',
            source: json['source_chunk_id']?.toString() ?? 'qa_synthetic.jsonl',
          );

          if (qaDoc.question.isNotEmpty && qaDoc.answer.isNotEmpty) {
            await _vectorDb.addQADocument(qaDoc);
            processedCount++;
            
            if (processedCount % 20 == 0) {
              print('🤖 Processed $processedCount QA pairs...');
            }
          }
        } catch (e) {
          print('⚠️ Error processing QA line ${processedCount + 1}: $e');
        }
      }

      print('✅ Loaded $processedCount QA pairs successfully');
    } catch (e) {
      print('❌ Error loading QA pairs: $e');
    }
  }

  /// Reset and reload all data
  Future<void> resetAndReload() async {
    print('🔄 Resetting database and reloading...');
    await _vectorDb.clearAll();
    _isLoaded = false;
    await loadDataIntoDatabase();
  }

  /// Get loading status
  bool get isLoaded => _isLoaded;

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    await _vectorDb.initialize();
    return await _vectorDb.getStats();
  }
}