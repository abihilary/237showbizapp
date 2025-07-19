import 'Reply.dart';

class Comment {
  final String name;
  final String text;
  final DateTime timestamp;
  List<Reply>? replies;

  Comment({
    required this.name,
    required this.text,
    required this.timestamp,
  });
}
