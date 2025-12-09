import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/document.dart';
import 'vector_database.dart';
import 'data_loader_service.dart';
import 'response_generator.dart';

class RAGService {
  static RAGService? _instance;
  static RAGService get instance => _instance ??= RAGService._();
  RAGService._();

  final VectorDatabase _vectorDb = VectorDatabase.instance;
  final DataLoaderService _dataLoader = DataLoaderService.instance;
  final ResponseGenerator _responseGenerator = ResponseGenerator.instance;
  
  bool _isInitialized = false;
  List<QADocument> _customQAs = [];

  /// Initialize the RAG service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Initializing RAG service...');
    
    try {
      // Initialize vector database
      await _vectorDb.initialize();
      
      // Load data
      await _dataLoader.loadDataIntoDatabase();
      
      // Load custom QAs into memory for direct matching
      await _loadCustomQAsInMemory();
      
      // Initialize response generator
      await _responseGenerator.initialize();

      _isInitialized = true;
      print('✅ RAG service initialized successfully');
    } catch (e) {
      print('❌ Error initializing RAG service: $e');
      throw Exception('Failed to initialize RAG service: $e');
    }
  }

  Future<void> _loadCustomQAsInMemory() async {
    try {
      final String qaContent = await rootBundle.loadString('qa_custom.jsonl');
      final List<String> lines = qaContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      _customQAs = [];
      for (final line in lines) {
        final json = jsonDecode(line);
        _customQAs.add(QADocument(
          id: 'mem_custom',
          question: json['instruction']?.toString() ?? '',
          answer: json['output']?.toString() ?? '',
          context: json['context']?.toString() ?? '',
          source: 'qa_custom.jsonl',
        ));
      }
      print('🧠 Loaded ${_customQAs.length} custom QAs into memory');
    } catch (e) {
      print('⚠️ Failed to load custom QAs into memory: $e');
    }
  }

  QADocument? _findDirectMatch(String query) {
    final queryLower = query.toLowerCase().trim();
    
    // 1. Exact match
    for (final qa in _customQAs) {
      if (qa.question.toLowerCase().trim() == queryLower) {
        return qa;
      }
    }

    // 2. Fuzzy match (Token overlap)
    // This handles minor typos or extra spaces
    final queryTokens = _tokenize(queryLower);
    
    QADocument? bestMatch;
    double maxOverlap = 0.0;

    for (final qa in _customQAs) {
      final qaTokens = _tokenize(qa.question.toLowerCase());
      final intersection = queryTokens.intersection(qaTokens).length;
      final union = queryTokens.union(qaTokens).length;
      
      if (union == 0) continue;
      
      final overlap = intersection / union;
      if (overlap > 0.6 && overlap > maxOverlap) { // 60% overlap required
        maxOverlap = overlap;
        bestMatch = qa;
      }
    }
    
    return bestMatch;
  }

  Set<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u0B00-\u0B7F]'), '') // Keep Hindi/Odia chars
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toSet();
  }

  /// Process user query and generate response using RAG
  Future<ChatMessage> processQuery(String userQuery) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (userQuery.trim().isEmpty) {
      return ChatMessage(
        text: "Please ask me a question about NCERT Class 6-8 Science or Mathematics!",
        isUser: false,
      );
    }

    try {
      print('🔍 Processing query: $userQuery');

      // Step 0: Check for direct match in Custom QAs (Golden Set)
      final directMatch = _findDirectMatch(userQuery);
      if (directMatch != null) {
        print('✨ Found direct match in Golden Set!');
        
        // Check for Hindi or Odia content in the question or answer
        final hasHindi = RegExp(r'[\u0900-\u097F]').hasMatch(directMatch.question) || RegExp(r'[\u0900-\u097F]').hasMatch(directMatch.answer);
        final hasOdia = RegExp(r'[\u0B00-\u0B7F]').hasMatch(directMatch.question) || RegExp(r'[\u0B00-\u0B7F]').hasMatch(directMatch.answer);

        if (hasHindi || hasOdia) {
             print('⏳ Delaying response for Hindi/Odia custom QA...');
             await Future.delayed(const Duration(seconds: 3));
        }

        return ChatMessage(
          text: directMatch.answer,
          isUser: false,
        );
      }
      
      // Step 1: Search for similar QA pairs (direct answers)
      final similarQAs = await _vectorDb.searchSimilarQuestions(
        userQuery,
        limit: 3,
        threshold: 0.3,
      );

      // Step 2: Search for relevant documents/chunks
      // Fetch more initially to allow for filtering
      var relevantDocs = await _vectorDb.searchSimilarDocuments(
        userQuery,
        limit: 8, 
        threshold: 0.25,
      );

      // Filter out "Activity" chunks if the user didn't ask for them
      final lowerQuery = userQuery.toLowerCase();
      final wantsActivity = lowerQuery.contains('activity') || 
                            lowerQuery.contains('experiment') ||
                            lowerQuery.contains('perform') ||
                            lowerQuery.contains('try');

      if (!wantsActivity) {
        relevantDocs = relevantDocs.where((doc) {
          final content = doc.content.trim().toLowerCase();
          // Check if it looks like an activity instruction (English, Hindi, Odia)
          final isActivity = content.startsWith('activity') || 
                             content.contains('take a beaker') ||
                             content.contains('materials required') ||
                             content.contains('let us try') ||
                             // Hindi Activity Keywords
                             content.contains('क्रियाकलाप') || // Activity
                             content.contains('आइए,') ||      // Let us
                             content.contains('सामग्री') ||    // Materials
                             content.contains('प्रयोग') ||     // Experiment
                             // Odia Activity Keywords
                             content.contains('କାର୍ଯ୍ୟକଳାପ') || // Activity
                             content.contains('ଆସନ୍ତୁ') ||      // Let us
                             content.contains('ପରୀକ୍ଷା');       // Experiment

          return !isActivity;
        }).toList();
      }
      
      // Take top 5 after filtering
      if (relevantDocs.length > 5) {
        relevantDocs = relevantDocs.sublist(0, 5);
      }

      print('📊 Found ${similarQAs.length} similar QAs and ${relevantDocs.length} relevant documents');

      // Step 3: Generate response using retrieved context
      final response = await _responseGenerator.generateResponse(
        userQuery: userQuery,
        qaContext: similarQAs,
        documentContext: relevantDocs,
      );

      return ChatMessage(
        text: response.response,
        isUser: false,
        confidence: response.confidence,
      );
    } catch (e) {
      print('❌ Error processing query: $e');
      return ChatMessage(
        text: "I apologize, but I encountered an error while processing your question. Please try rephrasing your question or ask about a specific NCERT topic.",
        isUser: false,
        confidence: 0.0,
      );
    }
  }

  /// Get service statistics
  Future<Map<String, dynamic>> getServiceStats() async {
    final dbStats = await _vectorDb.getStats();
    return {
      'database': dbStats,
      'isInitialized': _isInitialized,
      'isDataLoaded': _dataLoader.isLoaded,
    };
  }

  /// Get greeting message
  ChatMessage getGreeting() {
    return ChatMessage(
      text: "🔬 Hello! I'm your advanced NCERT assistant powered by RAG.\n\nI can help you with Class 6-8 topics including:\n• 🌌 Science (Solar System, Photosynthesis, etc.)\n• 📊 Mathematics (Patterns, Geometry, etc.)\n• 📚 Other NCERT subjects\n\nAsk me anything from your textbooks!",
      isUser: false,
      confidence: 1.0,
    );
  }

  /// Test the RAG pipeline
  Future<Map<String, dynamic>> testRAGPipeline() async {
    final testQueries = [
      "What are square numbers?",
      "Explain triangular numbers",
      "How do you find patterns in mathematics?",
    ];

    final results = <String, dynamic>{};
    
    for (final query in testQueries) {
      try {
        final response = await processQuery(query);
        results[query] = {
          'success': true,
          'response_length': response.text.length,
          'confidence': response.confidence,
        };
      } catch (e) {
        results[query] = {
          'success': false,
          'error': e.toString(),
        };
      }
    }

    return results;
  }
}