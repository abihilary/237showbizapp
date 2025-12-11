// CustomCard.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../DTOs/UserModel.dart';
import '../DTOs/CommentApi.dart';
import '../services/VideoDetailPlayer.dart'; // Keep this import if you have other functions in this file

// ====================================================================
// NEW WIDGET FOR STABLE MODAL CONTENT & LIFECYCLE MANAGEMENT
// ====================================================================
class CommentsModalContent extends StatefulWidget {
  final bool isDarkMode;
  final String subscriberName;
  final String subscriberId;
  final String postId;
  final Future<List<dynamic>> Function(String) fetchCommentsForPost;
  final Future<Map<String, dynamic>> Function(String, String, String) postCommentToAPI;
  final Future<bool> Function(String, String, String, String) replyToComment;
  final Function deleteComment;

  const CommentsModalContent({
    Key? key,
    required this.isDarkMode,
    required this.subscriberName,
    required this.subscriberId,
    required this.postId,
    required this.fetchCommentsForPost,
    required this.postCommentToAPI,
    required this.deleteComment,
    required this.replyToComment,
  }) : super(key: key);

  @override
  _CommentsModalContentState createState() => _CommentsModalContentState();
}

class _CommentsModalContentState extends State<CommentsModalContent> {
  late TextEditingController _actionController;
  late FocusNode _replyFocusNode;
  List<dynamic> _modalComments = [];
  String? _activeCommentId;
  String _actionType = ''; // 'reply' or 'edit'
  String _activeTargetName = '';
  Set<String> _expandedCommentIds = {};
  String _actualSubscriberId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _actionController = TextEditingController();
    _replyFocusNode = FocusNode();
    _actualSubscriberId = _cleanSubscriberId(widget.subscriberId);
    _fetchComments();
  }

  @override
  void dispose() {
    _actionController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  String _cleanSubscriberId(String id) {
    if (id.startsWith('{subscriber_id: ')) {
      return id.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }
    return id;
  }

  Future<void> _fetchComments() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final comments = await widget.fetchCommentsForPost(widget.postId);
      if (mounted) {
        setState(() {
          // NOTE: The list returned by fetchComments is structured for display,
          // but the modal header uses the length of the full list fetched by _CustomCardState.
          _modalComments = comments;
        });
      }
    } catch (e) {
      // Handle error fetching comments
      debugPrint('Error fetching comments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCommentAction() async {
    final text = _actionController.text.trim();
    if (text.isEmpty) return;

    _replyFocusNode.unfocus();
    _actionController.clear();

    try {
      if (_actionType == 'reply' && _activeCommentId != null) {
        await widget.replyToComment(_activeCommentId!, _actualSubscriberId, widget.postId, text);
      } else if (_actionType == 'edit' && _activeCommentId != null) {
        // Assume you have an updateCommentAPI function defined in CustomCard or a DTO
        // widget.updateCommentAPI(_activeCommentId!, text);
        // Placeholder for edit functionality
      } else {
        await widget.postCommentToAPI(text, _actualSubscriberId, widget.postId);
      }

      setState(() {
        _activeCommentId = null;
        _actionType = '';
        _activeTargetName = '';
      });
      await _fetchComments();
    } on Exception catch (e) {
      // Catch specific exception thrown from post/reply methods
      String errorMessage = "Failed to ${_actionType.isEmpty ? 'post comment' : _actionType}";

      // MODIFICATION: Check for ban (403) or spam (429) messages in the exception string
      if (e.toString().toLowerCase().contains('banned') || e.toString().contains('429') || e.toString().contains('You are posting')) {
        // Display the specific server message from the exception
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // NEW: Robust function to handle both correct (ISO 8601 UTC) and old (ambiguous) timestamps
  String _parseAndFormatTimeAgo(String timestamp) {
    if (timestamp.isEmpty || timestamp == 'null') {
      return 'Unknown time';
    }
    try {
      // 1. Attempt to parse the new, correct ISO 8601 format (e.g., '...T...Z').
      // Dart's DateTime.parse handles this correctly and returns a UTC time.
      final DateTime date = DateTime.parse(timestamp);
      return timeago.format(date);
    } catch (e) {
      // 2. Fallback for old/bad data without 'T' and 'Z' (the old server output: "2025-10-12 11:46:00").
      // We assume the old server data, which was previously stored without a timezone, was intended to be UTC.
      try {
        // Replace space with T and append Z to force interpretation as UTC.
        final String correctedTimestamp = timestamp.replaceAll(' ', 'T') + 'Z';
        final DateTime date = DateTime.parse(correctedTimestamp);
        return timeago.format(date);
      } catch (e2) {
        debugPrint('Failed to parse date string: $timestamp');
        return 'Unknown time';
      }
    }
  }


  Widget _buildReplies(
      List<dynamic> replies, {
        double paddingLeft = 0,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: replies.map<Widget>((comment) {
        final commentId = comment['comment_id'].toString();
        final commentSubscriberId = _cleanSubscriberId(comment['subscriber_id'].toString());
        final isCurrentUser = commentSubscriberId == _actualSubscriberId;
        final avatarUrl = comment['author_avatar_url'];
        final commenterName = comment['subscriber_name'] ?? 'U';
        final nestedReplies = comment['replies'] ?? [];
        final isExpanded = _expandedCommentIds.contains(commentId);
        final commentCount = comment['comment_count'] ?? nestedReplies.length;

        return Padding(
          // FIX 2: Add a unique key to the root widget of each comment/reply item
          key: ValueKey('modal_comment_$commentId'),
          padding: EdgeInsets.only(left: paddingLeft, top: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.blueGrey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.orange[200],
                      backgroundImage:
                      (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                        commenterName.isNotEmpty ? commenterName[0].toUpperCase() : 'U',
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  commenterName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (comment['timestamp'] != null)
                                Text(
                                  // MODIFIED: Use the new robust parser
                                  _parseAndFormatTimeAgo(comment['timestamp']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.white60 : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentUser)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: widget.isDarkMode ? Colors.white70 : Colors.grey[700]),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            setState(() {
                              _activeCommentId = commentId;
                              _actionType = 'edit';
                              _activeTargetName = commenterName;
                              _actionController.text = comment['text'] ?? '';
                            });
                            _replyFocusNode.requestFocus();
                          } else if (value == 'delete') {
                            await widget.deleteComment(commentId, _actualSubscriberId);
                            await _fetchComments();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 6), Text('Edit')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18), SizedBox(width: 6), Text('Delete')])),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  comment['text'] ?? '',
                  style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _activeCommentId = commentId;
                          _actionType = 'reply';
                          _activeTargetName = commenterName;
                          _actionController.clear();
                          // MODIFICATION: Unhide/Expand replies when the 'Reply' button is clicked
                          _expandedCommentIds.add(commentId);
                        });
                        _replyFocusNode.requestFocus();
                      },
                      icon: Icon(Icons.reply, size: 18, color: widget.isDarkMode ? Colors.white : Colors.orange[600]),
                      label: const Text('Reply', style: TextStyle(fontSize: 12)),
                    ),

                    if (nestedReplies.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _expandedCommentIds.contains(commentId) ? _expandedCommentIds.remove(commentId) : _expandedCommentIds.add(commentId);
                          });
                        },
                        child: Text(
                          isExpanded ? "Hide replies (${nestedReplies.length})" : "View replies (${nestedReplies.length})",
                          style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white60 : Colors.orange[600]),
                        ),
                      ),
                  ],
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  child: isExpanded && nestedReplies.isNotEmpty
                      ? _buildReplies(nestedReplies, paddingLeft: paddingLeft + 16)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Add dynamic padding equal to the keyboard height to push the content up.
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        child: Container(
          // Keep max height to ensure scrollability of the comment list
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF0A1F44) : Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              Row(
                children: [
                  Text('Comments (${_modalComments.length})', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: widget.isDarkMode ? Colors.white70 : Colors.black54, size: 20),
                    onPressed: _fetchComments,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _modalComments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : Scrollbar(
                  child: SingleChildScrollView(
                    child: _buildReplies(_modalComments),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Comment Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.blueGrey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: _replyFocusNode,
                        controller: _actionController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleCommentAction(),
                        decoration: InputDecoration(
                          hintText: _actionType == 'reply' ? 'Replying to $_activeTargetName...' : _actionType == 'edit' ? 'Editing comment...' : 'Type a message...',
                          hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: widget.isDarkMode ? Colors.greenAccent : Colors.orange[600],
                      child: IconButton(
                        icon: Icon(Icons.send, color: widget.isDarkMode ? Colors.black87 : Colors.white),
                        onPressed: _handleCommentAction,
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
}
// ====================================================================
// END NEW WIDGET
// ====================================================================


class CustomCard extends StatefulWidget {
  final String text;
  final String extraText;
  final String date;
  final String imageUrl;
  final int likeCount;
  final String youtubeLink;
  final bool isDarkMode;
  final bool isSubscribed;
  final VoidCallback onSubscribe;
  final String postId;

  const CustomCard({
    required this.text,
    required this.extraText,
    required this.date,
    required this.imageUrl,
    required this.likeCount,
    required this.youtubeLink,
    required this.isDarkMode,
    required this.isSubscribed,
    required this.onSubscribe,
    required this.postId,
    Key? key,
  }) : super(key: key);

  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool isLiked = false;
  late int likeCount;
  String? _activeCommentId;
  Set<String> expandedCommentIds = {};
  final Map<String, List<dynamic>> _repliesMap = {};
  late List<dynamic> _topLevelComments = [];
  String? comment_id;
  String? commentSiD;
  String? commentCount;
  List<dynamic> modalComments = [];


  @override
  void initState() {
    super.initState();
    likeCount = widget.likeCount;
    // Initial fetch to get the comment count for the card
    fetchComments(widget.postId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _cleanSubscriberId(String id) {
    if (id.startsWith('{subscriber_id: ')) {
      return id.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }
    return id;
  }

  Future<bool> replyToComment(String commentId, String subscriberId, String postId, String text) async {
    // --- SPAM AVOIDANCE IMPLEMENTATION (Client-side error handling) ---
    if (subscriberId.contains('{subscriber_id:')) {
      subscriberId = subscriberId.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }
    if (commentId.isEmpty) {
      print('Error: commentId is empty. Cannot reply to a comment.');
      return false;
    }

    final url = Uri.parse(
        'https://api.237showbiz.com/api/comment_interaction/?comment_id=$commentId&subscriber_id=$subscriberId');

    final payload = jsonEncode({
      'action': 'reply',
      'text': text,
      'post_id': postId,
    });


    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == 1 || data['success'] == true;
      } else if (response.statusCode == 403) { // ✅ ADDED: Handle ban status (403)
        final data = jsonDecode(response.body);
        // Throw exception with server message (e.g., "Subscriber is banned")
        throw Exception(data['error'] ?? 'You are banned from replying.');
      } else if (response.statusCode == 429) {
        // Handle spam check failure from the server
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Posting comments too quickly or content is duplicate.');
      } else {
        print('Failed to reply: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is Exception && (e.toString().contains('429') || e.toString().toLowerCase().contains('banned'))) rethrow; // Re-throw the specific exception
      print('Error replying to comment: $e');
    }
    return false;
  }

  Future<void> _refreshCommentCount() async {
    // This function is no longer strictly necessary if fetchComments updates `modalComments`.
    // Keeping it simple: just call the main fetch.
    await fetchComments(widget.postId);
  }


  Future<List<dynamic>> fetchComments(String postId) async {
    final commentsData = await CommentApi().fetchCommentsForPost(postId);

    Map<String, dynamic> commentMap = {
      for (var c in commentsData)
        c['comment_id'].toString(): {...c, 'replies': []}
    };

    List<dynamic> topLevelComments = [];

    for (var comment in commentMap.values) {
      final parentIdRaw = comment['parent_id'];
      final parentId = parentIdRaw?.toString() ?? '';

      if (parentId.isEmpty || parentId == 'null') {
        topLevelComments.add(comment);
      } else {
        if (commentMap.containsKey(parentId)) {
          commentMap[parentId]['replies'].add(comment);
        }
      }
    }
    // Update the state variable used to display the count on the card
    // MODIFICATION: Use the full raw list to get the total count including replies
    if(mounted) {
      setState(() {
        modalComments = commentsData; // Assign the raw list (includes all comments and replies)
      });
    }

    return topLevelComments;
  }

  Future<Map<String, dynamic>> postCommentToAPI(String comment, String subscriberId, String postId) async {
    // --- SPAM AVOIDANCE IMPLEMENTATION (Client-side error handling) ---
    if (subscriberId.contains('{subscriber_id:')) {
      subscriberId = subscriberId.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }

    final url = Uri.parse("https://api.237showbiz.com/api/comments/");
    final payload = jsonEncode({
      'text': comment,
      'subscriber_id': subscriberId,
      'post_id': postId,
    });
    final response = await http.post(
      url,
      body: payload,
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'author_name': data['author_name'],
        'author_avatar_url': data['author_avatar_url'],
        'text': data['text'],
        'comment_id': data['comment_id'],
        // The server-side fix now ensures 'timestamp' is in ISO 8601 format
        'timestamp': data['timestamp'],
      };
    } else if (response.statusCode == 403) { // ✅ ADDED: Handle ban status (403)
      final data = jsonDecode(response.body);
      // Throw exception with server message (e.g., "Subscriber is banned")
      throw Exception(data['error'] ?? 'You are banned from commenting.');
    } else if (response.statusCode == 429) {
      // Handle spam check failure from the server
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Posting comments too quickly or content is duplicate.');
    } else {
      throw Exception('Failed to post comment');
    }
  }

  Future<Map<String, dynamic>> postReplyCommentToAPI(String comment, String subscriberId, String postId, {required int parentId}) async {
    // ... (Existing logic for postReplyCommentToAPI)
    // NOTE: This function is not called by the modal but is kept for completeness.
    if (subscriberId.contains('{subscriber_id:')) {
      subscriberId = subscriberId.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }

    final url = Uri.parse("https://api.237showbiz.com/api/comments/");
    final payload = jsonEncode({
      'text': comment,
      'subscriber_id': subscriberId,
      'post_id': postId,
      'parent_id': parentId,
    });
    final response = await http.post(
      url,
      body: payload,
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'author_name': data['author_name'],
        'author_avatar_url': data['author_avatar_url'],
        'text': data['text'],
        'comment_id': data['comment_id'],
      };
    } else if (response.statusCode == 403) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'You are banned from replying.');
    } else if (response.statusCode == 429) {
      // Handle spam check failure from the server
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Posting comments too quickly or content is duplicate.');
    } else {
      throw Exception('Failed to post reply');
    }
  }

  Future<bool> deleteComment(String commentId, String subscriberId) async {
    // ... (Existing logic for deleteComment)
    if (subscriberId.contains('{subscriber_id:')) {
      subscriberId = subscriberId.replaceAll('{subscriber_id: ', '').replaceAll('}', '');
    }

    final url = Uri.parse('https://api.237showbiz.com/api/comment_interaction/?comment_id=$commentId&subscriber_id=$subscriberId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'delete',
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['success'] == true;
    } else {
      return false;
    }
  }

  updateCommentAPI(String commentId, String inputText) {}
  Future<Map<String, dynamic>?> getLocalSubscriber() async {
    // ... (Existing logic for getLocalSubscriber)
    final prefs = await SharedPreferences.getInstance();
    final subscriberString = prefs.getString('subscriber');

    if (subscriberString != null) {
      return jsonDecode(subscriberString);
    }
    return null;
  }
  Future<void> _loadSubscriberData() async {
    // ... (Existing logic for _loadSubscriberData)
    final data = await getLocalSubscriber();
    setState(() {
      var subscriberData = data;
    });
  }

  String _formatDate(String isoDate) {
    // ... (Existing logic for _formatDate)
    try {
      // Parsing the new ISO 8601 UTC string and converting to the local timezone for display
      DateTime? dateTime = DateTime.tryParse(isoDate);
      // NOTE: .toLocal() is crucial here to display the full date in the user's timezone
      return dateTime != null ? DateFormat('dd MMMM yyyy, hh:mm a').format(dateTime.toLocal()) : "Unknown Date";
    } catch (e) {
      return "Unknown Date";
    }
  }

  String removeHtmlTags(String htmlString) {
    // ... (Existing logic for removeHtmlTags)
    final unescape = HtmlUnescape();
    String cleanedText = unescape.convert(htmlString);
    final regex = RegExp(r'<[^>]*>');
    return cleanedText.replaceAll(regex, '');
  }

  void _sharePost() async {
    // ... (Existing logic for _sharePost)
    if (widget.text.isEmpty && widget.extraText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to share!")),
      );
      return;
    }

    final String plainCustomText = removeHtmlTags(widget.text);
    final String plainExtraText = removeHtmlTags(widget.extraText);
    final String content = '$plainCustomText\n\nCheck it out: $plainExtraText';

    try {
      await Share.share(content, subject: 'Sharing Plain Text');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sharing post: $e")),
      );
    }
  }


  String? _extractDownloadLink(String htmlContent) {
    // ... (Existing logic for _extractDownloadLink)
    final RegExp regExp = RegExp(r'href="(https:\/\/237showbiz\.com\/wp-content\/uploads\/[^\s"]+\.mp3)"', caseSensitive: false);
    final match = regExp.firstMatch(htmlContent);
    return match?.group(1);
  }

  String _removeDownloadButtonHtml(String htmlContent) {
    // ... (Existing logic for _removeDownloadButtonHtml)
    final RegExp regExp = RegExp(
      r'<div style="text-align:center;">.*?<a class="fusion-button.*?<\/a>.*?<\/div>',
      multiLine: true,
      caseSensitive: false,
    );
    return htmlContent.replaceAll(regExp, '');
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final sanitizedExtraText = _removeDownloadButtonHtml(widget.extraText);
    const int maxSnippetLength = 150;

    // Create a plain text snippet for safe display in the card
    String textSnippet = removeHtmlTags(sanitizedExtraText);
    if (textSnippet.length > maxSnippetLength) {
      textSnippet = "${textSnippet.substring(0, maxSnippetLength)}...";
    }

    return Card(
      color: widget.isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        // FIX 1: The SingleChildScrollView wrapper on the card's Column addresses the massive overflow.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.imageUrl.isNotEmpty)
              // MODIFICATION 1: Image to show full without cropping
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  // Removed fixed height: 250, to allow image to scale fully
                  child: GestureDetector(
                    onTap: () => _viewMore(context, widget.isDarkMode),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.fitWidth, // Shows the whole image, fitting the width
                        width: double.infinity,
                        // Removed fixed height: 250
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),

              // Post date
              Text(
                _formatDate(widget.date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),

              // Post text
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 5),

              // FIX: Use plain text snippet to prevent HTML rendering overflow
              Text(
                textSnippet,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),

              // View More button
              TextButton(
                onPressed: () => _viewMore(context, widget.isDarkMode),
                child: const Text(
                  "View More",
                  style: TextStyle(
                    color: Colors.orange,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const Divider(),

              // LIKE - COMMENT - SHARE row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like button (unchanged logic)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.orange[600],
                        ),
                        onPressed: () async {
                          final userModel = Provider.of<UserModel>(context, listen: false);

                          if (userModel.username.isEmpty) {
                            widget.onSubscribe();
                            return;
                          }

                          final previousLiked = isLiked;
                          final previousCount = likeCount;

                          setState(() {
                            isLiked = !isLiked;
                            likeCount += isLiked ? 1 : -1;
                          });

                          try {
                            final subscriberId = userModel.subscriberId;
                            final body = jsonEncode({
                              'action': 'toggle_like',
                              'like': isLiked,
                            });

                            final String cleanSubscriberId = _cleanSubscriberId(subscriberId);

                            final response = await http.post(
                              Uri.parse(
                                'https://api.237showbiz.com/api/comment_interaction/?comment_id=$_activeCommentId&subscriber_id=$cleanSubscriberId',
                              ),
                              headers: {'Content-Type': 'application/json'},
                              body: body,
                            );

                            final success = response.statusCode == 200 &&
                                jsonDecode(response.body)['success'] == true;

                            if (!success) {
                              setState(() {
                                isLiked = previousLiked;
                                likeCount = previousCount;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to update like status',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLiked = previousLiked;
                              likeCount = previousCount;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to update like status',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        "$likeCount",
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  // Comments button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.comment,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.orange[600],
                        ),
                        onPressed: () async {
                          final userModel = Provider.of<UserModel>(context, listen: false);

                          if (userModel.username.isEmpty) {
                            widget.onSubscribe();
                          } else {
                            await fetchComments(widget.postId);
                            await _showCommentsModal(
                              context,
                              widget.isDarkMode,
                              userModel.username.toUpperCase(),
                              userModel.subscriberId,
                              widget.postId,
                            );
                            await _refreshCommentCount();
                          }
                        },
                      ),
                      Text(
                        modalComments.length.toString(),
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  // Share button (unchanged logic)
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: widget.isDarkMode ? Colors.white : Colors.orange[600],
                    ),
                    onPressed: _sharePost,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  }

// Inside _CustomCardState
  void _viewMore(BuildContext context, bool isDarkMode) {
    final videoId = YoutubePlayerController.convertUrlToId(widget.youtubeLink);
    final downloadLink = _extractDownloadLink(widget.extraText);
    final userModel = Provider.of<UserModel>(context, listen: false);

    // FIX 3: Localize and Dispose Controllers/FocusNode SAFELY inside the navigation block
    final TextEditingController _commentController = TextEditingController();
    final FocusNode _commentFocusNode = FocusNode();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Details",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontFamily: 'Poppins')),
              backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
              iconTheme:
              IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
            ),
            backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
            // FIX 4: Use Column with Expanded to correctly constrain scrollable and non-scrollable widgets
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    // 1. MODIFIED: Increased bottom padding for better scroll reach
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 50.0), // Added 50.0 bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.imageUrl,
                              fit: BoxFit.fitWidth,
                              width: double.infinity,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Html(
                          data: _removeDownloadButtonHtml(widget.extraText),
                          style: {
                            'body': Style(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: FontSize.medium),
                            'p': Style(
                                color: isDarkMode ? Colors.white : Colors.black),
                            'h1': Style(
                                color: isDarkMode ? Colors.orange : Colors.blue,
                                fontWeight: FontWeight.bold),
                          },
                        ),
                        if (videoId != null && videoId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              // **FIX:** Use the new stateful widget to manage the controller lifecycle
                              child: VideoDetailPlayer(videoId: videoId),
                            ),
                          ),
                        if (videoId == null || videoId.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Text(
                              "No YouTube video found for this post.",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        if (downloadLink != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 15),
                                ),
                                onPressed: () async {
                                  final url = Uri.parse(downloadLink);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Could not open download link: $downloadLink')),
                                    );
                                  }
                                },
                                child: const Text('Download',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              ),
                            ),
                          ),

                        const Divider(),
                        Padding(
                          // FIX: Increased vertical padding for better visibility on all devices
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: _buildInteractionRow(userModel),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._topLevelComments.map((comment) {
                              final commentId = comment['comment_id'].toString();
                              final isCurrentUser =
                                  comment['subscriber_id'].toString() ==
                                      userModel.subscriberId;
                              final replies = _repliesMap[commentId] ?? [];
                              final isExpanded =
                              expandedCommentIds.contains(commentId);
                              final avatarUrl = comment['author_avatar_url'];
                              final commenterName =
                                  comment['subscriber_name'] ?? 'U';

                              return Container(
                                key: ValueKey('comment_detail_$commentId'),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.orange,
                                        backgroundImage: (avatarUrl != null &&
                                            avatarUrl.isNotEmpty)
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                        child: (avatarUrl == null ||
                                            avatarUrl.isEmpty)
                                            ? Text(
                                            commenterName.isNotEmpty
                                                ? commenterName[0]
                                                .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                                color: Colors.white))
                                            : null,
                                      ),
                                      title: Text(commenterName,
                                          style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87)),
                                      subtitle: Html(
                                        data: comment['text'] ?? '',
                                        style: {
                                          'body': Style(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black)
                                        },
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            // Reply feature placeholder
                                          },
                                          child: const Text("Reply",
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        if (isCurrentUser) ...[
                                          TextButton(
                                            onPressed: () {
                                              // Edit placeholder
                                            },
                                            child: const Text("Edit",
                                                style: TextStyle(fontSize: 12)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              bool success =
                                              await deleteComment(commentId,
                                                  userModel.subscriberId);
                                              if (success) {
                                                await fetchComments(widget.postId);
                                              }
                                            },
                                            child: const Text('Delete'),
                                          )
                                        ],
                                        if (replies.isNotEmpty)
                                          TextButton(
                                            onPressed: () {
                                              // Expand replies placeholder
                                            },
                                            child: Text(
                                                isExpanded
                                                    ? "Hide replies"
                                                    : "View replies (${replies.length})",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange,
                                                    fontFamily: "Poppins")),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      // FIX 3: Dispose controllers/focus node after the page is popped
      _commentController.dispose();
      _commentFocusNode.dispose();
    });
  }
  Future<void> _showCommentsModal(
      BuildContext context,
      bool isDarkMode,
      String subscriberName,
      String subscriberId,
      String postId,
      ) async {

    // FIX 2: Use the new StatefulWidget instead of StatefulBuilder to manage lifecycle
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return CommentsModalContent(
          isDarkMode: isDarkMode,
          subscriberName: subscriberName,
          subscriberId: subscriberId,
          postId: postId,
          fetchCommentsForPost: fetchComments, // Pass the method reference
          postCommentToAPI: postCommentToAPI, // Pass the method reference
          deleteComment: deleteComment, // Pass the method reference
          replyToComment: replyToComment, // Pass the method reference
        );
      },
    );

    // After the modal is closed, refresh the card's comment count
    await fetchComments(postId);
  }

  Widget _buildInteractionRow(UserModel userModel) {
    // ... (Existing logic for _buildInteractionRow)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: widget.isDarkMode ? Colors.white : Colors.orange[600],
              ),
              onPressed: () async {
                if (userModel.username.isEmpty) {
                  widget.onSubscribe();
                  return;
                }

                final previousLiked = isLiked;
                final previousCount = likeCount;

                setState(() {
                  isLiked = !isLiked;
                  likeCount += isLiked ? 1 : -1;
                });

                try {
                  final subscriberId = userModel.subscriberId;
                  final body = jsonEncode({
                    'action': 'toggle_like',
                    'like': isLiked,
                  });
                  final String cleansubscriberId = _cleanSubscriberId(subscriberId);
                  final response = await http.post(
                    Uri.parse(
                        'https://api.237showbiz.com/api/comment_interaction/?comment_id=$_activeCommentId&subscriber_id=$cleansubscriberId'),
                    headers: {'Content-Type': 'application/json'},
                    body: body,
                  );

                  final success = response.statusCode == 200 &&
                      jsonDecode(response.body)['success'] == true;

                  if (!success) {
                    setState(() {
                      isLiked = previousLiked;
                      likeCount = previousCount;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to update like status',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() {
                    isLiked = previousLiked;
                    likeCount = previousCount;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to update like status',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  );
                }
              },
            ),
            Text(
              "$likeCount",
              style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.comment,
                  color: widget.isDarkMode ? Colors.white : Colors.orange[600]),
              onPressed: () async {
                if (userModel.username.isEmpty) {
                  widget.onSubscribe();
                } else {
                  await fetchComments(widget.postId);
                  await _showCommentsModal(
                    context,
                    widget.isDarkMode,
                    userModel.username.toUpperCase(),
                    userModel.subscriberId,
                    widget.postId,
                  );
                }
              },
            ),
            Text(
              modalComments.length.toString(),
              style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.share,
              color: widget.isDarkMode ? Colors.white : Colors.orange[600]),
          onPressed: _sharePost,
        ),
      ],
    );
  }

}