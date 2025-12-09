import 'dart:math';

class EmbeddingService {
  static EmbeddingService? _instance;
  static EmbeddingService get instance => _instance ??= EmbeddingService._();
  EmbeddingService._();

  // Hashing Vectorizer settings
  static const int _vectorSize = 2048; // Increased size to reduce collisions further
  
  // Common English stop words to ignore
  static const Set<String> _stopWords = {
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
    'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what',
    'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me',
    'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know', 'take',
    'people', 'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see', 'other',
    'than', 'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also',
    'back', 'after', 'use', 'two', 'how', 'our', 'work', 'first', 'well', 'way',
    'even', 'new', 'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us',
    'is', 'are', 'was', 'were', 'been', 'has', 'had', 'does', 'did', 'very'
  };
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Generate embedding for text using Hashing Vectorizer approach
  /// This allows handling ANY word without a predefined vocabulary
  List<double> generateEmbedding(String text) {
    if (!_isInitialized) {
      throw Exception('EmbeddingService not initialized');
    }

    final words = _preprocessText(text);
    
    // Create embedding vector initialized to 0.0
    final embedding = List<double>.filled(_vectorSize, 0.0);
    
    if (words.isEmpty) return embedding;

    // Count word frequencies
    final wordCount = <String, double>{};
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }

    // Fill vector using hashing
    for (final entry in wordCount.entries) {
      final word = entry.key;
      final count = entry.value;
      final tf = count / words.length; // Term frequency
      
      // Use consistent hashing to map word to a vector index
      // We use multiple hash functions (simulated) to better represent the word
      final hash1 = _getHash(word, 1) % _vectorSize;
      final hash2 = _getHash(word, 2) % _vectorSize;
      
      embedding[hash1] += tf;
      embedding[hash2] += tf;
    }

    // Normalize vector (L2 normalization)
    return _normalizeVector(embedding);
  }

  /// Simple consistent hash function
  int _getHash(String text, int seed) {
    int hash = seed;
    for (int i = 0; i < text.length; i++) {
      hash = 31 * hash + text.codeUnitAt(i);
      hash &= 0xFFFFFFFF; // Keep it 32-bit
    }
    return hash.abs();
  }

  /// Calculate cosine similarity between two embeddings
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  List<String> _preprocessText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((w) => w.length > 2 && !_stopWords.contains(w)) // Filter short words and stop words
        .toList();
  }

  List<double> _normalizeVector(List<double> vector) {
    double magnitude = 0.0;
    for (final val in vector) {
      magnitude += val * val;
    }
    magnitude = sqrt(magnitude);

    if (magnitude == 0) return vector;

    return vector.map((val) => val / magnitude).toList();
  }
}