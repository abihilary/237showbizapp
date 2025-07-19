class VideoPost {
  final String videoUrl;
  final String text;
  final String extraText;
  final String downloadUrl;


  VideoPost({
    required this.videoUrl,
    required this.text,
    required this.extraText,
    required this.downloadUrl,
  });

  factory VideoPost.fromJson(Map<String, dynamic> json) {
    final content = json['content']['rendered'] as String;
    final videoIdMatch = RegExp(r'youtube.com/embed/([^?]+)').firstMatch(content);
    final videoUrl = videoIdMatch != null ? 'https://www.youtube.com/watch?v=${videoIdMatch.group(1)}' : '';

    final downloadMatch = RegExp(r'href="([^"]+)"').firstMatch(content);
    final downloadUrl = downloadMatch != null ? downloadMatch.group(1) ?? '' : '';

    return VideoPost(
      videoUrl: videoUrl,
      text: json['title']['rendered'] as String,
      extraText: json['content']['rendered'] as String,
      downloadUrl: downloadUrl,
    );
  }
}
