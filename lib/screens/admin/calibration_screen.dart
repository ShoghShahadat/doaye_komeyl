import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/calibration_choice_model.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:komeyl_app/screens/admin/preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class CalibrationScreen extends StatelessWidget {
  final CalibrationProject project;
  const CalibrationScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalibrationProvider(project: project),
      child: Consumer<CalibrationProvider>(
        builder: (context, provider, child) {
          Widget bottomPanel;
          final selectedKey = provider.selectedWordKey;
          // ١. تشخیص اینکه آیا کلمه انتخاب شده دارای تداخل است یا نه
          bool hasConflict = selectedKey != null &&
              provider.timestamps.containsKey(selectedKey) &&
              provider.timestamps[selectedKey]!.length > 1;

          // ٢. نمایش پنل مناسب بر اساس وضعیت برنامه
          if (hasConflict) {
            bottomPanel = _ConflictResolutionPanel(provider: provider);
          } else if (provider.isRangeSelectionMode) {
            bottomPanel = _RangeSelectionControls(provider: provider);
          } else if (selectedKey != null) {
            bottomPanel = _FineTuneControls(provider: provider);
          } else {
            bottomPanel =
                const SizedBox.shrink(); // در غیر این صورت هیچ پنلی نمایش نده
          }

          return Scaffold(
            drawer: _CalibrationDrawer(provider: provider),
            appBar: AppBar(
              title: Text('کالیبره کردن: ${project.title}'),
              backgroundColor: Colors.deepOrange,
              actions: [
                _AppBarActions(provider: provider),
              ],
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
                  // ٣. استفاده از انیمیشن برای نمایش نرم پنل‌ها
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: bottomPanel,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- ویجت‌های این صفحه ---

class _AppBarActions extends StatelessWidget {
  final CalibrationProvider provider;
  const _AppBarActions({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}

// --- ویجت جدید: نوار ابزار بازطراحی شده ---
class _EditingToolbar extends StatelessWidget {
  final CalibrationProvider provider;
  const _EditingToolbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // بخش ابزارهای عمومی
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: provider.canUndo ? provider.undo : null),
              IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: provider.canRedo ? provider.redo : null),
              IconButton(
                  icon: const Icon(Icons.group_work_outlined,
                      color: Colors.purple),
                  onPressed: () {/* ... */}),
            ],
          ),
          // ٢. بخش ابزارهای کالیبراسیون سریع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.skip_previous),
                    tooltip: 'ثبت برای قبلی',
                    onPressed: provider.stampPreviousWord),
                IconButton(
                    icon: const Icon(Icons.gps_fixed, color: Colors.red),
                    tooltip: 'ثبت مجدد برای فعلی',
                    onPressed: provider.restampCurrentWord),
                IconButton(
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'ثبت برای بعدی',
                    onPressed: provider.stampNextWord),
              ],
            ),
          ),
          // بخش ابزارهای جانبی
          Row(
            children: [
              IconButton(
                  icon:
                      const Icon(Icons.visibility_outlined, color: Colors.teal),
                  onPressed: () {/* ... */}),
              IconButton(
                  icon: const Icon(Icons.archive_outlined, color: Colors.green),
                  onPressed: () {/* ... */}),
            ],
          ),
        ],
      ),
    );
  }
}

// --- ویجت جدید: پنل حل تداخل ---
class _ConflictResolutionPanel extends StatelessWidget {
  final CalibrationProvider provider;
  const _ConflictResolutionPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final choices = provider.timestamps[provider.selectedWordKey] ?? [];
    return Container(
      key: const ValueKey('ConflictPanel'),
      padding: const EdgeInsets.all(8.0),
      color: Colors.orange.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تداخل شناسایی شد! یک گزینه را انتخاب کنید:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...choices
              .map((choice) => ListTile(
                    title: Text('${choice.source}: ${choice.timestamp} ms'),
                    leading: Icon(
                      choice.isChosen
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: choice.isChosen
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                    onTap: () => provider.resolveConflict(
                        provider.selectedWordKey!, choice),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.orange),
                      onPressed: () {
                        provider.audioPlayer
                            .seek(Duration(milliseconds: choice.timestamp));
                        provider.audioPlayer.play();
                      },
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}

// --- ویجت کلمه با قابلیت نمایش تداخل ---
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
    final choices = provider.timestamps[key];
    final bool isTimestamped = choices != null && choices.isNotEmpty;
    // یک کلمه دارای تداخل است اگر بیش از یک گزینه داشته باشد
    final bool hasConflict = choices != null && choices.length > 1;
    final bool isSelected = provider.selectedWordKey == key;
    final bool isRangeStart = provider.rangeStartKey == key;
    final bool isRangeEnd = provider.rangeEndKey == key;

    bool isInRange = false;
    // ... منطق isInRange بدون تغییر ...

    final word = provider.arabicLinesOfWords[lineIndex][wordIndex];

    return InkWell(
      onTap: () {
        if (provider.isRangeSelectionMode) {
          provider.setRangeMarker(lineIndex, wordIndex);
        } else {
          // اگر کلمه زمان‌بندی نشده، یکی برایش بساز
          if (!isTimestamped) {
            provider.assignTimestamp(lineIndex, wordIndex);
          }
          // کلمه را برای نمایش پنل مناسب (تنظیم دقیق یا حل تداخل) انتخاب کن
          provider.selectWord(lineIndex, wordIndex);
        }
      },
      child: Chip(
        label: Text(word,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        // ٤. رنگ نارنجی برای نمایش تداخل
        backgroundColor: isRangeStart || isRangeEnd
            ? Colors.blue.shade700
            : isInRange
                ? Colors.blue.shade300
                : hasConflict
                    ? Colors.orange.shade700
                    : isTimestamped
                        ? Colors.green
                        : Colors.grey.shade600,
        shape: isSelected
            ? StadiumBorder(
                side: BorderSide(color: Colors.deepOrange.shade700, width: 2.5))
            : const StadiumBorder(),
      ),
    );
  }
}

class _FineTuneControls extends StatelessWidget {
  final CalibrationProvider provider;
  const _FineTuneControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final key = provider.selectedWordKey;
    final choices = (key != null && provider.timestamps.containsKey(key))
        ? provider.timestamps[key]!
        : <CalibrationChoice>[];
    final chosenTimestamp = choices.isNotEmpty
        ? choices
            .firstWhere((c) => c.isChosen, orElse: () => choices.first)
            .timestamp
        : 0;

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.deepOrange.shade100,
      child: Column(
        children: [
          Text('تنظیم دقیق کلمه انتخاب شده: $chosenTimestamp ms'),
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
    if (provider.arabicLinesOfWords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: provider.arabicLinesOfWords.length,
      itemBuilder: (context, lineIndex) {
        final words = provider.arabicLinesOfWords[lineIndex];
        final translation = (lineIndex < provider.translationLines.length)
            ? provider.translationLines[lineIndex]
            : '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
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
                if (translation.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(
                    translation,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalibrationDrawer extends StatelessWidget {
  final CalibrationProvider provider;
  const _CalibrationDrawer({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepOrange),
            child: Text(provider.project.title,
                style: const TextStyle(fontSize: 24, color: Colors.white)),
          ),
          ListTile(
            title: const Text('فایل صوتی'),
            subtitle: Text(provider.project.audioPath,
                overflow: TextOverflow.ellipsis),
            leading: const Icon(Icons.audiotrack),
          ),
          ListTile(
            title: const Text('فایل متن اصلی'),
            subtitle: Text(provider.project.mainTextPath,
                overflow: TextOverflow.ellipsis),
            leading: const Icon(Icons.text_fields),
          ),
          if (provider.project.translationTextPath != null)
            ListTile(
              title: const Text('فایل ترجمه'),
              subtitle: Text(provider.project.translationTextPath!,
                  overflow: TextOverflow.ellipsis),
              leading: const Icon(Icons.translate),
            ),
          const Divider(),
          ListTile(
            title: const Text('تغییر حالت پردازش متن'),
            subtitle: Text(provider.project.textParsingMode == 'interleaved'
                ? 'ترکیبی'
                : 'مجزا'),
            leading: const Icon(Icons.sync_alt),
            onTap: () {
              // در آینده می‌توان منطق تغییر حالت را اینجا اضافه کرد
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
