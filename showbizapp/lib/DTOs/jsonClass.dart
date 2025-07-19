class jArtist {
  String? id; // ← Changed from int? to String
  String name;
  String imageUrl;
  int votes;

  jArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.votes = 0,
  });

  factory jArtist.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['name'] == null) {
      throw Exception("Missing required field in artist data: $json");
    }

    String rawUrl = json['image_path'] ?? '';
    String fullUrl = rawUrl.startsWith('http')
        ? rawUrl
        : 'https://api.237showbiz.com/api/$rawUrl';

    return jArtist(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: fullUrl,
      votes: json['votes'] ?? 0,
    );
  }
  @override
  String toString() {
    return 'jArtist(id: $id, name: $name, votes: $votes, imageUrl: $imageUrl)';
  }

}
