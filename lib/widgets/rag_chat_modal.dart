import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/rag_service.dart';
import 'message_bubble.dart';

class RAGChatModal extends StatefulWidget {
  const RAGChatModal({Key? key}) : super(key: key);

  @override
  State<RAGChatModal> createState() => _RAGChatModalState();
}

class _RAGChatModalState extends State<RAGChatModal> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RAGService _ragService = RAGService.instance;
  bool _isLoading = false;
  bool _isInitializing = true;
  Map<String, dynamic>? _serviceStats;

  @override
  void initState() {
    super.initState();
    _initializeRAGService();
  }

  void _initializeRAGService() async {
    try {
      // Show initialization message
      setState(() {
        _messages.add(ChatMessage(
          text: "🔄 Initializing RAG system...\nLoading NCERT content and building vector database...",
          isUser: false,
        ));
      });

      // Initialize the RAG service
      await _ragService.initialize();

      // Get stats
      _serviceStats = await _ragService.getServiceStats();

      // Replace initialization message with greeting
      setState(() {
        _messages.clear();
        _messages.add(_ragService.getGreeting());
        _isInitializing = false;
      });

      print('✅ RAG service initialized in UI');
    } catch (e) {
      setState(() {
        _messages.clear();
        _messages.add(ChatMessage(
          text: "❌ Failed to initialize RAG system: ${e.toString()}\n\nPlease restart the app or contact support.",
          isUser: false,
        ));
        _isInitializing = false;
      });
      print('❌ RAG initialization error: $e');
    }
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty || _isLoading || _isInitializing) return;

    final userMessage = ChatMessage(
      text: _textController.text.trim(),
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    // Get RAG response
    try {
      final botResponse = await _ragService.processQuery(userMessage.text);
      setState(() {
        _messages.add(botResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "I apologize, but I encountered an error while processing your question. Please try again or rephrase your question.",
          isUser: false,
          confidence: 0.0,
        ));
        _isLoading = false;
      });
      print('Error in RAG processing: $e');
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showStatsDialog() async {
    final stats = await _ragService.getServiceStats();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 RAG System Stats'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Documents: ${stats['database']['documents']}'),
              Text('QA Pairs: ${stats['database']['qa_pairs']}'),
              Text('Embeddings: ${stats['database']['embeddings']}'),
              const SizedBox(height: 8),
              Text('Initialized: ${stats['isInitialized']}'),
              Text('Data Loaded: ${stats['isDataLoaded']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).colorScheme.onPrimary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dronacharya',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Powered by Vector Database',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: _showStatsDialog,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Searching vector database...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          
          // Input field
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about NCERT mathematics...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoading && !_isInitializing,
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: (_isLoading || _isInitializing) ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}