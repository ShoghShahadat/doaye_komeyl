import 'package:flutter/material.dart';

/// ویجت موج صوتی کوچک برای نمایش در کارت آیه فعلی
class MiniWaveform extends StatefulWidget {
  final bool isPlaying;
  const MiniWaveform({super.key, required this.isPlaying});

  @override
  State<MiniWaveform> createState() => _MiniWaveformState();
}

class _MiniWaveformState extends State<MiniWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final List<double> _waveHeights = List.generate(5, (index) => 0.3);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    if (widget.isPlaying) {
      _waveController.repeat();
    }

    _waveController.addListener(() {
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.3 +
              0.7 *
                  (0.5 +
                      0.5 *
                          (i.isEven
                              ? _waveController.value
                              : 1 - _waveController.value));
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant MiniWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!widget.isPlaying && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 3,
            height: widget.isPlaying ? 20 * _waveHeights[index] : 4,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
