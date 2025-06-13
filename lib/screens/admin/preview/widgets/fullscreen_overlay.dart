import 'package:flutter/material.dart';

/// ویجت پوششی برای حالت نمایش تمام‌صفحه
class FullscreenOverlay extends StatelessWidget {
  final List<String> words;
  final int currentWordIndex;
  final bool isPlaying;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final Function(int) onSeek;

  const FullscreenOverlay({
    super.key,
    required this.words,
    required this.currentWordIndex,
    required this.isPlaying,
    required this.onClose,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 20,
                  textDirection: TextDirection.rtl,
                  alignment: WrapAlignment.center,
                  children: _buildFullscreenWords(),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_fullscreen_rounded),
                color: Colors.white,
                iconSize: 32,
                onPressed: onClose,
              ),
            ),
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: _buildFullscreenControls(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFullscreenWords() {
    return List.generate(words.length, (index) {
      final isCurrent = index == currentWordIndex;
      final isPast = index < currentWordIndex;

      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontFamily: 'Alhura',
          fontSize: isCurrent ? 48 : 40,
          color: isCurrent
              ? Colors.amber
              : isPast
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
        child: Text(words[index]),
      );
    });
  }

  Widget _buildFullscreenControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10_rounded),
          color: Colors.white,
          iconSize: 32,
          onPressed: () => onSeek(-10),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle : Icons.play_circle,
          ),
          color: Colors.white,
          iconSize: 64,
          onPressed: onPlayPause,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_10_rounded),
          color: Colors.white,
          iconSize: 32,
          onPressed: () => onSeek(10),
        ),
      ],
    );
  }
}
