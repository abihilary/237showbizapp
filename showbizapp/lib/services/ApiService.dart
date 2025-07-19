import 'dart:convert';
import 'package:http/http.dart' as http;
import 'VideoPost.dart';

Future<List<VideoPost>> fetchVideoPosts() async {
  final response = await http.get(Uri.parse('https://237showbiz.com/wp-json/wp/v2/posts'));

  if (response.statusCode == 200) {
    List<dynamic> body = jsonDecode(response.body);
    return body.map((json) => VideoPost.fromJson(json)).toList(); // Convert JSON to VideoPost list
  } else {
    throw Exception('Failed to load video posts');
  }
}
