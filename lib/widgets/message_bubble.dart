import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: message.isUser 
              ? Theme.of(context).primaryColor
              : Colors.grey[100],
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Theme.of(context).colorScheme.onPrimary : Colors.black87,
                  fontSize: 15.0,
                  height: 1.4,
                ),
              ),
              if (!message.isUser && message.confidence != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getConfidenceIcon(message.confidence!),
                        size: 12,
                        color: _getConfidenceColor(message.confidence!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getConfidenceText(message.confidence!),
                        style: TextStyle(
                          color: _getConfidenceColor(message.confidence!),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.8) return Icons.verified;
    if (confidence >= 0.6) return Icons.check_circle_outline;
    if (confidence >= 0.4) return Icons.help_outline;
    return Icons.info_outline;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.blue;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.8) return 'High confidence';
    if (confidence >= 0.6) return 'Good match';
    if (confidence >= 0.4) return 'Related topic';
    return 'General info';
  }
}