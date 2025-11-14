import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

class CommentDialog extends StatefulWidget {
  final String postId;
  final String subscriberId;
  final bool isDarkMode;

  const CommentDialog({
    super.key,
    required this.postId,
    required this.subscriberId,
    required this.isDarkMode,
  });

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    setState(() => isLoading = true);
    final url = Uri.parse('https://api.237showbiz.com/api/comments/?post_id=${widget.postId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          comments = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        // Handle error
      }
    } catch (e) {
      setState(() => isLoading = false);
      // Handle network error
    }
  }

  Future<void> postComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final url = Uri.parse('https://api.237showbiz.com/api/comment_interaction/?post_id=${widget.postId}&subscriber_id=${widget.subscriberId}');
    final payload = jsonEncode({'action': 'post', 'text': commentText});
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload);
      if (response.statusCode == 200) {
        _commentController.clear();
        await fetchComments();
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle network error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.black87 : Colors.white,
      title: Text('Comments', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              title: Text(HtmlUnescape().convert(comment['text'] ?? ''), style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
              subtitle: Text(comment['name'] ?? 'Anonymous', style: TextStyle(color: widget.isDarkMode ? Colors.grey : Colors.grey[600])),
            );
          },
        ),
      ),
      actions: [
        TextField(
          controller: _commentController,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Add a comment...',
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.grey : Colors.grey[600]),
            suffixIcon: IconButton(
              icon: Icon(Icons.send, color: widget.isDarkMode ? Colors.white : Colors.black),
              onPressed: postComment,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}