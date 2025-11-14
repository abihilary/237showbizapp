import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:showbizapp/components/subscription_dialog.dart';
import 'package:showbizapp/pages/swipper.dart';
import '../DTOs/post_model.dart';
import '../components/CustomCard.dart';
import '../components/buttomnav.dart';
import '../DTOs/UserModel.dart';

class RecentPostsPage extends StatefulWidget {
  final bool isDarkMode;
  const RecentPostsPage({super.key, required this.isDarkMode});

  @override
  _RecentPostsPageState createState() => _RecentPostsPageState();
}

class _RecentPostsPageState extends State<RecentPostsPage> {
  List<PostModel> posts = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int currentPage = 1;
  final ScrollController scrollController = ScrollController();
  final int postsPerPage = 10;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchPostData(currentPage);
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 300 && !isFetchingMore && hasMore) {
      _fetchPostData(currentPage + 1);
    }
  }

  Future<void> _fetchPostData(int page) async {
    if (page == 1) {
      setState(() => isLoading = true);
    }
    isFetchingMore = true;

    try {
      final Uri postsUrl = Uri.parse("https://237showbiz.com/wp-json/wp/v2/posts?page=$page&per_page=$postsPerPage&_embed=true");
      final response = await http.get(postsUrl);

      if (response.statusCode == 200) {
        final List<dynamic> postData = json.decode(response.body);
        if (postData.isNotEmpty) {
          final newPosts = postData.map((post) => PostModel.fromApiJson(post)).toList();
          setState(() {
            posts.addAll(newPosts);
            currentPage++;
            hasMore = newPosts.length == postsPerPage;
          });
        } else {
          setState(() => hasMore = false);
        }
      } else {
        throw Exception("Failed to load posts: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching posts: $e');
    } finally {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
    }
  }

  void _scrollToTop() {
    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onSubscribe() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionDialog(
        onSaveSubscriber: (name, email, subscriberId) {
          // Logic for saving subscriber is now in the dialog itself
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
      appBar: AppBar(
        title: const Text('Latest Hits'),
        backgroundColor: widget.isDarkMode ? const Color(0xFF0A1F44) : Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: scrollController,
            itemCount: posts.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < posts.length) {
                final post = posts[index];
                return CustomCard(
                  text: HtmlUnescape().convert(post.title ?? ''),
                  extraText: post.content ?? '',
                  date: post.date ?? '',
                  imageUrl: post.imageUrl ?? '',
                  likeCount: 0,
                  youtubeLink: post.youtubeLink ?? '',
                  isDarkMode: widget.isDarkMode,
                  isSubscribed: userModel.subscriberId.isNotEmpty,
                  onSubscribe: _onSubscribe,
                  postId: post.id?.toString() ?? '0',
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
          if (isLoading && posts.isEmpty)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ),
    );
  }
}