import 'package:flutter/material.dart';

class GalleryPage extends StatelessWidget {
  GalleryPage({Key? key}) : super(key: key);

  final List<Map<String, String>> sampleArtists = [
    {
      "image": "https://picsum.photos/200/200?random=11",
      "name": "Artist One",
      "bio": "A passionate music creator from NYC."
    },
    {
      "image": "https://picsum.photos/200/200?random=12",
      "name": "Artist Two",
      "bio": "Known for soulful melodies and beats."
    },
    {
      "image": "https://picsum.photos/200/200?random=13",
      "name": "Artist Three",
      "bio": "Hip-hop artist with a story to tell."
    },
    {
      "image": "https://picsum.photos/200/200?random=14",
      "name": "Artist Four",
      "bio": "Experimental sounds and fresh vibes."
    },
    {
      "image": "https://picsum.photos/200/200?random=15",
      "name": "Artist Five",
      "bio": "A rising star in the indie scene."
    },
    {
      "image": "https://picsum.photos/200/200?random=16",
      "name": "Artist Six",
      "bio": "Bringing jazz fusion to the mainstream."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Artist"),backgroundColor: Colors.orange,),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 per row to fit image + text better
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75, // to give space for name + bio
        ),
        itemCount: sampleArtists.length,
        itemBuilder: (context, index) {
          final artist = sampleArtists[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    artist['image']!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    artist['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    artist['bio']!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
