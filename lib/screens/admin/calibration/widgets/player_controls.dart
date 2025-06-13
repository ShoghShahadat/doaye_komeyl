import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';

class PlayerControls extends StatelessWidget {
  final CalibrationProvider provider;
  const PlayerControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: provider.audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: provider.audioPlayer.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;
                  return Column(
                    children: [
                      Row(
                        children: [
                          _buildTimeDisplay(position),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PlayerSlider(
                              value: position.inMilliseconds.toDouble(),
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                provider.audioPlayer.seek(
                                  Duration(milliseconds: value.round()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildTimeDisplay(duration),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPlaybackControls(provider),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$minutes:$seconds.$milliseconds',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(CalibrationProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10_rounded),
          onPressed: () {
            final newPosition =
                provider.audioPlayer.position - const Duration(seconds: 10);
            provider.audioPlayer.seek(newPosition);
          },
        ),
        const SizedBox(width: 8),
        StreamBuilder<bool>(
          stream: provider.audioPlayer.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return Material(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  if (isPlaying) {
                    provider.audioPlayer.pause();
                  } else {
                    provider.audioPlayer.play();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.forward_10_rounded),
          onPressed: () {
            final newPosition =
                provider.audioPlayer.position + const Duration(seconds: 10);
            provider.audioPlayer.seek(newPosition);
          },
        ),
      ],
    );
  }
}

class _PlayerSlider extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  const _PlayerSlider({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFF6C63FF),
        inactiveTrackColor: const Color(0xFFE0E0E0),
        trackHeight: 6,
        thumbColor: const Color(0xFF6C63FF),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Slider(
        value: value.clamp(0.0, max > 0 ? max : 1.0),
        max: max > 0 ? max : 1.0,
        onChanged: onChanged,
      ),
    );
  }
}
