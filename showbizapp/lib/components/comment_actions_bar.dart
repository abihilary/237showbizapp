import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommentInteractionBar extends StatefulWidget {
  final bool isDarkMode;
  final String commentId;
  final String subscriberId;
  final String subscriberName;
  final int initialLikeCount;
  final bool initialIsLiked;
  final String commentCount;
  final Function onSubscribe;
  final Function fetchComments;
  final Future<void> Function(BuildContext, bool, String, String, String) showCommentsModal;
  final Function sharePost;

  const CommentInteractionBar({
    Key? key,
    required this.isDarkMode,
    required this.commentId,
    required this.subscriberId,
    required this.subscriberName,
    required this.initialLikeCount,
    required this.initialIsLiked,
    required this.commentCount,
    required this.onSubscribe,
    required this.fetchComments,
    required this.showCommentsModal,
    required this.sharePost,
  }) : super(key: key);

  @override
  _CommentInteractionBarState createState() => _CommentInteractionBarState();
}

class _CommentInteractionBarState extends State<CommentInteractionBar> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialIsLiked;
    likeCount = widget.initialLikeCount;
  }

  Future<void> toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.237showbiz.com/api/comment_interaction/?comment_id=${widget.commentId}&subscriber_id=${widget.subscriberId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'toggle_like', 'like': isLiked}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        _revertLike();
      }
    } catch (e) {
      _revertLike();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update like status')));
    }
  }

  void _revertLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_down_outlined, color: Colors.orange),
          onPressed: toggleLike,
        ),
        Text('$likeCount', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        IconButton(
          icon: const Icon(Icons.comment, color: Colors.orange),
          onPressed: () async {
            await widget.fetchComments(widget.commentId);
            await widget.showCommentsModal(context, widget.isDarkMode, widget.subscriberName, widget.subscriberId, widget.commentId);
          },
        ),
        Text(widget.commentCount, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.orange),
          onPressed: () => widget.sharePost(),
        ),
      ],
    );
  }
}