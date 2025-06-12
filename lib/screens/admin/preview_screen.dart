import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PreviewScreen extends StatefulWidget {
  final CalibrationProject project;
  final Map<String, int> timestamps;
  final List<List<String>> linesOfWords;
  final int? initialSeekMilliseconds; // نقطه شروع پخش (اختیاری)

  const PreviewScreen({
    super.key,
    required this.project,
    required this.timestamps,
    required this.linesOfWords,
    this.initialSeekMilliseconds,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ItemScrollController _itemScrollController = ItemScrollController();
  int _currentWordLine = -1;
  int _currentWordIndex = -1;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setFilePath(widget.project.audioPath);
      // اگر نقطه شروعی ارسال شده بود، به آنجا منتقل شو
      if (widget.initialSeekMilliseconds != null) {
        await _audioPlayer
            .seek(Duration(milliseconds: widget.initialSeekMilliseconds!));
      }
      _audioPlayer.positionStream.listen(_updateHighlighting);
    } catch (e) {
      print("Error setting audio source in preview: $e");
    }
  }

  void _updateHighlighting(Duration position) {
    final ms = position.inMilliseconds;
    String? foundKey;

    widget.timestamps.forEach((key, value) {
      if (value <= ms) {
        if (foundKey == null || value > widget.timestamps[foundKey]!) {
          foundKey = key;
        }
      }
    });

    if (foundKey != null) {
      final parts = foundKey!.split('-').map(int.parse).toList();
      if (parts[0] != _currentWordLine) {
        // اسکرول خودکار به خط جدید
        if (_itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: parts[0],
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            alignment: 0.4,
          );
        }
      }
      if (parts[0] != _currentWordLine || parts[1] != _currentWordIndex) {
        setState(() {
          _currentWordLine = parts[0];
          _currentWordIndex = parts[1];
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('پیش‌نمایش: ${widget.project.title}'),
        backgroundColor: Colors.indigo,
      ),
      // استفاده از Column برای قرار دادن لیست و پنل کنترلر
      body: Column(
        children: [
          Expanded(
            // استفاده از لیست با قابلیت اسکرول به آیتم
            child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              padding: const EdgeInsets.all(12.0),
              itemCount: widget.linesOfWords.length,
              itemBuilder: (context, lineIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: _buildLineSpans(lineIndex),
                    ),
                  ),
                );
              },
            ),
          ),
          // پنل کنترلر جدید در پایین صفحه
          _PlayerControlsPreview(audioPlayer: _audioPlayer),
        ],
      ),
    );
  }

  List<TextSpan> _buildLineSpans(int lineIndex) {
    List<TextSpan> spans = [];
    for (int wordIndex = 0;
        wordIndex < widget.linesOfWords[lineIndex].length;
        wordIndex++) {
      final key = '$lineIndex-$wordIndex';
      final bool isTimestamped = widget.timestamps.containsKey(key);
      final bool isPast = lineIndex < _currentWordLine ||
          (lineIndex == _currentWordLine && wordIndex < _currentWordIndex);
      final bool isCurrent =
          lineIndex == _currentWordLine && wordIndex == _currentWordIndex;
      final word = widget.linesOfWords[lineIndex][wordIndex];

      Color color;
      if (isCurrent) {
        color = Colors.amber.shade700;
      } else if (isPast && isTimestamped) {
        color = Colors.indigo.shade800;
      } else {
        color = Colors.grey.shade700;
      }

      spans.add(
        TextSpan(
          text: '$word ',
          style: TextStyle(
            fontFamily: 'Alhura',
            fontSize: 28,
            color: color,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return spans;
  }
}

// ویجت جدید برای کنترلرهای پخش در صفحه پیش‌نمایش
class _PlayerControlsPreview extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const _PlayerControlsPreview({required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration d) {
      if (d.inHours > 0) return d.toString().split('.').first.padLeft(8, "0");
      return d.toString().split('.').first.padLeft(8, "0").substring(3);
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.indigo.withOpacity(0.1),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return Row(
                children: [
                  Text(formatDuration(position)),
                  Expanded(
                    child: StreamBuilder<Duration?>(
                        stream: audioPlayer.durationStream,
                        builder: (context, snapshot) {
                          final duration = snapshot.data ?? Duration.zero;
                          return Slider(
                            value: position.inMilliseconds
                                .toDouble()
                                .clamp(0.0, duration.inMilliseconds.toDouble()),
                            max: duration.inMilliseconds.toDouble() > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                            onChanged: (value) {
                              audioPlayer
                                  .seek(Duration(milliseconds: value.round()));
                            },
                            activeColor: Colors.indigo,
                          );
                        }),
                  ),
                  StreamBuilder<Duration?>(
                      stream: audioPlayer.durationStream,
                      builder: (context, snapshot) =>
                          Text(formatDuration(snapshot.data ?? Duration.zero))),
                ],
              );
            },
          ),
          StreamBuilder<bool>(
            stream: audioPlayer.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 50,
                color: Colors.indigo,
                onPressed: () {
                  isPlaying ? audioPlayer.pause() : audioPlayer.play();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
