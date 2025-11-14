import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Your other page imports
// import 'package:showbizapp/DTOs/VotingScreen.dart';
// import 'package:showbizapp/pages/GeneralVotingScreen.dart';

// --- Data Models ---
class Subscriber {
  final String username;
  final String email;
  final String id;
  final int banned;

  Subscriber({required this.username, required this.email, required this.id, required this.banned});
}

class Comment {
  final String username;
  final String comment;
  final String id;

  Comment({required this.username, required this.comment, required this.id});
}

// --- Admin Page Widget ---
class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // State variables for list expansion
  bool _isSubscribersExpanded = false;
  bool _isCommentsExpanded = false;
  final int _initialItemLimit = 3;

  // Controller for scrolling
  late ScrollController _scrollController;

  // Data lists and state management
  List<Subscriber> subscribers = [];
  List<Comment> comments = [];
  bool isLoadingSubscribers = false;
  bool isLoadingComments = false;
  String fetchErrorSubscribers = '';
  String fetchErrorComments = '';

  // MODIFIED: Controllers for notification title and body only
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    fetchSubscribers();
    fetchComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // MODIFIED: Dispose relevant controllers
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- UI Methods ---
  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // --- API Interaction Methods ---
  Future<void> toggleBanSubscriber(String subscriberId, int currentBanStatus) async {
    final newBanStatus = currentBanStatus == 0 ? 1 : 0;
    try {
      final response = await http.post(
        Uri.parse('https://api.237showbiz.com/api/subscribers/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': subscriberId, 'action': 'toggleBan'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          subscribers = subscribers.map((subscriber) {
            if (subscriber.id == subscriberId) {
              return Subscriber(id: subscriber.id, username: subscriber.username, email: subscriber.email, banned: newBanStatus);
            }
            return subscriber;
          }).toList();
        });
      }
    } catch (e) {
      print('Error toggling ban status: $e');
    }
  }

  Future<void> fetchSubscribers() async {
    setState(() => isLoadingSubscribers = true);
    try {
      final response = await http.get(Uri.parse('https://api.237showbiz.com/api/subscribers'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() => subscribers = data.map((item) => Subscriber(id: item['id']?.toString() ?? '', username: item['name'] ?? 'Unknown', email: item['email'] ?? 'No email', banned: item['banned'] ?? 0)).toList());
      }
    } finally {
      setState(() => isLoadingSubscribers = false);
    }
  }

  Future<void> fetchComments() async {
    setState(() => isLoadingComments = true);
    try {
      final response = await http.get(Uri.parse('https://api.237showbiz.com/api/comments'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() => comments = data.map((item) => Comment(username: item['subscriber_name'] ?? 'Unknown', comment: item['text'] ?? '', id: item['comment_id']?.toString() ?? '')).toList());
      }
    } finally {
      setState(() => isLoadingComments = false);
    }
  }

  void deleteSubscriber(String id) async {
    try {
      final response = await http.delete(Uri.parse('https://api.237showbiz.com/api/subscribers/?id=$id'));
      if (response.statusCode == 200) {
        setState(() => subscribers.removeWhere((sub) => sub.id == id));
      }
    } catch (e) {
      print('Error deleting subscriber: $e');
    }
  }

  void deleteComment(String id) async {
    try {
      final response = await http.delete(Uri.parse('https://api.237showbiz.com/api/comment/$id'));
      if (response.statusCode == 200) {
        setState(() => comments.removeWhere((com) => com.id == id));
      }
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  // --- UPDATED sendNotification Function (sends to all) ---
  void sendNotification() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Please fill in both title and body.')),
      );
      return;
    }

    // IMPORTANT: Make sure this URL points to your PHP script that sends to a TOPIC
    final String phpEndpointUrl = 'https://api.237showbiz.com/api/Notifications'; // Example URL

    try {
      final response = await http.post(
        Uri.parse(phpEndpointUrl),
        headers: {'Content-Type': 'application/json'},
        // The JSON body no longer contains a token
        body: jsonEncode({
          "title": title,
          "body": body,
        }),
      );
      print('Server Response Status Code: ${response.statusCode}');
      print('Server Response Body:\n${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody.containsKey('success') && responseBody['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Notification sent to all users!')));
          _titleController.clear();
          _bodyController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Backend Error: ${responseBody['error']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ HTTP Error: ${response.statusCode}, ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ An error occurred: $e')));
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final subscribersToShow = _isSubscribersExpanded ? subscribers : subscribers.take(_initialItemLimit);
    final commentsToShow = _isCommentsExpanded ? comments : comments.take(_initialItemLimit);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Subscribers Card ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscribers (${subscribers.length})', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    if (isLoadingSubscribers) Center(child: CircularProgressIndicator())
                    else if (subscribers.isEmpty) Text("No subscribers found.")
                    else ...[
                        ...subscribersToShow.map((sub) => ListTile(
                          title: Text(sub.username),
                          subtitle: Text(sub.email),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: Icon(Icons.block, color: sub.banned == 1 ? Colors.red : Colors.grey), onPressed: () => toggleBanSubscriber(sub.id, sub.banned)),
                            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteSubscriber(sub.id)),
                          ]),
                        )),
                        if (subscribers.length > _initialItemLimit)
                          TextButton(onPressed: () => setState(() => _isSubscribersExpanded = !_isSubscribersExpanded),style: TextButton.styleFrom(foregroundColor: Colors.orange,), child: Text(_isSubscribersExpanded ? 'View Less' : 'View More')),
                      ]
                  ],
                ),
              ),
            ),

            // --- Comments Card ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comments (${comments.length})', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    if (isLoadingComments) Center(child: CircularProgressIndicator())
                    else if (comments.isEmpty) Text("No comments found.")
                    else ...[
                        ...commentsToShow.map((com) => ListTile(
                          title: Text(com.username),
                          subtitle: Text(com.comment),
                          trailing: IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteComment(com.id)),
                        )),
                        if (comments.length > _initialItemLimit)
                          TextButton(onPressed: () => setState(() => _isCommentsExpanded = !_isCommentsExpanded),style: TextButton.styleFrom(foregroundColor: Colors.orange,),child: Text(_isCommentsExpanded ? 'View Less' : 'View More'),),
                      ]
                  ],
                ),
              ),
            ),

            // --- UPDATED Push Notification Card ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send Notification to All Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
                    const SizedBox(height: 16),
                    // Field for Title
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Notification Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // Field for Body/Message
                    TextField(
                      controller: _bodyController,
                      decoration: InputDecoration(labelText: 'Notification Body', border: OutlineInputBorder(), hintText: 'Enter your message here'),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: sendNotification,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: Size(double.infinity, 50)),
                      child: Text('Send to All', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
        tooltip: 'Scroll to Top',
      ),
    );
  }
}