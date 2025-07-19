import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ArtistVote {
  final String name;
  final String imageUrl;
  final int votes;

  ArtistVote({required this.name, required this.imageUrl, required this.votes});

  // Factory method to create an ArtistVote from JSON
  factory ArtistVote.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['image_path'] ?? '';
    String fullUrl = rawUrl.startsWith('http')?rawUrl :'https://api.237showbiz.com/api/$rawUrl';
    return ArtistVote(
      name: json['name'] ?? '',
      imageUrl: fullUrl,
      votes: json['votes'] ?? 0,
    );
  }
}

class VoteResultScreen extends StatefulWidget {
  const VoteResultScreen({Key? key}) : super(key: key);

  @override
  _VoteResultScreenState createState() => _VoteResultScreenState();
}

class _VoteResultScreenState extends State<VoteResultScreen> {
  late Future<List<ArtistVote>> _futureArtists;

  @override
  void initState() {
    super.initState();
    _futureArtists = fetchArtists();
  }

  Future<List<ArtistVote>> fetchArtists() async {
    final response = await http.post(
      Uri.parse("https://api.237showbiz.com/api/artist/"),

      body: {
        'action': 'fetch',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print(data);

      // Map each JSON item to ArtistVote model
      return data.map((artistJson) => ArtistVote.fromJson(artistJson)).toList();
    } else {
      throw Exception('Failed to load artists');
    }
  }

  Widget buildVoteCard(ArtistVote artist) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artist.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text("${artist.votes} votes", style: const TextStyle(fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: FutureBuilder<List<ArtistVote>>(
        future: _futureArtists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading spinner while fetching
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show error message if fetch failed
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // No data found
            return const Center(child: Text('No artists found.'));
          }

          final artists = snapshot.data!;
          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) => buildVoteCard(artists[index]),
          );
        },
      ),
    );
  }
}
