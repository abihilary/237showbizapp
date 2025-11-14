import 'package:hive/hive.dart';
import 'package:html_unescape/html_unescape.dart';

part 'post_model.g.dart';

@HiveType(typeId: 0)
class PostModel {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final String? date;

  @HiveField(3)
  final String? content;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String? youtubeLink;

  PostModel({
    this.id,
    this.title,
    this.date,
    this.content,
    this.imageUrl,
    this.youtubeLink,
  });

  factory PostModel.fromApiJson(Map<String, dynamic> json) {
    final htmlContent = json['content']['rendered'] as String? ?? '';
    return PostModel(
      id: json['id'] as int?,
      title: HtmlUnescape().convert(json['title']['rendered'] as String? ?? ''),
      date: json['date'] as String?,
      content: htmlContent,
      imageUrl: _extractImageUrl(json),
      youtubeLink: _extractYoutubeLink(htmlContent),
    );
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    if (json['_embedded'] != null && json['_embedded']['wp:featuredmedia'] != null) {
      final media = json['_embedded']['wp:featuredmedia'][0];
      return media['source_url'] as String?;
    }
    return null;
  }

  static String? _extractYoutubeLink(String htmlContent) {
    // A more robust regex to find the video ID in various YouTube embed URL formats
    final RegExp regExp = RegExp(
      r'src="https?:\/\/(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)(?:\?.*)?"',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(htmlContent);

    if (match != null && match.groupCount >= 1) {
      final videoId = match.group(1);
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    return null;
  }
}