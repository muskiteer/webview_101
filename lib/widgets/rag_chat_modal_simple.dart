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

  @override
  void initState() {
    super.initState();
    _initializeRAGService();
  }

  void _initializeRAGService() async {
    try {
      setState(() {
        _messages.add(ChatMessage(
          text: "🔄 Initializing RAG system...\nLoading NCERT content and building vector database...",
          isUser: false,
        ));
      });

      await _ragService.initialize();

      setState(() {
        _messages.clear();
        _messages.add(_ragService.getGreeting());
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _messages.clear();
        _messages.add(ChatMessage(
          text: "❌ Failed to initialize RAG system: ${e.toString()}",
          isUser: false,
        ));
        _isInitializing = false;
      });
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

    try {
      final botResponse = await _ragService.processQuery(userMessage.text);
      setState(() {
        _messages.add(botResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "I encountered an error. Please try again.",
          isUser: false,
          confidence: 0.0,
        ));
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'RAG Math Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    ),
                  );
                }
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about NCERT mathematics...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading && !_isInitializing,
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  mini: true,
                  onPressed: (_isLoading || _isInitializing) ? null : _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
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