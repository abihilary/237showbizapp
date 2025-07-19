import 'package:flutter/material.dart';
import '../DTOs/Comment.dart'; // Assuming you have a Comment DTO class

class CommentSection extends StatefulWidget {
  final List<Comment> comments; // Accept a list of comments to persist

  const CommentSection({Key? key, required this.comments}) : super(key: key);

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController commentController = TextEditingController();

  void addComment(String text) {
    setState(() {
      widget.comments.add(Comment(
        name: 'User', // User's name
        text: text,
        timestamp: DateTime.now(),
      ));
      commentController.clear(); // Clear the input after adding
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // Account for keyboard
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close Button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context, widget.comments.length); // Return the comment count
              },
            ),
          ),

          // Comments List
          if (widget.comments.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: widget.comments.length,
                itemBuilder: (context, index) {
                  final comment = widget.comments[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundImage: AssetImage('assets/applogo.png'),
                    ),
                    title: Text(
                      comment.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.text),
                        Text(
                          '${comment.timestamp.hour}:${comment.timestamp.minute}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Add Comment Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/applogo.png'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () {
                    if (commentController.text.isNotEmpty) {
                      addComment(commentController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
