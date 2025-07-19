import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:html_unescape/html_unescape.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../DTOs/UserModel.dart';
import '../components/comment_actions_bar.dart';

import '../DTOs/CommentApi.dart';
import '../DTOs/Reply.dart';
import 'package:provider/provider.dart';

class CustomCard extends StatefulWidget {
  final String text;
  final String extraText;
  final String date;
  final String imageUrl;
  final int likeCount;
 // final List<dynamic> comments;
  final String youtubeLink;
  final bool isDarkMode;
  final bool isSubscribed;
  final VoidCallback onSubscribe;

  final String postId;
  final String subscriberId;
  final String subscriberName;

  final dynamic ? onReply;


  const CustomCard({
    required this.text,
    required this.extraText,
    required this.date,
    required this.imageUrl,
    required this.likeCount,
    //required this.comments,
    required this.youtubeLink,
    required this.isDarkMode,
    required this.onReply,




    Key? key, required this.isSubscribed, required this.onSubscribe, required this.postId, required this.subscriberId, required this.subscriberName,
  }) : super(key: key);

  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool isLiked = false;
  late int likeCount;
  late List<dynamic> comments=[];
  late int commentCount;
  late WebViewController controller;
  late YoutubePlayerController _controller;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  final FocusNode _replyFocusNode = FocusNode();
  String? _activeCommentId; // Comment being replied or edited
  String _actionType = '';
  final TextEditingController _actionTextController = TextEditingController();
  String? activeCommentId;


  String _activeTargetName = '';
  Set<String> expandedCommentIds = {};
  Map<String, List<dynamic>> repliesMap = {};
  String? comment_id;
  String? commentSiD;

  List<dynamic> _topLevelComments = [];
  Map<String, List<dynamic>> _repliesMap = {};



// Inside your `_showCommentsModal`, initialize it and dispose properly
  @override
  void dispose() {
    _replyFocusNode.dispose();
    super.dispose();
  }
  updateCommentAPI(String commentId, String inputText) {}
  Future<Map<String, dynamic>?> getLocalSubscriber() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberString = prefs.getString('subscriber');

    if (subscriberString != null) {
      return jsonDecode(subscriberString);
    }
    return null; // Return null if no data found
  }
  Future<void> _loadSubscriberData() async {
    final data = await getLocalSubscriber();
    setState(() {
      var subscriberData = data;
    });
  }
  Future<Map<String, dynamic>> postCommentToAPI(
      String text,
      String subscriberId,
      String postId, {
        int? parentId,
      }) async {
    print("id is: $subscriberId");

    final response = await http.post(
      Uri.parse('https://api.237showbiz.com/api/comments/?subscriber_id=$subscriberId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'subscriber_id': subscriberId.toString(),
        'post_id': postId,
        if (parentId != null) 'parent_id': parentId,
      }),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        comment_id = responseData['comment_id'];
      });
      return responseData;
    } else {
      throw Exception('Failed to post comment: ${response.statusCode} ${response.body}');
    }
  }



  Future<bool> replyToComment(String commentId, String subscriberId, String postId, String text) async {
    final url = Uri.parse(
        'https://api.237showbiz.com/api/comment_interaction/?comment_id=$commentId&subscriber_id=$subscriberId');

    final payload = jsonEncode({
      'action': 'reply',
      'text': text,
      'post_id': postId,  // <-- include post_id here
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == 1 || data['success'] == true;
      } else {
        print('Failed to reply: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error replying to comment: $e');
    }
    return false;
  }


  Future<bool> deleteComment(String commentId, String subscriberId) async {
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




  Future<Map<String, dynamic>> postReplyCommentToAPI(String comment, String subscriberId, String postId) async {
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
      };
    } else {
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('Payload sent: $payload');
      throw Exception('Failed to post comment');
    }
  }
  //final response = await http.get(Uri.parse('https://api.237showbiz.com/api/comments/'));

  Future<void> fetchComments(String postId) async {
    print('Fetching comments for postId: $postId');

    final commentsData = await CommentApi().fetchCommentsForPost(postId); // Filter by postId

    for (var c in commentsData) {
      final id = c['comment_id'].toString().trim().toLowerCase();
      setState(() {
        commentSiD = id;
      });
      final parentId = c['parent_id']?.toString().trim().toLowerCase() ?? '';
      print('Comment ID: $id, Parent ID: $parentId');
    }

    print('Raw comments data received:');
    for (var c in commentsData) {
      print('Comment: ${c['comment_id']} | Parent: ${c['parent_id']} | Text: ${c['text']}');
    }

    Map<String, List<dynamic>> repliesMap = {};
    List<dynamic> topLevelComments = [];

    for (var comment in commentsData) {
      final String commentId = comment['comment_id'].toString().trim().toLowerCase();
      final dynamic parentIdRaw = comment['parent_id'];
      final String parentId = parentIdRaw?.toString().trim().toLowerCase() ?? '';

      if (parentId.isEmpty || parentId == 'null') {
        topLevelComments.add(comment);
      } else {
        if (!repliesMap.containsKey(parentId)) {
          repliesMap[parentId] = [];
        }
        repliesMap[parentId]!.add(comment);
      }
    }

    print('\nTop-level comments (${topLevelComments.length}):');
    for (var c in topLevelComments) {
      print(' - ${c['comment_id']}: ${c['text']}');
    }

    print('\nReplies map:');
    repliesMap.forEach((parentId, replies) {
      print('Replies to $parentId (${replies.length}):');
      for (var reply in replies) {
        print('  - ${reply['comment_id']}: ${reply['text']} (parent_id: ${reply['parent_id']})');
      }
    });

    if (mounted) {
      setState(() {
        _topLevelComments = topLevelComments;
        _repliesMap = repliesMap;
      });
    }
  }







  @override
  void initState() {
    super.initState();
    _loadSubscriberData();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You can update a loading indicator here if desired
            print('Loading progress: $progress%');
          },
          onPageStarted: (String url) {
            // Optionally handle when a page starts loading
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            // Optionally handle when a page finishes loading
            print('Page finished loading: $url');
          },
          onHttpError: (HttpResponseError error) {
            // Handle HTTP errors here
            print('HTTP error: ${error.response?.statusCode}');
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource errors here
            print('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Prevent opening YouTube links within the WebView
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    likeCount = widget.likeCount;
    comments = comments;
    commentCount = comments.length;
    fetchComments(widget.postId);
  }

  String _formatDate(String isoDate) {
    try {
      DateTime? dateTime = DateTime.tryParse(isoDate);
      return dateTime != null ? DateFormat('dd MMMM yyyy, hh:mm a').format(
          dateTime) : "Unknown Date";
    } catch (e) {
      return "Unknown Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    // Preprocess the HTML to remove unsupported CSS selectors like :hover
    String sanitizeHtml(String htmlContent) {
      return htmlContent.replaceAll(
          RegExp(r':hover', caseSensitive: false), '');
    }

    return Card(
      color: widget.isDarkMode ? const Color(0xFF0A1F44) :Colors.white ,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl.isNotEmpty)
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 1.5,
                height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.5,
                child: GestureDetector(
                  onTap: () => _viewMore(context,widget.isDarkMode),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              _formatDate(widget.date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: widget.isDarkMode ? Colors.white: Colors.black87,
              ),
            ),
            Html(
              // Sanitize the HTML data
              data: sanitizeHtml(widget.extraText.length > 100
                  ? "${HtmlUnescape().convert(
                  widget.extraText.substring(0, 100))}..."
                  : HtmlUnescape().convert(widget.extraText)),
              doNotRenderTheseTags: {'hover'},
              // Prevent rendering of unsupported tags
              extensions: [
                TagExtension(
                  tagsToExtend: {"iframe"},
                  builder: (context) {
                    final src = context.attributes['src'] ?? '';

                    if (src.contains('youtube.com') ||
                        src.contains('youtu.be')) {
                      return Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: WebViewWidget(
                            controller: WebViewController()
                              ..loadRequest(Uri.parse(src)),
                          ),
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text('Unsupported video format.'),
                      ); // Provide fallback for unsupported iframes
                    }
                  },
                ),
              ],
              style: {
                'body': Style(
                  color: widget.isDarkMode ? Colors.white : Colors.black, fontFamily: 'Poppins',// Switch color based on theme
                ),
                'p': Style(
                  color: widget.isDarkMode ? Colors.white : Colors.black,fontFamily: 'Poppins', // Paragraph text
                ),
                'h1': Style(
                  color: widget.isDarkMode ? Colors.orange : Colors.blue, // Header styling
                  fontWeight: FontWeight.bold,fontFamily: 'Poppins',
                ),
              },
            ),
            TextButton(
              onPressed: () => _viewMore(context,widget.isDarkMode),
              child: const Text(
                "View More",
                style: TextStyle(color: Colors.orange,fontFamily: 'Poppins',),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button and count
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: Colors.orange,
                      ),
                      onPressed: () async {
                        setState(() {
                          isLiked = !isLiked;
                          isLiked ? likeCount++ : likeCount--;
                        });

                        try {
                          final body = jsonEncode({'action': 'toggle_like', 'like': isLiked});
                          final response = await http.post(
                            Uri.parse('https://api.237showbiz.com/api/comment_interaction/?comment_id=$activeCommentId&subscriber_id=${widget.subscriberId}'),
                            headers: {'Content-Type': 'application/json'},
                            body: body,
                          );

                          if (response.statusCode != 200 || jsonDecode(response.body)['success'] != true) {
                            setState(() {
                              isLiked = !isLiked;
                              isLiked ? likeCount++ : likeCount--;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            isLiked = !isLiked;
                            isLiked ? likeCount++ : likeCount--;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update like status', style: TextStyle(fontFamily: 'Poppins'))),
                          );
                        }
                      },
                    ),
                    Text(
                      "$likeCount",
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ],
                ),

                // Comment button and count
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.orange),
                      onPressed: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        print(prefs.getKeys());
                        print(prefs.getString('subscriber'));
                        if (userModel.username=="") {
                          widget.onSubscribe();
                        } else {
                          await fetchComments(widget.postId);
                          await _showCommentsModal(
                            context,
                            widget.isDarkMode,
                            widget.subscriberName,
                            widget.subscriberId,
                            widget.postId,
                          );
                        }
                      },
                    ),
                    Text(
                      _topLevelComments.length.toString(),
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ],
                ),

                // Share button (no count)
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.orange),
                  onPressed: _sharePost,
                ),
              ],
            )

          ],
        ),
      ),
    );
  }


  void _viewMore(BuildContext context, bool isDarkMode) {
    final userModel = Provider.of<UserModel>(context);
    // State variables for reply handling inside StatefulBuilder
    String? replyToCommentId; // Which comment is being replied to
    TextEditingController replyController = TextEditingController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  "Details",
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87,fontFamily: 'Poppins',),
                ),
                backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
                iconTheme: IconThemeData(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.imageUrl.isNotEmpty)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 1.5,
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // HTML Description
                    Html(
                      data: widget.extraText,
                      style: {
                        'body': Style(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: FontSize.medium,
                        ),
                        'p': Style(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        'h1': Style(
                          color: isDarkMode ? Colors.orange : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      },
                    ),

                    // YouTube Player
                    if (widget.youtubeLink.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: YoutubePlayer(
                            controller: _controller = YoutubePlayerController.fromVideoId(
                              videoId: YoutubePlayerController.convertUrlToId(widget.youtubeLink) ?? '',
                              params: const YoutubePlayerParams(
                                showControls: true,
                                showFullscreenButton: true,
                                mute: false,
                                loop: false,
                              ),
                            ),
                            aspectRatio: 16 / 9,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Divider(),

                    // COMMENTS SECTION (updated)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display all comments
                        ...comments.map((comment) {
                          bool isReplying = replyToCommentId == comment.id;
                          final commentId = comment.id.toString().trim().toLowerCase();
                          final replies = repliesMap[commentId] ?? [];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.text,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (isReplying) {
                                            // Clicking reply again cancels reply
                                            replyToCommentId = null;
                                            replyController.clear();
                                          } else {
                                            replyToCommentId = comment.id;
                                            replyController.clear();
                                          }
                                        });
                                      },
                                      child: Text(
                                        isReplying ? 'Cancel' : 'Reply',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Reply input field
                                if (isReplying)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: replyController,
                                            decoration: InputDecoration(
                                              hintText: 'Write a reply...',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.send, color: Colors.orange),
                                          onPressed: () {
                                            final replyText = replyController.text.trim();
                                            if (replyText.isEmpty) return;

                                            setState(() {
                                              // Add reply to repliesMap locally
                                              repliesMap[commentId] = [
                                                ...replies,
                                                {'id': UniqueKey().toString(), 'text': replyText},
                                              ];

                                              replyController.clear();
                                              replyToCommentId = null;
                                            });

                                            // TODO: Optionally handle persistence of replies here
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                // Display replies indented
                                if (replies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: replies.map((reply) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6.0),
                                          child: Text(
                                            "- ${reply['text'] ?? ''}",
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                              fontStyle: FontStyle.italic,
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 12),

                        // Input for adding new comment (optional, if needed)
                        // You can add this section if you want users to add new comments here
                        /*
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newCommentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: Colors.orange),
                            onPressed: () {
                              // Add new comment logic
                            },
                          ),
                        ],
                      ),
                      */
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),

                    // Like, Comment, Share Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_down_alt_outlined,
                            color: Colors.orange,
                          ),
                          onPressed: () {
                            setState(() {
                              isLiked = !isLiked;
                              isLiked ? likeCount++ : likeCount--;
                            });
                          },
                        ),
                        Text(
                          "$likeCount",
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment, color: Colors.orange),
                          onPressed: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            if (widget.isSubscribed) {
                              widget.onSubscribe();
                            } else {
                              _showCommentsModal(
                                context,
                                isDarkMode,
                                widget.subscriberName,
                                widget.subscriberId,
                                widget.postId,
                              );
                            }
                          },
                        ),
                        Text(
                          _topLevelComments.length.toString(),
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.orange),
                          onPressed: _sharePost,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  void _sharePost() async {
    if (widget.text.isEmpty && widget.extraText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to share!")),
      );
      return;
    }

    // Remove HTML tags properly
    final String plainExtraText = removeHtmlTags(widget.extraText);
    final String plainCustomText = removeHtmlTags(widget.text);

    // Construct plain text content
    final String content = '$plainCustomText\n\nCheck it out at: $plainExtraText';

    try {
      // Ensure plain text content is shared
      await Share.share(content, subject: 'Sharing Plain Text');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post shared successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sharing post: $e")),
      );
    }
  }

// Helper function to remove HTML tags
  String removeHtmlTags(String input) {
    // Use a regular expression to strip HTML tags
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: false);
    return input.replaceAll(exp, '').trim();
  }


  Future<void> _showCommentsModal(
      BuildContext context,
      bool isDarkMode,
      String subscriberName,
      String subscriberId,
      String postId,
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
                child: Column(
                  children: [
                    // Comment list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _topLevelComments.length,
                        itemBuilder: (context, index) {
                          final comment = _topLevelComments[index];
                          final commentId = comment['comment_id'].toString();
                          final isCurrentUser = comment['subscriber_id'].toString() == subscriberId;
                          final replies = _repliesMap[commentId] ?? [];
                          final isExpanded = expandedCommentIds.contains(commentId);
                          final avatarUrl = comment['author_avatar_url'];
                          final commenterName = comment['subscriber_name'] ?? 'U';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: (avatarUrl == null || avatarUrl.isEmpty)
                                        ? Text(
                                      commenterName.isNotEmpty
                                          ? commenterName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                        : null,
                                  ),
                                  title: Text(
                                    commenterName,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Html(
                                    data: comment['text'] ?? '',
                                    style: {
                                      'body': Style(color: isDarkMode ? Colors.white : Colors.black),
                                      'p': Style(color: isDarkMode ? Colors.white : Colors.black),
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setModalState(() {
                                          activeCommentId = commentId;
                                          _actionType = 'reply';
                                          _activeTargetName = commenterName;
                                          _actionTextController.clear();
                                          FocusScope.of(context).requestFocus(_replyFocusNode);
                                        });
                                      },
                                      child: const Text("Reply", style: TextStyle(fontSize: 12)),
                                    ),
                                    if (isCurrentUser) ...[
                                      TextButton(
                                        onPressed: () {
                                          setModalState(() {
                                            activeCommentId = commentId;
                                            _actionType = 'edit';
                                            _activeTargetName = commenterName;
                                            _actionTextController.text = comment['text'] ?? '';
                                            FocusScope.of(context).requestFocus(_replyFocusNode);
                                          });
                                        },
                                        child: const Text("Edit", style: TextStyle(fontSize: 12)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          print('Delete pressed for commentId: $commentId');
                                          bool success = await CommentApi().deleteComment(commentId, subscriberId, postId);
                                          print('Delete success: $success');
                                          if (success) {
                                            print('Fetching comments after delete...');
                                            await fetchComments(postId); // await here
                                            // No need to call setState here because fetchComments already does
                                          } else {
                                            print('Delete failed');
                                          }
                                        },
                                        child: Text('Delete'),
                                      )
                                    ],
                                    if (replies.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          setModalState(() {
                                            isExpanded
                                                ? expandedCommentIds.remove(commentId)
                                                : expandedCommentIds.add(commentId);
                                          });
                                        },
                                        child: Text(
                                          isExpanded
                                              ? "Hide replies"
                                              : "View replies (${replies.length})",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                                if (isExpanded && replies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40, top: 4),
                                    child: Column(
                                      children: replies.map<Widget>((reply) {
                                        final replyAvatar = reply['author_avatar_url'];
                                        final replyName = reply['subscriber_name'] ?? 'U';
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.grey[300],
                                              backgroundImage: (replyAvatar != null &&
                                                  replyAvatar.isNotEmpty)
                                                  ? NetworkImage(replyAvatar)
                                                  : null,
                                              child: (replyAvatar == null || replyAvatar.isEmpty)
                                                  ? Text(
                                                replyName.isNotEmpty
                                                    ? replyName[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                ),
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
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  Html(
                                                    data: reply['text'] ?? '',
                                                    style: {
                                                      'body': Style(
                                                        fontSize: FontSize.small,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    if (activeCommentId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _actionType == 'reply'
                                  ? 'Replying to $_activeTargetName'
                                  : 'Editing your comment',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  activeCommentId = null;
                                  _actionType = '';
                                  _activeTargetName = '';
                                  _actionTextController.clear();
                                });
                              },
                              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _replyFocusNode,
                            controller: _actionTextController,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: _actionType == 'reply'
                                  ? 'Write a reply...'
                                  : _actionType == 'edit'
                                  ? 'Edit comment...'
                                  : 'Type a message...',
                              hintStyle: TextStyle(
                                color: isDarkMode ? Colors.white60 : Colors.black54,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 25,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () async {
                              final inputText = _actionTextController.text.trim();
                              if (inputText.isEmpty) return;

                              if (_actionType == 'reply' && activeCommentId != null) {
                                await replyToComment(
                                    activeCommentId!, subscriberId, postId, inputText);
                              } else if (_actionType == 'edit') {
                                await CommentApi().editComment(
                                    activeCommentId!, subscriberId, inputText);
                              } else {
                                await postCommentToAPI(inputText, subscriberId, postId);
                              }

                              await fetchComments(postId);
                              setModalState(() {
                                _actionTextController.clear();
                                activeCommentId = null;
                                _actionType = '';
                                _activeTargetName = '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }












}


