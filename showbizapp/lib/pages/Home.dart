// pages/Home.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:provider/provider.dart';
import 'package:showbizapp/DTOs/Mainscafold.dart';
import 'package:showbizapp/DTOs/UserModel.dart';
import 'package:showbizapp/DTOs/methods.dart';
import 'package:showbizapp/DTOs/post_model.dart';
import 'package:showbizapp/components/CustomCard.dart';
import 'package:showbizapp/components/main_drawer.dart';
import 'package:showbizapp/components/subscription_dialog.dart';
import 'package:showbizapp/pages/swipper.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:dio_retry_plus/dio_retry_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool isDarkMode = false;
  List<PostModel> posts = [];
  int currentPage = 1;
  final int postsPerPage = 10;
  bool isFetchingMore = false;
  late ScrollController _scrollController;
  bool showSearchField = false;
  bool hasMore = true;
  String? notificationMessage;
  String _currentSearchTerm = '';
  Timer? _debounce;

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  @override
  void initState() {
    super.initState();


    // NEW: Load user data from SharedPreferences on startup
    _loadSubscriberData();

    _scrollController = ScrollController()..addListener(_onScroll);
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: 3,
        retryDelays: const [Duration(seconds: 2)],
        toNoInternetPageNavigator: () async => _showErrorDialog("No internet connection"),
        logPrint: print,
      ),
    );
    _fetchPostData();
    //_setupFirebaseMessaging();
    //_requestNotificationPermissionAfterBuild();
   //start from here
  }

  // NEW METHOD: Load user data from SharedPreferences
  Future<void> _loadSubscriberData() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberId = prefs.getString('subscriberId');
    final subscriberName = prefs.getString('subscriberName');

    if (subscriberId != null && subscriberName != null) {
      // Update the UserModel if data is found
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.setSubscriber(subscriberName, subscriberId);
    }
  }


  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 && !isFetchingMore && hasMore) {
      if (_currentSearchTerm.isNotEmpty) {
        _fetchPostData(page: currentPage + 1, searchQuery: _currentSearchTerm);
      } else {
        _fetchPostData(page: currentPage + 1);
      }
    }
  }

  // MODIFIED: Added logic to reset state for a refresh
  Future<void> _fetchPostData({int page = 1, String? searchQuery, bool isRefresh = false}) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _handleNoInternet();
      return;
    }

    if (page == 1 || isRefresh) {
      setState(() {
        // Only show loading if it's the initial load or a non-search refresh
        isLoading = isRefresh ? false : true;
        posts.clear(); // Clear existing posts for a new search or initial load
        hasMore = true; // Assume we have more posts on a fresh fetch
        currentPage = 1; // Reset page number
      });
    }

    // Prevent fetching if a search query is cleared but the list is already clear
    if (searchQuery != null && searchQuery.isEmpty && posts.isEmpty && !isRefresh) {
      setState(() => isLoading = false);
      return;
    }

    isFetchingMore = true;
    String apiUrl = "https://237showbiz.com/wp-json/wp/v2/posts?page=$page&per_page=$postsPerPage&_embed=true";
    if (searchQuery != null && searchQuery.isNotEmpty) {
      apiUrl += "&search=$searchQuery";
    }

    Uri postsUrl = Uri.parse(apiUrl);

    try {
      final response = await dio.getUri(postsUrl, options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        List<dynamic> postData = response.data;
        if (postData.isNotEmpty) {
          final postsBox = Hive.box<PostModel>('postsBox');
          final newPosts = postData.map((post) => PostModel.fromApiJson(post)).toList();

          setState(() {
            posts.addAll(newPosts);
            currentPage = page;
            isFetchingMore = false;
            isLoading = false;
            hasMore = newPosts.length == postsPerPage;
          });

          if (searchQuery == null) {
            for (var post in newPosts) {
              postsBox.put(post.id, post);
            }
          }
        } else {
          setState(() {
            hasMore = false;
            isFetchingMore = false;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load posts: ${response.statusCode}");
      }
    } on DioException catch (e) {
      _showErrorDialog("Network error. Please check your internet connection or try again.");
    } catch (e) {
      _showErrorDialog("Unexpected error: $e");
    } finally {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
    }
  }

  // NEW METHOD: Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    // Only refresh if not searching
    if (_currentSearchTerm.isEmpty) {
      await _fetchPostData(page: 1, isRefresh: true);
    } else {
      // If searching, re-fetch the current search term on page 1
      await _fetchPostData(page: 1, searchQuery: _currentSearchTerm, isRefresh: true);
    }
  }


  void _handleNoInternet() {
    _showErrorDialog("No internet connection. Please check your network.");
    final postsBox = Hive.box<PostModel>('postsBox');
    final cachedPosts = postsBox.values.toList();
    if (cachedPosts.isEmpty) {
      _showErrorDialog("No internet and no cached posts available.");
    } else {
      setState(() => posts = cachedPosts);
    }
    setState(() => isLoading = false);
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Error"),
        content: Text(errorMessage),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
      ),
    );
  }

  void _toggleThemeColor(bool value) {
    setState(() => isDarkMode = value);
  }

  void _scrollToTop() {
    _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _showSubscribeDialog() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (userModel.subscriberId.isNotEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionDialog(
        onSaveSubscriber: (name, email, subscriberId) async {
          // This logic is handled within the SubscriptionDialog
        },
      ),
    );
  }

  Future<void> unSubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear the specific keys used for persistence
    await prefs.remove('subscriberName');
    await prefs.remove('subscriberId');

    final userModel = Provider.of<UserModel>(context, listen: false);
    userModel.setSubscriber('', '');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have unsubscribed successfully.'), backgroundColor: Colors.redAccent));
  }

  void _handleUpdateSubscription() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    showUpdateModal(
      context,
      isDarkMode: isDarkMode,
      subscriberId: userModel.subscriberId,
      username: userModel.username.toUpperCase(),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentSearchTerm = query;
        currentPage = 1;
        hasMore = true;
      });
      if (query.isNotEmpty) {
        _fetchPostData(page: 1, searchQuery: query);
      } else {
        _fetchPostData(page: 1);
      }
    });
  }

  void _toggleSearchField() {
    setState(() {
      showSearchField = !showSearchField;
      if (!showSearchField) {
        _searchController.clear();
        _onSearchChanged('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    return MainScaffold(
      isDarkMode: isDarkMode,
      backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.orange[600],
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => Scaffold.of(context).openDrawer())),
        title: Center(child: Image.asset('assets/applogo.png', height: 100)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.video_camera_front, color: Colors.white), onPressed: () {}),
                const Text('Live', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      drawer: MainDrawer(
        isDarkMode: isDarkMode,
        onThemeChanged: _toggleThemeColor,
        subscriberName: userModel.username,
        onUnsubscribe: unSubscribe,
        onUpdateSubscription: _handleUpdateSubscription,
        getSubscriberId: () => Future.value(userModel.subscriberId),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: showSearchField ? 80 : 0),
            // WRAP THE LIST VIEW WITH RefreshIndicator
            child: isLoading && posts.isEmpty && _currentSearchTerm.isEmpty // Only show initial loading spinner if no posts exist and we're not searching
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty && !isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No results found.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_currentSearchTerm.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _toggleSearchField();
                      },
                      child: const Text("Go back to home"),
                    ),
                ],
              ),
            )
                : RefreshIndicator( // Added RefreshIndicator
              onRefresh: _handleRefresh,
              color: isDarkMode ? Colors.white : Colors.orange,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: posts.length + (hasMore && _currentSearchTerm.isEmpty ? 1 : 0), // Only show loading spinner on bottom when not searching
                itemBuilder: (context, index) {
                  if (index == 0 && _currentSearchTerm.isEmpty) {
                    return const swipper();
                  }
                  if (index >= posts.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final post = posts[index];
                  return CustomCard(
                    text: HtmlUnescape().convert(post.title ?? ''),
                    extraText: post.content ?? '',
                    date: post.date ?? '',
                    imageUrl: post.imageUrl ?? '',
                    likeCount: 0,
                    youtubeLink: post.youtubeLink ?? '',
                    isDarkMode: isDarkMode,
                    isSubscribed: userModel.subscriberId.isNotEmpty,
                    onSubscribe: _showSubscribeDialog,
                    postId: post.id?.toString() ?? '0',
                  );
                },
              ),
            ),
          ),
          if (showSearchField)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search posts...',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black87),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleSearchField,
                      child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: posts.isNotEmpty && !showSearchField ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.orange[600],
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ) : null,
      selectedIndex: 0,
      externalSearchFunction: _toggleSearchField,
    );
  }
}