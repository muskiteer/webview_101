import '../models/document.dart';

class GeneratedResponse {
  final String response;
  final double confidence;
  final List<String> sources;

  GeneratedResponse({
    required this.response,
    required this.confidence,
    this.sources = const [],
  });
}

class ResponseGenerator {
  static ResponseGenerator? _instance;
  static ResponseGenerator get instance => _instance ??= ResponseGenerator._();
  ResponseGenerator._();

  final List<String> _greetingWords = ['hello', 'hi', 'hey', 'good morning', 'good afternoon'];
  final List<String> _questionWords = ['what', 'how', 'why', 'when', 'where', 'explain', 'define', 'calculate'];

  Future<void> initialize() async {
    // Initialization if needed
  }

  /// Generate response using retrieved context
  Future<GeneratedResponse> generateResponse({
    required String userQuery,
    required List<QADocument> qaContext,
    required List<VectorDocument> documentContext,
  }) async {
    
    // Handle greetings
    if (_isGreeting(userQuery)) {
      return GeneratedResponse(
        response: "Hello! I'm here to help you with NCERT Class 6-8 Mathematics. What would you like to learn about?",
        confidence: 1.0,
      );
    }

    // Priority 1: Use direct QA matches if confidence is high
    if (qaContext.isNotEmpty) {
      final bestQA = qaContext.first;
      if (_calculateQARelevance(userQuery, bestQA) > 0.6) {
        return GeneratedResponse(
          response: _formatQAResponse(bestQA, userQuery),
          confidence: 0.9,
          sources: [bestQA.source],
        );
      }
    }

    // Priority 2: Use multiple QA responses if moderately relevant
    if (qaContext.length >= 2) {
      final combinedResponse = _combineQAResponses(qaContext, userQuery);
      if (combinedResponse.isNotEmpty) {
        return GeneratedResponse(
          response: combinedResponse,
          confidence: 0.7,
          sources: qaContext.map((qa) => qa.source).toList(),
        );
      }
    }

    // Priority 3: Use document context to create response
    if (documentContext.isNotEmpty) {
      final documentResponse = _generateFromDocuments(documentContext, userQuery);
      return GeneratedResponse(
        response: documentResponse,
        confidence: 0.6,
        sources: documentContext.map((doc) => doc.source).toList(),
      );
    }

    // Priority 4: Single QA with lower confidence
    if (qaContext.isNotEmpty) {
      final bestQA = qaContext.first;
      return GeneratedResponse(
        response: _formatQAResponse(bestQA, userQuery, lowConfidence: true),
        confidence: 0.4,
        sources: [bestQA.source],
      );
    }

    // Fallback: No relevant context found
    return _generateFallbackResponse(userQuery);
  }

  bool _isGreeting(String query) {
    final lowerQuery = query.toLowerCase();
    return _greetingWords.any((greeting) => lowerQuery.contains(greeting)) &&
           !_questionWords.any((question) => lowerQuery.contains(question));
  }

  double _calculateQARelevance(String query, QADocument qa) {
    final queryWords = _extractKeywords(query);
    final questionWords = _extractKeywords(qa.question);
    
    final intersection = queryWords.intersection(questionWords);
    final union = queryWords.union(questionWords);
    
    if (union.isEmpty) return 0.0;
    return intersection.length / union.length;
  }

  Set<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 2)
        .where((word) => !['the', 'and', 'are', 'for', 'that', 'this', 'with'].contains(word))
        .toSet();
  }

  String _formatQAResponse(QADocument qa, String userQuery, {bool lowConfidence = false}) {
    String response = qa.answer;
    
    if (lowConfidence) {
      response = "Based on similar topics in NCERT mathematics:\n\n$response";
    }
    
    // Add context if it provides additional value
    if (qa.context.isNotEmpty && qa.context != qa.answer) {
      final contextSnippet = qa.context.length > 150 
          ? qa.context.substring(0, 150) + "..."
          : qa.context;
      
      response += "\n\n📚 Context: $contextSnippet";
    }
    
    return response;
  }

  String _combineQAResponses(List<QADocument> qaDocuments, String userQuery) {
    if (qaDocuments.isEmpty) return '';
    
    final primaryAnswer = qaDocuments.first.answer;
    final additionalPoints = <String>[];
    
    for (int i = 1; i < qaDocuments.length && i < 3; i++) {
      final qa = qaDocuments[i];
      if (qa.answer != primaryAnswer && qa.answer.length > 20) {
        additionalPoints.add(qa.answer);
      }
    }
    
    String response = primaryAnswer;
    
    if (additionalPoints.isNotEmpty) {
      response += "\n\n🔍 Related concepts:\n";
      for (int i = 0; i < additionalPoints.length; i++) {
        response += "• ${additionalPoints[i]}\n";
      }
    }
    
    return response;
  }

  String _generateFromDocuments(List<VectorDocument> documents, String userQuery) {
    if (documents.isEmpty) return '';
    
    // Find most relevant document
    final primaryDoc = documents.first;
    String content = primaryDoc.content;
    
    // Extract relevant portion based on query
    final relevantSnippet = _extractRelevantSnippet(content, userQuery);
    
    String response = "Based on NCERT content:\n\n$relevantSnippet";
    
    // Add related information from other documents
    if (documents.length > 1) {
      response += "\n\n📖 Additional information:";
      for (int i = 1; i < documents.length && i < 3; i++) {
        final snippet = _extractRelevantSnippet(documents[i].content, userQuery, maxLength: 100);
        if (snippet.isNotEmpty) {
          response += "\n• $snippet";
        }
      }
    }
    
    response += "\n\nWould you like me to explain any specific part of this topic?";
    
    return response;
  }

  String _extractRelevantSnippet(String content, String query, {int maxLength = 200}) {
    final queryWords = _extractKeywords(query);
    final sentences = content.split('.');
    
    // Find sentence with most query words
    String bestSentence = '';
    int maxMatches = 0;
    
    for (final sentence in sentences) {
      final sentenceWords = _extractKeywords(sentence);
      final matches = queryWords.intersection(sentenceWords).length;
      
      if (matches > maxMatches && sentence.trim().length > 20) {
        maxMatches = matches;
        bestSentence = sentence.trim();
      }
    }
    
    if (bestSentence.isEmpty) {
      // Fallback: take beginning of content
      bestSentence = content.length > maxLength 
          ? content.substring(0, maxLength)
          : content;
    }
    
    if (bestSentence.length > maxLength) {
      bestSentence = bestSentence.substring(0, maxLength) + "...";
    }
    
    return bestSentence;
  }

  GeneratedResponse _generateFallbackResponse(String userQuery) {
    final keywords = _extractKeywords(userQuery);
    final mathKeywords = ['pattern', 'number', 'sequence', 'math', 'geometry', 'shape'];
    
    final hasMathKeywords = keywords.any((k) => mathKeywords.contains(k));
    
    String response;
    if (hasMathKeywords) {
      response = "I understand you're asking about mathematics, but I couldn't find specific information about your question in the NCERT content.\n\n";
      response += "🔍 I can help with topics like:\n";
      response += "• Number patterns and sequences\n";
      response += "• Geometric shapes and properties\n";
      response += "• Mathematical operations\n";
      response += "• NCERT Class 6-8 concepts\n\n";
      response += "Could you rephrase your question or ask about a specific topic?";
    } else {
      response = "I'm specialized in NCERT Class 6-8 Mathematics. Please ask me about:\n\n";
      response += "📊 Numbers and patterns\n";
      response += "🔷 Shapes and geometry\n";
      response += "🧮 Mathematical operations\n";
      response += "📚 NCERT textbook topics\n\n";
      response += "What mathematics topic would you like to explore?";
    }
    
    return GeneratedResponse(
      response: response,
      confidence: 0.3,
    );
  }
}