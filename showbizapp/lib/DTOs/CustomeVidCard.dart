import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart'; // Import youtube_player_iframe package
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/CommentSection.dart';
import 'Comment.dart';

class CustomVideoCard extends StatefulWidget {
  final String videoUrl;
  final String text;
  final String extraText;
  final String downloadUrl;

  const CustomVideoCard({
    required this.videoUrl,
    required this.text,
    required this.extraText,
    required this.downloadUrl,
    Key? key,
  }) : super(key: key);

  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomVideoCard> {
  late YoutubePlayerController _controller;

  int likes = 0;
  bool isLiked = false;
  int commentCount = 0;
  List<Comment> comments = [];
  bool isTextExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '',
      params: const YoutubePlayerParams(
        showControls: true, // Show playback controls
        showFullscreenButton: true, // Show the fullscreen button
        mute: false, // Start unmuted
        loop: false, // Do not loop the video
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.25,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Html(
                  data: widget.text,
                  style: {
                    'p': Style(
                      fontSize: FontSize(16),
                      fontWeight: FontWeight.w400,
                      fontFamily: "Poppins",
                    ),
                  },
                ),
                if (isTextExpanded)
                  Html(
                    data: widget.extraText,
                    style: {
                      'p': Style(
                        fontSize: FontSize(16),
                        fontWeight: FontWeight.w400,
                        fontFamily: "Poppins",
                      ),
                    },
                  ),
                Center(
                  child: isTextExpanded
                      ? TextButton(
                    onPressed: () async {
                      if (await canLaunch(widget.downloadUrl)) {
                        await launch(widget.downloadUrl);
                      } else {
                        throw 'Could not launch ${widget.downloadUrl}';
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Download",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  )
                      : const SizedBox(),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isTextExpanded = !isTextExpanded;
                    });
                  },
                  child: Center(
                    child: Text(
                      isTextExpanded ? "View Less" : "View More",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          isLiked = !isLiked;
                          likes += isLiked ? 1 : -1;
                        });
                      },
                    ),
                    Text('$likes'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.orange),
                      onPressed: () {
                        _showCommentSection(context);
                      },
                    ),
                    Text('$commentCount'),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.orange),
                  onPressed: () {
                    _showShareOptions(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentSection(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentSection(comments: comments),
    );

    if (result != null && result > 0) {
      setState(() {
        commentCount = result;
      });
    }
  }

  void _showShareOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Share"),
          content: const Text("Share this content with your friends!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
