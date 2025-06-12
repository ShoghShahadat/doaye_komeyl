import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:komeyl_app/screens/admin/preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _PlayerControls(provider: provider),
                  _EditingToolbar(provider: provider),
                  const Divider(thickness: 2, height: 2),
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
}

// --- ویجت جدید: نوار ابزار ویرایش ---
class _EditingToolbar extends StatelessWidget {
  final CalibrationProvider provider;
  const _EditingToolbar({required this.provider});

  void _showCollaborationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('همکاری و اشتراک‌گذاری'),
        content: const Text('یکی از گزینه‌های زیر را انتخاب کنید:'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('ورود فایل کالیبره (.json)'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['json']);
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final jsonContent = await file.readAsString();
                await provider.importAndMergeFromJson(jsonContent);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فایل با موفقیت ادغام شد!')),
                  );
                }
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.share_outlined),
            label: const Text('اشتراک‌گذاری کالیبره من'),
            onPressed: () {
              Navigator.of(ctx).pop();
              final jsonToShare = provider.exportTimestampsToJson();
              Share.share(jsonToShare,
                  subject: 'فایل کالیبراسیون برای ${provider.project.title}');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportPackage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('در حال ساخت بسته پروژه...')),
    );
    final Uint8List? zipData = await provider.packageProjectAsZip();
    if (zipData != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await FileSaver.instance.saveFile(
        name:
            '${provider.project.title}_${DateTime.now().millisecondsSinceEpoch}',
        bytes: zipData,
        ext: 'zip',
        mimeType: MimeType.zip,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پروژه با موفقیت ذخیره شد!')),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ساخت بسته!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.grey.shade200,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        children: [
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
          const VerticalDivider(),
          IconButton(
            icon: Icon(
              provider.isRangeSelectionMode
                  ? Icons.cancel_outlined
                  : Icons.select_all,
              color: provider.isRangeSelectionMode
                  ? Colors.blue.shade700
                  : Theme.of(context).iconTheme.color,
            ),
            tooltip: 'انتخاب گروهی',
            onPressed: provider.toggleRangeSelectionMode,
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'پیش‌نمایش',
            onPressed: () {
              provider.audioPlayer.pause();
              int? startTime;
              if (provider.selectedWordKey != null &&
                  provider.timestamps.containsKey(provider.selectedWordKey)) {
                startTime = provider.timestamps[provider.selectedWordKey];
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PreviewScreen(
                    project: provider.project,
                    timestamps: provider.timestamps,
                    linesOfWords: provider.linesOfWords,
                    initialSeekMilliseconds: startTime,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_work_outlined, color: Colors.purple),
            tooltip: 'ورود و اشتراک‌گذاری',
            onPressed: () => _showCollaborationDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.green),
            tooltip: 'بسته‌بندی و خروجی گرفتن',
            onPressed: () => _exportPackage(context),
          ),
        ],
      ),
    );
  }
}

// --- سایر ویجت‌های این صفحه ---

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    child: const Text('-100ms'),
                    onPressed: () => provider.nudgeTimestamp(-100)),
                const SizedBox(width: 4),
                ElevatedButton(
                    child: const Text('-10ms'),
                    onPressed: () => provider.nudgeTimestamp(-10)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.red),
                  tooltip: 'حذف زمان‌بندی این کلمه',
                  onPressed: provider.deleteSelectedTimestamp,
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline,
                      color: Colors.deepOrange),
                  tooltip: 'پخش از این نقطه',
                  onPressed: provider.playFromSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.pause_circle_outline,
                      color: Colors.deepOrange),
                  tooltip: 'توقف',
                  onPressed: () => provider.audioPlayer.pause(),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                    child: const Text('+10ms'),
                    onPressed: () => provider.nudgeTimestamp(10)),
                const SizedBox(width: 4),
                ElevatedButton(
                    child: const Text('+100ms'),
                    onPressed: () => provider.nudgeTimestamp(100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
