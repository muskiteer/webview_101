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
      // Load English chunks
      await _loadChunks('chunks.jsonl', 'en');
      
      // Try loading Hindi chunks (if available)
      try {
        await _loadChunks('chunkshi.jsonl', 'hi');
        print('✅ Loaded Hindi content');
      } catch (_) {
        print('ℹ️ No Hindi content found (chunkshi.jsonl)');
      }

      // Try loading Odia chunks (if available)
      try {
        await _loadChunks('chunksodi.jsonl', 'or');
        print('✅ Loaded Odia content');
      } catch (_) {
        print('ℹ️ No Odia content found (chunksodi.jsonl)');
      }
      
      // Load QA pairs
      await _loadQAPairs();
      
      // Load Custom QA pairs (Golden Set)
      try {
        await _loadCustomQAPairs();
        print('✅ Loaded Custom QA pairs');
      } catch (_) {
        print('ℹ️ No Custom QA pairs found');
      }

      final finalStats = await _vectorDb.getStats();
      print('✅ Data loading completed: $finalStats');
      _isLoaded = true;
    } catch (e) {
      print('❌ Error loading data: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  Future<void> _loadChunks(String filename, String language) async {
    try {
      final String chunksContent = await rootBundle.loadString(filename);
      final List<String> lines = chunksContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      print('📄 Processing ${lines.length} chunks from $filename...');

      int processedCount = 0;
      for (final line in lines) {
        try {
          final Map<String, dynamic> json = jsonDecode(line);
          
          // Add language to metadata
          final metadata = <String, dynamic>{
            'type': 'chunk',
            'original_line': processedCount,
            'language': language,
          };

          final document = Document(
            id: json['id']?.toString() ?? '${language}_chunk_${processedCount}',
            content: json['content']?.toString() ?? json['text']?.toString() ?? '',
            source: filename,
            metadata: metadata,
          );

          if (document.content.isNotEmpty) {
            await _vectorDb.addDocument(document);
            processedCount++;
            
            if (processedCount % 50 == 0) {
              print('📄 Processed $processedCount chunks from $filename...');
            }
          }
        } catch (e) {
          print('⚠️ Error processing chunk line ${processedCount + 1} in $filename: $e');
        }
      }

      print('✅ Loaded $processedCount chunks from $filename successfully');
    } catch (e) {
      print('❌ Error loading chunks: $e');
    }
  }

  Future<void> _loadCustomQAPairs() async {
    try {
      final String qaContent = await rootBundle.loadString('qa_custom.jsonl');
      final List<String> lines = qaContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      print('🌟 Processing ${lines.length} Custom QA pairs...');

      int processedCount = 0;
      for (final line in lines) {
        try {
          final Map<String, dynamic> json = jsonDecode(line);
          
          final qaDoc = QADocument(
            id: 'qa_custom_${processedCount}',
            question: json['instruction']?.toString() ?? '',
            answer: json['output']?.toString() ?? '',
            context: json['context']?.toString() ?? '',
            source: 'qa_custom.jsonl',
          );

          if (qaDoc.question.isNotEmpty && qaDoc.answer.isNotEmpty) {
            await _vectorDb.addQADocument(qaDoc);
            processedCount++;
          }
        } catch (e) {
          print('⚠️ Error processing Custom QA line ${processedCount + 1}: $e');
        }
      }

      print('✅ Loaded $processedCount Custom QA pairs successfully');
    } catch (e) {
      print('❌ Error loading Custom QA pairs: $e');
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