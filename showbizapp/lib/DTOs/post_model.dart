import 'package:hive/hive.dart';

part 'post_model.g.dart'; // Needed for code generation

@HiveType(typeId: 0)
class PostModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String imageUrl;

  @HiveField(3)
  String date;

  @HiveField(4)
  String content;

  @HiveField(5)
  String youtubeLink;

  PostModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.content,
    required this.youtubeLink,
  });
}
