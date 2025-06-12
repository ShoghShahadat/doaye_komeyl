import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:komeyl_app/screens/admin/preview_screen.dart';
import 'package:provider/provider.dart';

class CalibrationScreen extends StatelessWidget {
  final CalibrationProject project;

  const CalibrationScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalibrationProvider(project: project),
      child: Consumer<CalibrationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('کالیبره کردن: ${project.title}'),
              backgroundColor: Colors.deepOrange,
              actions: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: provider.canUndo ? provider.undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                  onPressed: provider.canRedo ? provider.redo : null,
                ),
                IconButton(
                  icon: Icon(
                    provider.isRangeSelectionMode
                        ? Icons.cancel
                        : Icons.select_all,
                    color: provider.isRangeSelectionMode
                        ? Colors.yellow
                        : Colors.white,
                  ),
                  tooltip: 'انتخاب گروهی',
                  onPressed: provider.toggleRangeSelectionMode,
                ),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'پیش‌نمایش',
                  onPressed: () {
                    provider.audioPlayer.pause();

                    int? startTime;
                    // اگر کلمه‌ای انتخاب شده بود، زمان آن را به عنوان نقطه شروع در نظر بگیر
                    if (provider.selectedWordKey != null &&
                        provider.timestamps
                            .containsKey(provider.selectedWordKey)) {
                      startTime = provider.timestamps[provider.selectedWordKey];
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PreviewScreen(
                          project: provider.project,
                          timestamps: provider.timestamps,
                          linesOfWords: provider.linesOfWords,
                          initialSeekMilliseconds: startTime, // ارسال زمان شروع
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    final jsonOutput = provider.exportTimestampsToJson();
                    _showExportDialog(context, jsonOutput);
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _PlayerControls(provider: provider),
                  const Divider(thickness: 2),
                  Expanded(
                    child: _TextDisplay(provider: provider),
                  ),
                  if (provider.isRangeSelectionMode)
                    _RangeSelectionControls(provider: provider)
                  else if (provider.selectedWordKey != null)
                    _FineTuneControls(provider: provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context, String jsonOutput) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('فایل خروجی JSON'),
          content: Scrollbar(
            child: SingleChildScrollView(
              child: Text(jsonOutput,
                  style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('کپی در کلیپ‌بورد'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonOutput));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('متن JSON کپی شد!')),
                );
              },
            ),
            TextButton(
              child: const Text('بستن'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

// --- ویجت پنل تنظیم دقیق با رفع باگ و دکمه جدید ---
class _FineTuneControls extends StatelessWidget {
  final CalibrationProvider provider;
  const _FineTuneControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final key = provider.selectedWordKey;
    final timestamp = (key != null && provider.timestamps.containsKey(key))
        ? provider.timestamps[key]
        : 0;

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.deepOrange.shade100,
      child: Column(
        children: [
          Text('تنظیم دقیق کلمه انتخاب شده: $timestamp ms'),
          // ١. برای حل مشکل Overflow، ردیف دکمه‌ها را در یک ویجت اسکرول افقی قرار می‌دهیم
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNudgeButton(provider, '-100ms', -100),
                const SizedBox(width: 4),
                _buildNudgeButton(provider, '-10ms', -10),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.red),
                  tooltip: 'حذف زمان‌بندی این کلمه',
                  onPressed: () {
                    provider.deleteSelectedTimestamp();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline,
                      color: Colors.deepOrange),
                  tooltip: 'پخش از این نقطه',
                  onPressed: () => provider.playFromSelected(),
                ),
                // ٢. دکمه مکث جدید برای راحتی کاربر اضافه شد
                IconButton(
                  icon: const Icon(Icons.pause_circle_outline,
                      color: Colors.deepOrange),
                  tooltip: 'توقف',
                  onPressed: () => provider.audioPlayer.pause(),
                ),
                const SizedBox(width: 8),
                _buildNudgeButton(provider, '+10ms', 10),
                const SizedBox(width: 4),
                _buildNudgeButton(provider, '+100ms', 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeButton(
      CalibrationProvider provider, String label, int amount) {
    return ElevatedButton(
      child: Text(label),
      onPressed: () => provider.nudgeTimestamp(amount),
    );
  }
}

// --- سایر ویجت‌ها بدون تغییر باقی می‌مانند ---

class _RangeSelectionControls extends StatelessWidget {
  final CalibrationProvider provider;
  const _RangeSelectionControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Expanded(
              child: Text(
            'یک کلمه برای شروع و یک کلمه برای پایان محدوده انتخاب کنید.',
            textAlign: TextAlign.center,
          )),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep),
            label: const Text('حذف محدوده'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed:
                (provider.rangeStartKey != null && provider.rangeEndKey != null)
                    ? () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تایید حذف'),
                            content: const Text(
                                'آیا از حذف زمان‌بندی کلمات انتخاب شده اطمینان دارید؟ این عمل قابل بازگشت (Undo) است.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('لغو')),
                              TextButton(
                                child: const Text('بله، حذف کن'),
                                onPressed: () {
                                  provider.deleteTimestampsInRange();
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final CalibrationProvider provider;
  const _PlayerControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<Duration>(
        stream: provider.audioPlayer.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          return Row(
            children: [
              StreamBuilder<bool>(
                  stream: provider.audioPlayer.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () {
                        isPlaying
                            ? provider.audioPlayer.pause()
                            : provider.audioPlayer.play();
                      },
                    );
                  }),
              Text(
                '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}.${(position.inMilliseconds % 1000).toString().padLeft(3, '0')}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
              Expanded(
                child: StreamBuilder<Duration?>(
                    stream: provider.audioPlayer.durationStream,
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
                          provider.audioPlayer
                              .seek(Duration(milliseconds: value.round()));
                        },
                      );
                    }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TextDisplay extends StatelessWidget {
  final CalibrationProvider provider;
  const _TextDisplay({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.linesOfWords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: provider.linesOfWords.length,
      itemBuilder: (context, lineIndex) {
        final words = provider.linesOfWords[lineIndex];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            textDirection: TextDirection.rtl,
            children: List.generate(words.length, (wordIndex) {
              return _CalibratableWord(
                provider: provider,
                lineIndex: lineIndex,
                wordIndex: wordIndex,
              );
            }),
          ),
        );
      },
    );
  }
}

class _CalibratableWord extends StatelessWidget {
  final CalibrationProvider provider;
  final int lineIndex;
  final int wordIndex;

  const _CalibratableWord({
    required this.provider,
    required this.lineIndex,
    required this.wordIndex,
  });

  @override
  Widget build(BuildContext context) {
    final key = '$lineIndex-$wordIndex';
    final bool isTimestamped = provider.timestamps.containsKey(key);
    final bool isSelected = provider.selectedWordKey == key;
    final bool isRangeStart = provider.rangeStartKey == key;
    final bool isRangeEnd = provider.rangeEndKey == key;

    bool isInRange = false;
    if (provider.isRangeSelectionMode &&
        provider.rangeStartKey != null &&
        provider.rangeEndKey != null) {
      final startParts =
          provider.rangeStartKey!.split('-').map(int.parse).toList();
      final endParts = provider.rangeEndKey!.split('-').map(int.parse).toList();
      final currentKeyParts = key.split('-').map(int.parse).toList();

      bool isAfterStart = currentKeyParts[0] > startParts[0] ||
          (currentKeyParts[0] == startParts[0] &&
              currentKeyParts[1] >= startParts[1]);
      bool isBeforeEnd = currentKeyParts[0] < endParts[0] ||
          (currentKeyParts[0] == endParts[0] &&
              currentKeyParts[1] <= endParts[1]);

      isInRange = isAfterStart && isBeforeEnd;
    }

    final word = provider.linesOfWords[lineIndex][wordIndex];

    return InkWell(
      onTap: () {
        if (provider.isRangeSelectionMode) {
          provider.setRangeMarker(lineIndex, wordIndex);
        } else {
          if (!isTimestamped) {
            provider.assignTimestamp(lineIndex, wordIndex);
          }
          provider.selectWord(lineIndex, wordIndex);
        }
      },
      child: Chip(
        label: Text(word,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: isRangeStart || isRangeEnd
            ? Colors.blue.shade700
            : isInRange
                ? Colors.blue.shade300
                : isTimestamped
                    ? Colors.green
                    : Colors.grey.shade600,
        shape: isSelected
            ? StadiumBorder(
                side: BorderSide(color: Colors.deepOrange.shade700, width: 2.0))
            : const StadiumBorder(),
      ),
    );
  }
}
