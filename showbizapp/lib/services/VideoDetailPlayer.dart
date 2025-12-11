// NEW WIDGET FOR YOUTUBE PLAYER LIFECYCLE MANAGEMENT
import 'package:flutter/cupertino.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoDetailPlayer extends StatefulWidget {
  final String videoId;

  const VideoDetailPlayer({Key? key, required this.videoId}) : super(key: key);

  @override
  _VideoDetailPlayerState createState() => _VideoDetailPlayerState();
}

class _VideoDetailPlayerState extends State<VideoDetailPlayer> {
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.close(); // Use .close() for safe disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _youtubeController,
      aspectRatio: 16 / 9,
    );
  }
}