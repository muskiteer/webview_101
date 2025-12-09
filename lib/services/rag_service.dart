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

  /// Initialize the RAG service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 Initializing RAG service...');
    
    try {
      // Initialize vector database
      await _vectorDb.initialize();
      
      // Load data
      await _dataLoader.loadDataIntoDatabase();
      
      // Initialize response generator
      await _responseGenerator.initialize();

      _isInitialized = true;
      print('✅ RAG service initialized successfully');
    } catch (e) {
      print('❌ Error initializing RAG service: $e');
      throw Exception('Failed to initialize RAG service: $e');
    }
  }

  /// Process user query and generate response using RAG
  Future<ChatMessage> processQuery(String userQuery) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (userQuery.trim().isEmpty) {
      return ChatMessage(
        text: "Please ask me a question about NCERT Class 6-8 Mathematics!",
        isUser: false,
      );
    }

    try {
      print('🔍 Processing query: $userQuery');
      
      // Step 1: Search for similar QA pairs (direct answers)
      final similarQAs = await _vectorDb.searchSimilarQuestions(
        userQuery,
        limit: 3,
        threshold: 0.3,
      );

      // Step 2: Search for relevant documents/chunks
      final relevantDocs = await _vectorDb.searchSimilarDocuments(
        userQuery,
        limit: 5,
        threshold: 0.25,
      );

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
        text: "I apologize, but I encountered an error while processing your question. Please try rephrasing your question or ask about a specific NCERT mathematics topic.",
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