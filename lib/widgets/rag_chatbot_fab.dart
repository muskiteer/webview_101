import 'package:flutter/material.dart';
import 'rag_chat_modal_simple.dart';

class RAGChatbotFAB extends StatelessWidget {
  const RAGChatbotFAB({Key? key}) : super(key: key);

  void _showChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RAGChatModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showChatModal(context),
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(
        Icons.psychology,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}