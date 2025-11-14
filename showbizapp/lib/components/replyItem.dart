import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ReplyIte extends StatelessWidget {
   final Map reply;
   final bool isDarkMode;
   final bool isLast;

  const ReplyIte({
    required this.reply,
    required this.isDarkMode,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final replyAvatar = reply['author_avatar_url'];
    final replyName = reply['subscriber_name'] ?? 'U';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1,
            margin: const EdgeInsets.only(left: 10, right: 10),
            color: isLast ? Colors.transparent : Colors.grey[400],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.orange,
                    backgroundImage: (replyAvatar != null && replyAvatar.isNotEmpty)
                        ? NetworkImage(replyAvatar)
                        : null,
                    child: (replyAvatar == null || replyAvatar.isEmpty)
                        ? Text(
                      replyName.isNotEmpty ? replyName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replyName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Html(
                          data: reply['text'] ?? '',
                          style: {
                            'body': Style(
                              fontSize: FontSize.small,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          },
                        ),
                      ],
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
}