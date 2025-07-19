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

import '../DTOs/Reply.dart';

class CommentApi {
  Future<Map<String, dynamic>> getSubscriber() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberString = prefs.getString('subscriber');
    if (subscriberString != null) {
      return jsonDecode(subscriberString);
    }
    return {};
  }

  Future<Map<String, dynamic>> postComment(String text, String subscriberId, String postId, {int? parentId}) async {
    final response = await http.post(
      Uri.parse('https://api.237showbiz.com/api/comments/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'subscriber_id': subscriberId,
        'post_id': postId,
        if (parentId != null) 'parent_id': parentId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post comment: ${response.statusCode}');
    }
  }
  Future<bool> replyToComment(String commentId, String subscriberId, String postId, String text) async {
    final url = Uri.parse(
        'https://api.237showbiz.com/api/comment_interaction/?comment_id=$commentId&subscriber_id=$subscriberId&post_id=$postId');

    final payload = jsonEncode({
      'action': 'reply',
      'text': text,
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
        return data['success'] == 1;
      } else {
        print('Failed to reply: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error replying to comment: $e');
    }
    return false;
  }

  Future<bool> editComment(String commentId, String subscriberId, String newText) async {
    final uri = Uri.parse(
      'https://api.237showbiz.com/api/comments/?comment_id=$commentId&subscriber_id=$subscriberId',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> bodyData = {
      'action': 'edit',
      'text': newText,
    };

    final String jsonBody = json.encode(bodyData);

    print('--- DEBUGGING editComment() ---');
    print('URL: ${uri.toString()}');
    print('Headers: $headers');
    print('Request Body: $jsonBody');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Edit comment exception: $e');
      return false;
    }
  }





  Future<List<dynamic>> fetchCommentsForPost(String postId) async {
    final Uri commentsUrl = Uri.parse("https://api.237showbiz.com/api/comments/");

    try {
      final response = await http.get(commentsUrl);

      List<dynamic> comments = [];

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse is List) {
          // Filter comments by postId
          comments = decodedResponse.where((comment) {
            final commentPostId = comment['post_id']?.toString().trim();
            return commentPostId == postId;
          }).toList();
        } else {
          print('Unexpected response format from comments endpoint');
        }
      } else {
        print('Failed to load comments. Status code: ${response.statusCode}');
      }

      return comments;
    } catch (e) {
      print('Error fetching comments for post: $e');
      return [];
    }
  }

  Future<bool> deleteComment(String commentId, String subscriberId,String postId) async {
    final url = Uri.parse(
        'https://api.237showbiz.com/api/comment_interaction/?comment_id=$commentId&subscriber_id=$subscriberId'
    );
    print('Sending delete request to $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'action': 'delete'}),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Delete API success field: ${data['success']}');
      await fetchCommentsForPost(postId); // make sure this works
      return data['success'] == 1;
    }
    return false;
  }


}