import 'package:flutter/material.dart';
import 'package:showbizapp/pages/swipper.dart';
import 'package:showbizapp/services/onScrol.dart';
import '../DTOs/CustomeVidCard.dart';
import '../components/buttomnav.dart';
import '../services/ApiService.dart';
import '../services/VideoPost.dart';


class MusicVideo extends StatefulWidget {
  @override
  _MusicVideoState createState() => _MusicVideoState();
}

class _MusicVideoState extends State<MusicVideo> {
  late Future<List<VideoPost>> futureVideoPosts;
  late String dates;
  bool isDarkmode = true;

  @override
  void initState() {
    super.initState();
    futureVideoPosts = fetchVideoPosts();


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Music Videos",
          style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          const swipper(),
          Expanded(
            child: FutureBuilder<List<VideoPost>>(
              future: futureVideoPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No videos available'));
                }

                final videoData = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(0.0),
                  itemCount: videoData.length,
                  itemBuilder: (context, index) {
                    final video = videoData[index];
                    return CustomVideoCard(
                      videoUrl: video.videoUrl,
                      text: video.text,
                      extraText: video.extraText,
                      downloadUrl: video.downloadUrl,


                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,

        onPressed: () {
          // Scroll to the top of the list
          scrollToTop();
        },
        child: Icon(Icons.arrow_upward,color: Colors.white,),
      ),
    );
  }
}
