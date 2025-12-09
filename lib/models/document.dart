class Document {
  final String id;
  final String content;
  final String source;
  final Map<String, dynamic> metadata;

  Document({
    required this.id,
    required this.content,
    required this.source,
    this.metadata = const {},
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      source: json['source']?.toString() ?? json['source_chunk_id']?.toString() ?? '',
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'source': source,
      'metadata': metadata,
    };
  }
}

class QADocument {
  final String id;
  final String question;
  final String answer;
  final String context;
  final String source;

  QADocument({
    required this.id,
    required this.question,
    required this.answer,
    required this.context,
    required this.source,
  });

  factory QADocument.fromJson(Map<String, dynamic> json) {
    return QADocument(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      question: json['instruction']?.toString() ?? '',
      answer: json['output']?.toString() ?? '',
      context: json['context']?.toString() ?? '',
      source: json['source_chunk_id']?.toString() ?? '',
    );
  }
}

class VectorDocument {
  final String id;
  final String content;
  final List<double> embedding;
  final String source;
  final Map<String, dynamic> metadata;

  VectorDocument({
    required this.id,
    required this.content,
    required this.embedding,
    required this.source,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'embedding': embedding,
      'source': source,
      'metadata': metadata,
    };
  }

  factory VectorDocument.fromJson(Map<String, dynamic> json) {
    return VectorDocument(
      id: json['id'],
      content: json['content'],
      embedding: List<double>.from(json['embedding']),
      source: json['source'],
      metadata: json['metadata'] ?? {},
    );
  }
}