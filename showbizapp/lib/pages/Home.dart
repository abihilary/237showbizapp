import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:showbizapp/DTOs/Mainscafold.dart';
import 'package:showbizapp/DTOs/VotingScreen.dart';
import 'package:showbizapp/pages/AboutUs.dart';
import 'package:showbizapp/pages/Admin.dart';
import 'package:showbizapp/pages/AdminGalleryUploadScreen.dart';
import 'package:showbizapp/pages/CommingSoon.dart';
import 'package:showbizapp/pages/Event.dart';
import 'package:showbizapp/pages/FreeStyle.dart';
import 'package:showbizapp/pages/LatestHit.dart';
import 'package:showbizapp/pages/News.dart';
import 'package:showbizapp/pages/surport.dart';
import '../DTOs/CardContent.dart';
import '../DTOs/UserModel.dart';
import '../DTOs/methods.dart';
import '../DTOs/post_model.dart';
import '../components/CustomCard.dart';
import '../components/buttomnav.dart';
import '237showbizStudios.dart';
import 'Artist.dart';
import 'MusicVideoPage.dart';
import 'package:showbizapp/pages/swipper.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';





class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  bool isLoadingMore = false;
  bool isDarkMode = false;
  bool showAdmin = true;
  List<dynamic> posts = [];
  int currentPage = 1;
  final int postsPerPage = 10;
  bool isFetchingMore = false;
  final List<int> loadedPages = [1];
  late String newName;
  bool isOnline = true;

  late ScrollController _scrollController = ScrollController();
  List<dynamic> filteredPosts = [];

  bool get searching => _searchController.text.isNotEmpty;
  bool showSearchField = false;
  bool postsLoaded = false;
  bool _hasShownDialog = false;
  late final String matchGeneratedCode;
  bool hasMorePosts = true;
  String? notificationMessage;
  late WebSocketChannel channel;
  bool isSubscribed = false;
  late String subscriberName;


  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _codeController = TextEditingController();

  int step = 1;
  String generatedCode = '';
  bool showCodeField = false;
  Map<String, dynamic>? subscriberData;
  bool hasMore = true;


  //bool isDarkTheme = true;
//verification section
  Future<void> sendVerificationEmail(String name, String email,
      String code) async {

    String username = '237showbiz@gmail.com';
    String password = 'vwgjkxcqqbtocbdu';

    final smtpServer = gmail(
        username, password); // or use smtp(username, host, ...)

    final message = Message()
      ..from = Address(username, '237showbiz')
      ..recipients.add(email)
      ..subject = 'Your Verification Code'
      ..text = 'Hello $name,\n\nYour verification code is: $code\n\nThanks for subscribing!';

    try {
      final sendReport = await send(message, smtpServer);

      print('Message sent: ' + sendReport.toString());
    } catch (e) {
      print('Message not sent. $e');
      throw Exception('Failed to send email: $e');
    }
  }

  Future<Map<String, dynamic>?> getLocalSubscriber() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberString = prefs.getString('subscriber');

    if (subscriberString != null) {
      return jsonDecode(subscriberString);
    }
    return null; // Return null if no data found
  }

  //notification
  void showNotification(String message) {
    setState(() {
      notificationMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        notificationMessage = null;
      });
    });
  }

  void unSubscribe() {
    clearLocalStorage();

    setState(() {
      _hasShownDialog = !_hasShownDialog;
    });

    // Show a success SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have unsubscribed successfully.'),
        backgroundColor: Colors.redAccent, // Optional: for better visibility
      ),
    );
  }
  Future<bool> replyToComment(String commentId, String subscriberId, String text) async {
    final url = Uri.parse(
        'https://api.237showbiz.com/api/comment_interaction/?comment_id=$commentId&subscriber_id=$subscriberId');

    final payload = jsonEncode({
      'action': 'reply',
      'text': text,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // include authorization headers if needed, e.g.,
          // 'Authorization': 'Bearer your_token_here',
        },
        body: payload,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print('Failed to reply: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error replying to comment: $e');
    }
    return false;
  }

  Future<void> _loadSubscriberData() async {
    final data = await getLocalSubscriber();
    if (data != null && data['subscriber_id'] != null &&
        data['subscriber_id'] != '0') {
      setState(() {
        subscriberData = data;
      });
    } else {
      print('Invalid or missing subscriber data: $data');
    }
  }


  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    generatedCode =
        (Random().nextInt(900000) + 100000).toString(); // e.g. 463812

    try {
      await sendVerificationEmail(name, email, generatedCode);
      setState(() {
        step = 2;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email failed: $e')),
      );
    }
  }

  Future<void> clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _verifyCode() {
    if (_codeController.text.trim() == generatedCode) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for subscribing!')),
      );
      _nameController.clear();
      _emailController.clear();
      _codeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect code. Please try again.')),
      );
    }
  }

  Future<void> saveLocalSubscriber(String name, String email,
      String subscriberId) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriber = jsonEncode(
        {'name': name, 'email': email, "subscriber_id": subscriberId});
    await prefs.setString('subscriber', subscriber);
  }

  Future<bool> hasLocalSubscriber() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('subscriber');

    if (data == null || data.isEmpty) return false;

    try {
      final Map<String, dynamic> json = jsonDecode(data);
      return json['subscriber_id'] != null && json['subscriber_id'] != '0';
    } catch (e) {
      print('Error decoding subscriber data: $e');
      return false;
    }
  }
  Future<String?> getSubscriberId() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberJson = prefs.getString('subscriber');
    if (subscriberJson == null) return null;

    final Map<String, dynamic> subscriber = jsonDecode(subscriberJson);
    return subscriber['subscriber_id'];
  }


  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Show subscription dialog if needed
    if (_hasShownDialog) {
      _showSubscribeDialog();
    }

    // Initial fetch - page 1
    _fetchPostData(currentPage);
  }



  void _onScroll() {
    print('🟡 Scroll position: ${_scrollController.position.pixels}');
    print('🟡 Max scroll: ${_scrollController.position.maxScrollExtent}');

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300 &&
        !isLoading &&
        hasMore) {
      _fetchPostData(currentPage+1); // Load next page
    }
  }
  bool hasMoreData = true;
  void _loadMorePosts() {
    if (isFetchingMore) return;

    setState(() => isFetchingMore = true);

    currentPage += 1; // ✅ Go to next page

    _fetchPostData(currentPage).then((_) {
      setState(() => isFetchingMore = false);
    });
  }



  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController
        .dispose(); // Clean up the controller when the widget is disposed
    super.dispose();
  }

  void ShowSearchField() {
    setState(() {
      showSearchField = !showSearchField;
    });
  }

  // void _toggleTheme(bool value) {
  //   setState(() {
  //     isDarkTheme = value;
  //     // Apply your theme logic here (e.g., use ThemeProvider or similar)
  //   });
  // }

  Future<List<dynamic>> _fetchCommentsForPost(int postId) async {
    final Uri commentsUrl1 = Uri.parse(
        "https://237showbiz.com/wp-json/wp/v2/comments?post=$postId");
    final Uri commentsUrl2 = Uri.parse(
        "https://api.237showbiz.com/api/comments/$postId");
    print(postId.toString());

    try {
      final response1 = await http.get(commentsUrl1);
      final response2 = await http.get(commentsUrl2);

      List<dynamic> comments = [];

      if (response1.statusCode == 200) {
        final decodedResponse1 = jsonDecode(response1.body);
        if (decodedResponse1 != null && decodedResponse1 is List) {
          comments.addAll(decodedResponse1);
        } else {
          print('Unexpected response format from first endpoint');
        }
      } else {
        print(
            'Failed to load comments from first endpoint. Status code: ${response1
                .statusCode}');
      }

      if (response2.statusCode == 200) {
        final decodedResponse2 = jsonDecode(response2.body);
        if (decodedResponse2 != null && decodedResponse2 is List) {
          comments.addAll(decodedResponse2);
        } else {
          print('Unexpected response format from second endpoint');
        }
      } else {
        print(
            'Failed to load comments from second endpoint. Status code: ${response2
                .statusCode}');
      }

      return comments;
    } catch (e) {
      print('Error fetching comments for post $postId: $e');
      return [];
    }
  }

  // Create a cache to store fetched YouTube links
  final Map<int, String?> youtubeLinkCache = {};

// Set to track which postIds have been logged
  final Set<int> loggedPostIds = {};

  Future<String?> _fetchYoutubeLink(int postId) async {
    // Check if the link is already in the cache
    if (youtubeLinkCache.containsKey(postId)) {
      return youtubeLinkCache[postId];
    }

    final Uri postsUrl = Uri.parse(
        "https://237showbiz.com/wp-json/wp/v2/posts/$postId");

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
          // Cache the found YouTube link
          youtubeLinkCache[postId] = match.group(1);
          return match.group(1); // Return the YouTube link if found
        } else {
          // No YouTube link found; handle logging
          if (!loggedPostIds.contains(postId)) {
            print('No YouTube link found in post $postId.');
            loggedPostIds.add(postId); // Mark this postId as logged
          }
          youtubeLinkCache[postId] = null; // Cache the result as null
          return null; // Explicitly returning null if no link is found
        }
      } else {
        // Handle non-200 status codes
        print('Failed to load post $postId. Status code: ${response.statusCode}');
        youtubeLinkCache[postId] = null; // Cache the failed result as null
        return null;
      }
    } catch (e) {
      // Handle any errors that may occur during the network request
      print('Error fetching post $postId: $e');
      youtubeLinkCache[postId] = null; // Cache the error result as null
      return null;
    }
  }


  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }


// Inside your class
  Future<void> _fetchPostData(int page) async {
    if (isFetchingMore || postsLoaded) return;
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showErrorDialog("No internet connection. Please check your network.");
      return;
    }
    final postsBox = Hive.box<PostModel>('postsBox');

    if (page == 1) {
      setState(() {
        isLoading = true;
      });
    }

    isFetchingMore = true;

    if (!isOnline) {
      // 🔁 Load from cache when offline
      final cachedPosts = postsBox.values.toList();
      if (cachedPosts.isEmpty) {
        _showErrorDialog("No internet and no cached posts available.");
      } else {
        setState(() {
          posts = cachedPosts.map((p) => {
            'id': p.id,
            'title': p.title,
            'image_url': p.imageUrl,
            'date': p.date,
            'rendered_content': p.content,
            'youtube_link': p.youtubeLink,
          }).toList();
        });
      }

      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      return;
    }




    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: 60),
        receiveTimeout: Duration(seconds: 60),
      ),
    );

    Uri postsUrl = Uri.parse(
      "https://237showbiz.com/wp-json/wp/v2/posts?page=$page&per_page=$postsPerPage&_embed=true",
    );

    // Retry configuration
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await dio.getUri(
          postsUrl,
          options: Options(responseType: ResponseType.json),
        );

        if (response.statusCode == 200) {
          List<dynamic> postData = response.data;

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
          break; // Success
        } else {
          throw Exception("Failed to load posts: ${response.statusCode}");
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          attempt++;
          if (attempt >= maxRetries) {
            _showErrorDialog("Request timed out. Please try again later.");
            setState(() {
              isLoading = false;
              isFetchingMore = false;
            });
          }
        } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
          // Network error, server error, etc.
          attempt++;
          if (attempt >= maxRetries) {
            _showErrorDialog("Network error. Please check your internet connection.");
            setState(() {
              isLoading = false;
              isFetchingMore = false;
            });
          } else {
            await Future.delayed(Duration(seconds: 2));
          }
        } else {
          // Other errors
          _showErrorDialog("Error loading posts: $e");
          setState(() {
            isLoading = false;
            isFetchingMore = false;
          });
          break;
        }
      } catch (e) {
        _showErrorDialog("Unexpected error: $e");
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
        break;
      }
    }
  }


// Function to extract YouTube link from the HTML
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
      return ""; // Return an empty string if no link is found
    }
  }





  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _toggleThemeColor(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  // Inside the build method of Home
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    return FutureBuilder<Map<String, dynamic>?>(

      future: getLocalSubscriber(),
      builder: (context, subscriberSnapshot) {
        // Set subscriberName and ID based on data availability
        final subscriber = subscriberSnapshot.data;
        final hasSubscriber = subscriber != null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (subscriber != null && subscriber['name'] != null) {
            userModel.setUsername(subscriber['name'].toString());
            userModel.setSubscriberId(subscriber['subscriber_id'].toString());
          } else {
            userModel.setUsername('');
          }
        });
        final subscriberName = hasSubscriber ? subscriber['name']?.toString() ??
            "" : "";
        final subscriberId = hasSubscriber ? subscriber['subscriber_id']
            ?.toString() ?? "" : "";


        return MainScaffold(
          backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors
                .orange[600],
            leading: Builder(
              builder: (context) =>
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
            title: Center(
                child: Image.asset('assets/applogo.png', height: 100)),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.video_camera_front, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Text(
                      'Live',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(
              context, isDarkMode, _toggleThemeColor, subscriberName, () {}),
          body: Stack(
            children: [
              // Scrollable content
              Padding(
                padding: EdgeInsets.only(top: showSearchField ? 80 : 0), // leave space for fixed search
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: (searching ? filteredPosts.length : posts.length) + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return const swipper();

                    final dataList = searching ? filteredPosts : posts;

                    if (index == dataList.length + 1) {
                      return isLoading
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                          : const SizedBox.shrink();
                    }

                    final post = dataList[index - 1];

                    return FutureBuilder<String?>(
                      future: _fetchYoutubeLink(post['id']),
                      builder: (context, snapshot) {
                        final youtubeLink = snapshot.data ?? '';
                        return CustomCard(
                          imageUrl: post['image_url'],
                          text: HtmlUnescape().convert(post['title']?['rendered'] ?? ''),
                          extraText: post['content']?['rendered'] ?? '',
                          date: post['date'] ?? '',
                          likeCount: (post['likeCount'] as int?) ?? 0,
                          youtubeLink: youtubeLink,
                          isDarkMode: isDarkMode,
                          isSubscribed: _hasShownDialog,
                          onSubscribe: _showSubscribeDialog,
                          postId: post['id']?.toString() ?? "0",
                          subscriberId: subscriberId,
                          subscriberName: subscriberName,
                          onReply: (String commentId, String replyText) async {
                            final success = await replyToComment(commentId, subscriberId, replyText);
                            if (success) {
                              print("✅ Reply posted to $commentId");
                            } else {
                              print("❌ Failed to reply to $commentId");
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // 🔍 Fixed Search Bar
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
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87),
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search posts...',
                              hintStyle: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black87),
                              prefixIcon: Icon(Icons.search,
                                  color: isDarkMode ? Colors.white : Colors.black87),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                filteredPosts = posts.where((post) {
                                  final title = post['title']?['rendered']
                                      ?.toString()
                                      .toLowerCase() ??
                                      '';
                                  final content = post['content']?['rendered']
                                      ?.toString()
                                      .toLowerCase() ??
                                      '';
                                  return title.contains(value.toLowerCase()) ||
                                      content.contains(value.toLowerCase());
                                }).toList();
                              });
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showSearchField = false;
                              _searchController.clear();
                              filteredPosts = posts;
                            });
                          },
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Other overlays
              if (notificationMessage != null)
                Positioned(
                  top: showSearchField ? 90 : 50,
                  left: 20,
                  right: 20,
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        notificationMessage!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              if (isLoading && posts.isEmpty)
                const Center(child: CircularProgressIndicator()),

              if (!isLoading && posts.isEmpty)
                Center(
                  child: ElevatedButton(
                    onPressed: () => _fetchPostData(currentPage),
                    child: const Text('Refresh'),
                  ),
                ),

              if (isFetchingMore)
                const Center(child: CircularProgressIndicator()),
            ],
          ),


          floatingActionButton: posts.isNotEmpty
              ? FloatingActionButton(
            onPressed: _scrollToTop,
            backgroundColor: isDarkMode ? const Color(0xFF0A1F44) : Colors
                .orange[600],
            child: const Icon(Icons.arrow_upward, color: Colors.white),
          )
              : null,
          selectedIndex: 0,
          externalSearchFunction: (){
            setState(() {
              showSearchField = true;
            });
          },
        );
      },
    );
  }


  Widget _buildDrawer(BuildContext context, bool isDarkTheme,
      Function(bool) onThemeChanged, String? subscriberName,
      VoidCallback onUnsubscribe) {
    final userModel = Provider.of<UserModel>(context);
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: isDarkTheme ? const Color(0xFF0A1F44) : Colors
          .orange[600],


      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: isDarkTheme ? const Color(0xFF0A1F44) : Colors.orange[600],
            height: 80,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Row(
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    "UserName: ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: "Poppins",
                    ),
                  ),
                  Text(
                    userModel.username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),

                ],
              ),
            ),
          ),

          Divider(),
          ExpansionTile(
            title: const Text(
              'Music',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins"),
            ),
            leading: const Icon(Icons.library_music, color: Colors.white),
            trailing: const Icon(
                Icons.keyboard_arrow_down_rounded, color: Colors.white,
                size: 30),
            children: [
              _buildDrawerItem('Latest Hits', () =>
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          RecentPostsPage(isDarkMode: isDarkMode,)))),
              _buildDrawerItem('Music Video', () =>
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => MusicVideo()))),
            ],
          ),
          ExpansionTile(
            title: const Text(
              'Our Services',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins"),
            ),
            leading: const Icon(Icons.newspaper, color: Colors.white),
            trailing: const Icon(
                Icons.keyboard_arrow_down_rounded, color: Colors.white,
                size: 30),
            children: [
              _buildDrawerItem('237Showbiz Studios', () =>
    Navigator.push(context,
    MaterialPageRoute(builder: (context) => ShowbizStudiosPage()))),
              _buildDrawerItem('Shows', () =>Navigator.push(context, MaterialPageRoute(builder: (context) =>
                  Commingsoon())),),
            ],
          ),ListTile(
              title: const Text('Movies', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.movie, color: Colors.white),
              onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (context) =>
             Commingsoon())),),
          ListTile(
            title: const Text('Artists', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.person, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    GalleryPage())),
          ),
          ListTile(
            title: const Text('Events', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.person, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    EventsPage())),
          ),
          ListTile(
            title: const Text('News', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.person, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                   NewsPage())),
          ),
          ListTile(
            title: const Text('Trending', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.trending_down_sharp, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    Commingsoon())),
          ),
          ListTile(
            title: const Text('Contact Us', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.group, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    ContactPage(isDarkMode: isDarkMode,))),
          ),
          ListTile(
            title: const Text('About Us', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.event, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    AboutUs())),
          ), ListTile(
            title: const Text('Vote', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.how_to_vote, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    VotingScreen())),
          ),
          ListTile(
            title: const Text('Live', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.video_camera_front, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    Commingsoon())),
          ),
          // Theme Switcher
          ListTile(
            title: const Text('Switch Theme', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.brightness_4, color: Colors.white),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                onThemeChanged(value); // Trigger theme change
              },
            ),
          ),
         showAdmin? ListTile(
            title: const Text('Admin', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.event, color: Colors.white),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    AdminPage())),
          ):Container(),
          ExpansionTile(
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
            leading: const Icon(Icons.settings, color: Colors.white),
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 30,
            ),
            children: [
              // Subscribe button


              // Update Subscription button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextButton.icon(
                  onPressed: ()async {
                    final id = await getSubscriberId();
                    showUpdateModal(context,subscriberId: id.toString(),isDarkMode:isDarkMode,username: subscriberName!.toUpperCase().toString() );
                  },
                  icon: Icon(Icons.update, color: Colors.white),
                  label: Text(
                    "Update Subscription",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Unsubscribe button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextButton.icon(
                  onPressed: () {
                    unSubscribe();
                  },
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    "Unsubscribe",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),



        ],
      ),
    );
  }


  Widget _buildDrawerItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontFamily: "Poppins")),
        onTap: onTap,
      ),
    );
  }

  // place this at the top level of your widget (e.g. as a field in your State)

  void _showSubscribeDialog() async {
    final alreadySubscribed = await hasLocalSubscriber();
    if (alreadySubscribed) {
      print("User already subscribed. Dialog won't show.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSendingCode = false;
        bool isVerifyingCode = false;
        final userModel = Provider.of<UserModel>(context);

        return StatefulBuilder(
          builder: (context, setState) {
            final isLoading = isSendingCode || isVerifyingCode;

            return Stack(
              children: [
                AlertDialog(
                  title: const Text(
                    'Subscribe for Interactions',
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(),
                        if (!showCodeField) ...[
                          TextField(
                            controller: _nameController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(labelText: 'Name'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          if (isSendingCode)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                        if (showCodeField) ...[
                          const Text(
                            'Enter the code sent to your email',
                            style: TextStyle(fontFamily: "Poppins"),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _codeController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(labelText: 'Verification Code'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          if (isVerifyingCode)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        Navigator.of(context).pop();
                        _nameController.clear();
                        _emailController.clear();
                        _codeController.clear();
                        _fetchPostData(currentPage);
                        setState(() {
                          showCodeField = false;
                        });
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.redAccent, fontFamily: "Poppins"),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: showCodeField ? Colors.green : Colors.orange,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                        if (!showCodeField) {
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          if (name.isEmpty || email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter both name and email')),
                            );
                            return;
                          }

                          String newGeneratedCode =
                          (Random().nextInt(900000) + 100000).toString();

                          setState(() {
                            generatedCode = newGeneratedCode;
                            isSendingCode = true;
                          });
                          print("Generated code: $generatedCode");

                          try {
                            await sendVerificationEmail(name, email, generatedCode);
                            setState(() {
                              showCodeField = true;
                              isSendingCode = false;
                            });
                          } catch (e) {
                            setState(() {
                              isSendingCode = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send email: $e')),
                            );
                          }
                        } else {
                          if (_codeController.text.trim() == generatedCode) {
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();

                            final uri = Uri.parse('https://api.237showbiz.com/api/subscribers');

                            setState(() {
                              showAdmin = true;
                              isVerifyingCode = true;
                            });

                            try {
                              final response = await http.post(
                                uri,
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'name': name, 'email': email}),
                              );

                              print("Response status: ${response.statusCode}");
                              print("Response body: ${response.body}");

                              final responseData = jsonDecode(response.body);

                              if ((response.statusCode == 200 || response.statusCode == 201) &&
                                  responseData['id'] != null &&
                                  responseData['id']['subscriber_id'] != null) {
                                final idData = responseData['id'];
                                final subscriberIdRaw = idData['subscriber_id'];

                                String subscriberId;
                                if (subscriberIdRaw is Map &&
                                    subscriberIdRaw.containsKey('subscriber_id')) {
                                  subscriberId = subscriberIdRaw['subscriber_id'].toString();
                                } else {
                                  subscriberId = subscriberIdRaw.toString();
                                }

                                print("Subscriber ID: $subscriberId");
                                if (email.toLowerCase() == '237showbiz@gmail.com' &&
                                    name.toLowerCase() == 'admin') {
                                  setState(() {
                                    showAdmin = true;
                                  });
                                }

                                userModel.setUsername(name);
                                await saveLocalSubscriber(name, email, subscriberId);

                                setState(() {
                                  _hasShownDialog = !_hasShownDialog;
                                  showCodeField = false;
                                  isVerifyingCode = false;
                                });

                                Navigator.of(context).pop();
                                _nameController.clear();
                                _emailController.clear();
                                _codeController.clear();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you for subscribing!',
                                        style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                setState(() {
                                  isVerifyingCode = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to save subscriber: ${response.body}'),
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                isVerifyingCode = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Network error: $e')),
                              );
                            }
                          } else {
                            setState(() {
                              isVerifyingCode = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Incorrect verification code.')),
                            );
                          }
                        }
                      },
                      child: Text(
                        showCodeField ? 'Verify Code' : 'Send Code',
                        style: const TextStyle(color: Colors.white, fontFamily: "Poppins"),
                      ),
                    ),
                  ],
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black87,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }




}
