import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import './replyItem.dart';
import 'package:showbizapp/components/replyItem.dart';


class CommentIte extends StatelessWidget {
  final Map comment;
  final List replies;
  final bool isDarkMode;
  final String actualSubscriberId;
  final Function(String, String) onReply;
  final Function(String, String, String) onEdit;
  final Function(String) onDelete;

  const CommentIte({
    required this.comment,
    required this.replies,
    required this.isDarkMode,
    required this.actualSubscriberId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final commentId = comment['comment_id'].toString();
    final commentSubscriberId = _cleanSubscriberId(comment['subscriber_id'].toString());
    final isCurrentUser = commentSubscriberId == actualSubscriberId;
    final commenterName = comment['subscriber_name'] ?? 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange,
                radius: 20,
                child: Text(
                  commenterName.isNotEmpty ? commenterName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commenterName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Html(
                      data: comment['text'] ?? '',
                      style: {
                        'body': Style(color: isDarkMode ? Colors.white : Colors.black),
                        'p': Style(color: isDarkMode ? Colors.white : Colors.black),
                      },
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => onReply(commentId, commenterName),
                          child: const Text("Reply", style: TextStyle(fontSize: 12)),
                        ),
                        if (isCurrentUser) ...[
                          TextButton(
                            onPressed: () => onEdit(commentId, commenterName, comment['text']),
                            child: const Text("Edit", style: TextStyle(fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () => onDelete(commentId),
                            child: const Text('Delete', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                final reply = replies[index];
                return ReplyIte(
                  reply: reply,
                  isDarkMode: isDarkMode,
                  isLast: index == replies.length - 1,
                );
              },
            ),
          ),
      ],
    );
  }
  String _cleanSubscriberId(String id) {
    if (id.startsWith('{subscriber_id: ')) {
      return id.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }
    return id;
  }
}