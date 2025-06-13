import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ویجت نمایش ویدیو در پس‌زمینه نمای تک‌صفحه
class SingleViewBackgroundVideo extends StatefulWidget {
  const SingleViewBackgroundVideo({super.key});

  @override
  State<SingleViewBackgroundVideo> createState() =>
      _SingleViewBackgroundVideoState();
}

class _SingleViewBackgroundVideoState extends State<SingleViewBackgroundVideo> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/video.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.setVolume(0.0);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return AnimatedOpacity(
        duration: const Duration(seconds: 2),
        opacity: _isInitialized ? 1.0 : 0.0,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
      ),
    );
  }
}
