import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:showbizapp/pages/swipper.dart';
import 'package:showbizapp/services/onScrol.dart';
import '../components/CustomCard.dart';

import '../components/buttomnav.dart';

class RecentPostsPage extends StatefulWidget {
  final bool isDarkMode;
  const RecentPostsPage({ required this.isDarkMode});
  @override
  _RecentPostsPageState createState() => _RecentPostsPageState();
}

class _RecentPostsPageState extends State<RecentPostsPage> {
  List<dynamic> posts = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int currentPage = 1;
  bool postsLoaded = false;
  final  ScrollController scrollController = ScrollController();
  final int postsPerPage = 10; // Limits the number of posts fetched

  @override
  void initState() {
    super.initState();
    _fetchPostData(currentPage);
  }
  void _scrollToTop() {

    scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<List<dynamic>> _fetchCommentsForPost(int postId) async {
    final Uri commentsUrl = Uri.parse(
        "https://237showbiz.com/wp-json/wp/v2/comments?post=$postId");

    try {
      final response = await http.get(commentsUrl);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load comments for post $postId. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching comments for post $postId: $e');
      return [];
    }
  }
  Future<String?> _fetchYoutubeLink(int postId) async {
    final Uri postsUrl = Uri.parse("https://237showbiz.com/wp-json/wp/v2/posts/$postId");

    try {
      final response = await http.get(postsUrl);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final htmlContent = body['content']['rendered'] ?? '';

        // Extract YouTube link using RegExp
        final RegExp youtubeLinkRegex = RegExp(
          r'<iframe.*?src="(https://www\.youtube\.com/embed/[^"]+)"',
          caseSensitive: false,
        );
        final match = youtubeLinkRegex.firstMatch(htmlContent);

        if (match != null) {
          return match.group(1); // Return the YouTube link
        } else {
          print('No YouTube link found in post $postId.');
          return null;
        }
      } else {
        print('Failed to load post $postId. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching post $postId: $e');
      return null;
    }
  }

  Future<void> _fetchPostData(int page) async {
    if (isFetchingMore || postsLoaded) return;

    if (page == 1) { // Only set loading if it's the first page
      setState(() {
        isLoading = true;
      });
    }

    isFetchingMore = true;

    Uri postsUrl = Uri.parse(
      "https://237showbiz.com/wp-json/wp/v2/posts?page=$page&per_page=$postsPerPage&_embed=true",
    );

    try {
      final postsResponse = await http.get(postsUrl);

      if (postsResponse.statusCode == 200) {
        List<dynamic> postData = jsonDecode(postsResponse.body);

        List<dynamic> validPosts = await Future.wait(postData.map((post) async {
          var embedded = post['_embedded'] ?? {};
          var mediaLinks = embedded['wp:featuredmedia'] ?? [];

          String renderedContent = post['content']['rendered'] ?? "";
          String youtubeLink = _extractYouTubeLink(renderedContent);

          if (mediaLinks.isNotEmpty) {
            var imageUrl = mediaLinks[0]['source_url'];
            if (imageUrl != null) {
              List<dynamic> comments = await _fetchCommentsForPost(post['id']);

              return {
                ...post,
                'image_url': imageUrl,
                'date': post['date'],
                'likeCount': (post['likeCount'] as int?) ?? 0,
                'comments': comments,
                'rendered_content': renderedContent,
                'youtube_link': youtubeLink,
              };
            }
          }
          return null; // Skip invalid posts
        }).toList());

        validPosts.removeWhere((post) => post == null);

        setState(() {
          if (validPosts.isNotEmpty) {
            posts.addAll(validPosts);
            currentPage++;
          } else {
            _showErrorDialog("No more posts available.");
          }
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        throw Exception("Failed to load posts.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      _showErrorDialog("Error loading posts: $e");
    }
  }
  String _extractYouTubeLink(String htmlContent) {
    // Regex pattern to match YouTube links
    RegExp youtubeRegExp = RegExp(
      r'(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );

    var match = youtubeRegExp.firstMatch(htmlContent);
    if (match != null) {
      // Return the full YouTube URL or just the video ID if you’d prefer
      return match.group(0) ?? "";
    } else {
      return "";  // Return an empty string if no link is found
    }
  }

  void _loadMorePosts() {
    _fetchPostData(currentPage);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode?const Color(0xFF0A1F44) :  Colors.white,
      appBar: AppBar(
        title: const Text(
          "Latest",
          style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              posts.length < postsPerPage) { // Check if less than 10 posts
            _loadMorePosts();
          }
          return true;
        },
        child: Column(
          children: [
            const swipper(),
            SizedBox(height: 16,), // Replace with your actual swiper implementation
            Expanded(
              child: ListView.builder(

                itemCount: 10, // Limit the number of posts displayed to 10
                itemBuilder: (context, index) {
                  final post = posts[index]; // Get the post at the current index
                  return FutureBuilder<String?>(
                    future: _fetchYoutubeLink(post['id']), // Dynamically fetch the YouTube link
                    builder: (context, snapshot) {
                      final youtubeLink = snapshot.data ?? ''; // Use fetched link or fallback to empty string
                      return CustomCard(
                        imageUrl: post['image_url'],
                        text: post['title']['rendered'],
                        extraText: post['content']['rendered'],
                        date: post['date'],
                        likeCount: (post['likeCount'] as int?) ?? 0,
                        //comments: (post['comments'] as List<dynamic>?) ?? [],
                        youtubeLink: youtubeLink, // Pass the fetched YouTube link
                        isDarkMode: widget.isDarkMode, isSubscribed: true,
                        onSubscribe: () {  }, postId: '', subscriberId: '', subscriberName: '', onReply: null, // Pass theme-related state for dynamic styling
                      );
                    },
                  );
                },
              ),

            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,

        onPressed: () {
          // Scroll to the top of the list
          _scrollToTop();
        },
        child: Icon(Icons.arrow_upward,color: Colors.white,),
      ),
      // Replace with your actual bottom nav
    );
  }
}