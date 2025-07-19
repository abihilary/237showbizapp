import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:showbizapp/DTOs/VotingScreen.dart';
import 'package:showbizapp/pages/AdminGalleryUploadScreen.dart';
import 'package:showbizapp/pages/AdminNewsEventScreen.dart';
import 'package:showbizapp/pages/GeneralVotingScreen.dart';

import 'AddEventScreen.dart';


class Subscriber {
  final String username;
  final String email;
  final String id;
  final int banned; // Add this

  Subscriber({required this.username, required this.email, required this.id, required this.banned});
}


class Comment {
  final String username;
  final String comment;
  final String id;

  Comment({required this.username, required this.comment, required this.id});
}

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Subscriber> subscribers = [];
  List<Comment> comments = [];
  bool isLoadingSubscribers = false;
  bool isLoadingComments = false;
  String fetchErrorSubscribers = '';
  String fetchErrorComments = '';
  TextEditingController _notificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSubscribers();
    fetchComments();
  }
  Future<void> toggleBanSubscriber(String subscriberId, int currentBanStatus) async {
    print("bann status is: $currentBanStatus and $subscriberId");
    final newBanStatus = currentBanStatus == 0 ? 1 : 0;

    try {
      final response = await http.post(
        Uri.parse('https://api.237showbiz.com/api/subscribers/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': subscriberId,
          'action': 'toggleBan',
        }),
      );

      if (response.statusCode == 200) {
        print('Subscriber $subscriberId ban status updated to $newBanStatus');

        // Optionally update your local state here if you have a subscribers list
        setState(() {
          subscribers = subscribers.map((subscriber) {
            if (subscriber.id == subscriberId) {
              return Subscriber(
                id: subscriber.id,
                username: subscriber.username,
                email: subscriber.email,
                banned: newBanStatus,
              );
            }
            return subscriber;
          }).toList();
        });
      } else {
        // Print the status code and the response body for debugging
        print('Failed to update ban status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error toggling ban status: $e');
    }
  }



  Future<void> fetchSubscribers() async {
    setState(() {
      isLoadingSubscribers = true;
      fetchErrorSubscribers = '';
    });
    try {
      final response = await http.get(Uri.parse('https://api.237showbiz.com/api/subscribers'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Subscribers raw response: ${response.body}'); // debug

        // Print each id to verify it's parsed correctly
        for (var item in data) {
          print('Subscriber id: ${item['id']}');
        }

        setState(() {
          subscribers = data.map((item) => Subscriber(
            id: item['id'] ?? '',
            username: item['name'] ?? 'Unknown',
            email: item['email'] ?? 'No email',
            banned: item['banned'] ?? 0,
          )).toList();
        });
      } else {
        setState(() {
          fetchErrorSubscribers = 'Error: Server responded ${response.statusCode}';
        });
        print('Failed to load subscribers: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        fetchErrorSubscribers = 'Error: $e';
      });
      print('Error fetching subscribers: $e');
    } finally {
      setState(() {
        isLoadingSubscribers = false;
      });
    }
  }


  Future<void> fetchComments() async {
    setState(() {
      isLoadingComments = true;
      fetchErrorComments = '';
    });
    try {
      final response = await http.get(Uri.parse('https://api.237showbiz.com/api/comments'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Comments raw response: ${response.body}'); // debug
        setState(() {
          comments = data.map((item) => Comment(
            username: item['subscriber_name'] ?? 'Unknown',
            comment: item['text'] ?? '',
            id: item['comment_id'] ?? '',
          )).toList();
        });
      } else {
        setState(() {
          fetchErrorComments = 'Error: Server responded ${response.statusCode}';
        });
        print('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        fetchErrorComments = 'Error: $e';
      });
      print('Error fetching comments: $e');
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  void deleteSubscriber(String id) async {
    try {
      print('Attempting to delete subscriber with ID: $id');

      final response = await http.delete(
        Uri.parse('https://api.237showbiz.com/api/subscribers/?id=$id'),
        headers: {'Content-Type': 'application/json'},
      );


      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          subscribers.removeWhere((sub) => sub.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscriber deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete subscriber. Status: ${response.statusCode}')),
        );
        print('Failed to delete subscriber. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred while deleting subscriber: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting subscriber: $e')),
      );
    }
  }


  void deleteComment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('https://api.237showbiz.com/api/comment/$id'),
          headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          comments.removeWhere((com) => com.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment. Server responded with status ${response.statusCode}')),
        );
        print('Error: Server responded with ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
      );
      print('Error deleting comment: $e');
    }
  }


  void sendNotification() {
    String message = _notificationController.text;
    if (message.isNotEmpty) {
      // Implement your push notification logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent: "$message"')),
      );
      _notificationController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Subscribers List
            // Subscribers List
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscribers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,fontFamily: 'Poppins')),
                    SizedBox(height: 10),
                    if (isLoadingSubscribers)
                      Center(child: CircularProgressIndicator())
                    else if (fetchErrorSubscribers.isNotEmpty)
                      Text(fetchErrorSubscribers, style: TextStyle(color: Colors.red))
                    else if (subscribers.isEmpty)
                        Text("No subscribers found.",style: TextStyle(fontFamily: 'Poppins'),)
                      else
                        ...subscribers.map((sub) {
                          return ListTile(
                            title: Text(sub.username),
                            subtitle: Text(sub.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.block,
                                    color: sub.banned == 1 ? Colors.red : Colors.orange, // red if banned, orange if not
                                  ),
                                  tooltip: sub.banned == 1 ? "Unban" : "Ban",
                                  onPressed: () => toggleBanSubscriber(sub.id, sub.banned),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Delete",
                                  onPressed: () => deleteSubscriber(sub.id),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ],
                ),
              ),
            ),

            // Comments List
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Comments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,fontFamily: 'Poppins')),
                    SizedBox(height: 10),
                    ...comments.map((com) {
                      return ListTile(
                        title: Text(com.username),
                        subtitle: Text(com.comment),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteComment(com.id),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            // Notification input
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Send Push Notification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.black87,fontFamily: 'Poppins')),
                    SizedBox(height: 10),
                    TextField(
                      controller: _notificationController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your message here',
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Send to All',style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
                    ),



                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>
                              GeneralVotingScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('vote',style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
                    ),
                    Divider(),
                    // ElevatedButton(
                    //   onPressed: () =>
                    //       Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    //           AdminNewsEventScreen())),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.orange,
                    //     minimumSize: Size(double.infinity, 50),
                    //   ),
                    //   child: Text('Add News',style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
                    // ),
                    // Divider(),
                    // ElevatedButton(
                    //   onPressed: () =>
                    //       Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    //           AdminEventScreen())),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.orange,
                    //     minimumSize: Size(double.infinity, 50),
                    //   ),
                    //   child: Text('Add Event',style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
                    // ),
                    // Divider(),
                    // ElevatedButton(
                    //   onPressed: () =>
                    //       Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    //           AdminGalleryUploadScreen())),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.orange,
                    //     minimumSize: Size(double.infinity, 50),
                    //   ),
                    //   child: Text('Add To Galery',style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
                    // ),

                  ],
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}