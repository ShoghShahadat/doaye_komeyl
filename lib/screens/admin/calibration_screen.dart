import 'dart:io';
import 'dart:ui';
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
          return Theme(
            data: _buildCustomTheme(context),
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              drawer: _ModernCalibrationDrawer(provider: provider),
              appBar: _buildModernAppBar(context, provider),
              body: SafeArea(
                child: Column(
                  children: [
                    _ModernPlayerControls(provider: provider),
                    _ProfessionalEditingToolbar(provider: provider),
                    Expanded(
                      child: _ModernTextDisplay(provider: provider),
                    ),
                    _buildBottomPanel(provider),
                  ],
                ),
              ),
              floatingActionButton: _buildFloatingButtons(context, provider),
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildCustomTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(
      BuildContext context, CalibrationProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'کالیبراسیون متن و صدا',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        _buildStatisticsBadge(provider),
        const SizedBox(width: 8),
        _buildUndoRedoButtons(provider),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatisticsBadge(CalibrationProvider provider) {
    final calibratedCount = provider.timestamps.length;
    final totalWords =
        provider.arabicLinesOfWords.expand((line) => line).length;
    final percentage =
        totalWords > 0 ? (calibratedCount / totalWords * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: percentage == 100 ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percentage == 100 ? Icons.check_circle : Icons.timeline,
            size: 16,
            color: percentage == 100 ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: percentage == 100 ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUndoRedoButtons(CalibrationProvider provider) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: provider.canUndo ? provider.undo : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.undo_rounded,
                color: provider.canUndo ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: provider.canRedo ? provider.redo : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.redo_rounded,
                color: provider.canRedo ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(CalibrationProvider provider) {
    final selectedKey = provider.selectedWordKey;
    bool hasConflict = selectedKey != null &&
        provider.timestamps.containsKey(selectedKey) &&
        provider.timestamps[selectedKey]!.length > 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _getBottomPanelHeight(provider, hasConflict),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _selectBottomPanel(provider, hasConflict),
      ),
    );
  }

  double _getBottomPanelHeight(CalibrationProvider provider, bool hasConflict) {
    if (hasConflict) return 200;
    if (provider.isRangeSelectionMode) return 80;
    if (provider.selectedWordKey != null) return 120;
    return 0;
  }

  Widget _selectBottomPanel(CalibrationProvider provider, bool hasConflict) {
    if (hasConflict) {
      return _ModernConflictResolutionPanel(
        key: const ValueKey('conflict'),
        provider: provider,
      );
    } else if (provider.isRangeSelectionMode) {
      return _ModernRangeSelectionPanel(
        key: const ValueKey('range'),
        provider: provider,
      );
    } else if (provider.selectedWordKey != null) {
      return _ModernFineTunePanel(
        key: const ValueKey('finetune'),
        provider: provider,
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildFloatingButtons(
      BuildContext context, CalibrationProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'preview',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6C63FF),
          elevation: 4,
          onPressed: () => _showPreview(context, provider),
          child: const Icon(Icons.preview_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'export',
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[700],
          elevation: 4,
          onPressed: () => _showExportOptions(context, provider),
          child: const Icon(Icons.save_alt_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'calibrate',
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: provider.calibrateNext,
          child: const Icon(Icons.fiber_manual_record_rounded, size: 20),
        ),
      ],
    );
  }

  void _showPreview(BuildContext context, CalibrationProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          project: project,
          timestamps: provider.timestamps.map((key, choices) {
            final chosen = choices.firstWhere(
              (c) => c.isChosen,
              orElse: () => choices.first,
            );
            return MapEntry(key, chosen.timestamp);
          }),
          linesOfWords: provider.arabicLinesOfWords,
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, CalibrationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExportOptionsSheet(provider: provider),
    );
  }
}

// Modern Player Controls
class _ModernPlayerControls extends StatelessWidget {
  final CalibrationProvider provider;
  const _ModernPlayerControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
                            child: _ModernSlider(
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
                  isPlaying
                      ? provider.audioPlayer.pause()
                      : provider.audioPlayer.play();
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

// Modern Slider Widget
class _ModernSlider extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  const _ModernSlider({
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

// Professional Editing Toolbar
class _ProfessionalEditingToolbar extends StatelessWidget {
  final CalibrationProvider provider;
  const _ProfessionalEditingToolbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
      child: Row(
        children: [
          _buildToolButton(
            icon: Icons.select_all_rounded,
            label: 'انتخاب محدوده',
            isActive: provider.isRangeSelectionMode,
            onPressed: provider.toggleRangeSelectionMode,
            color: Colors.blue,
          ),
          const VerticalDivider(indent: 12, endIndent: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickActionButton(
                  icon: Icons.skip_previous_rounded,
                  onPressed: provider.calibratePrevious,
                  tooltip: 'کلمه قبلی',
                ),
                const SizedBox(width: 8),
                _buildQuickActionButton(
                  icon: Icons.refresh_rounded,
                  onPressed: provider.recalibrateCurrent,
                  tooltip: 'ثبت مجدد',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildQuickActionButton(
                  icon: Icons.skip_next_rounded,
                  onPressed: provider.calibrateNext,
                  tooltip: 'کلمه بعدی',
                ),
              ],
            ),
          ),
          const VerticalDivider(indent: 12, endIndent: 12),
          _buildToolButton(
            icon: Icons.upload_file_rounded,
            label: 'وارد کردن',
            onPressed: () => _showImportDialog(context, provider),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    bool isActive = false,
  }) {
    return Material(
      color: isActive
          ? (color ?? const Color(0xFF6C63FF)).withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? (color ?? const Color(0xFF6C63FF))
                    : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? (color ?? const Color(0xFF6C63FF))
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: color ?? Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, CalibrationProvider provider) {
    // Implementation for import dialog
  }
}

// Modern Text Display
class _ModernTextDisplay extends StatelessWidget {
  final CalibrationProvider provider;
  const _ModernTextDisplay({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.arabicLinesOfWords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.arabicLinesOfWords.length,
      itemBuilder: (context, lineIndex) {
        final words = provider.arabicLinesOfWords[lineIndex];
        final translation = (lineIndex < provider.translationLines.length)
            ? provider.translationLines[lineIndex]
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'آیه ${lineIndex + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildLineProgress(provider, lineIndex, words.length),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      textDirection: TextDirection.rtl,
                      children: List.generate(words.length, (wordIndex) {
                        return _ModernCalibratableWord(
                          provider: provider,
                          lineIndex: lineIndex,
                          wordIndex: wordIndex,
                        );
                      }),
                    ),
                    if (translation.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          translation,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLineProgress(
      CalibrationProvider provider, int lineIndex, int totalWords) {
    int calibratedWords = 0;
    for (int i = 0; i < totalWords; i++) {
      if (provider.timestamps.containsKey('$lineIndex-$i')) {
        calibratedWords++;
      }
    }

    final percentage =
        totalWords > 0 ? (calibratedWords / totalWords * 100).round() : 0;
    final color = percentage == 100 ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percentage == 100 ? Icons.check_circle : Icons.timelapse,
            size: 14,
            color: color[700],
          ),
          const SizedBox(width: 4),
          Text(
            '$calibratedWords/$totalWords',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Calibratable Word
class _ModernCalibratableWord extends StatelessWidget {
  final CalibrationProvider provider;
  final int lineIndex;
  final int wordIndex;

  const _ModernCalibratableWord({
    required this.provider,
    required this.lineIndex,
    required this.wordIndex,
  });

  @override
  Widget build(BuildContext context) {
    final key = '$lineIndex-$wordIndex';
    final choices = provider.timestamps[key];
    final bool isTimestamped = choices != null && choices.isNotEmpty;
    final bool hasConflict = choices != null && choices.length > 1;
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
      final currentParts = key.split('-').map(int.parse).toList();

      isInRange = (currentParts[0] > startParts[0] ||
              (currentParts[0] == startParts[0] &&
                  currentParts[1] >= startParts[1])) &&
          (currentParts[0] < endParts[0] ||
              (currentParts[0] == endParts[0] &&
                  currentParts[1] <= endParts[1]));
    }

    final word = provider.arabicLinesOfWords[lineIndex][wordIndex];

    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getWordColor(isTimestamped, hasConflict, isSelected,
              isRangeStart, isRangeEnd, isInRange),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBorderColor(isSelected, isRangeStart, isRangeEnd),
            width: isSelected || isRangeStart || isRangeEnd ? 2 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          word,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Alhura',
          ),
        ),
      ),
    );
  }

  Color _getWordColor(bool isTimestamped, bool hasConflict, bool isSelected,
      bool isRangeStart, bool isRangeEnd, bool isInRange) {
    if (isRangeStart || isRangeEnd) return Colors.blue[600]!;
    if (isInRange) return Colors.blue[400]!;
    if (hasConflict) return Colors.orange[600]!;
    if (isTimestamped) return const Color(0xFF4CAF50);
    if (isSelected) return const Color(0xFF6C63FF);
    return Colors.grey[400]!;
  }

  Color _getBorderColor(bool isSelected, bool isRangeStart, bool isRangeEnd) {
    if (isRangeStart || isRangeEnd) return Colors.blue[800]!;
    if (isSelected) return const Color(0xFF5753C9);
    return Colors.transparent;
  }
}

// Modern Conflict Resolution Panel
class _ModernConflictResolutionPanel extends StatelessWidget {
  final CalibrationProvider provider;
  const _ModernConflictResolutionPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final choices = provider.timestamps[provider.selectedWordKey] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تداخل زمان‌بندی',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${choices.length} گزینه',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: choices.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final choice = choices[index];
                return _ConflictChoiceItem(
                  choice: choice,
                  isChosen: choice.isChosen,
                  onTap: () => provider.resolveConflict(
                    provider.selectedWordKey!,
                    choice,
                  ),
                  onPlay: () {
                    provider.audioPlayer.seek(
                      Duration(milliseconds: choice.timestamp),
                    );
                    provider.audioPlayer.play();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Conflict Choice Item
class _ConflictChoiceItem extends StatelessWidget {
  final CalibrationChoice choice;
  final bool isChosen;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _ConflictChoiceItem({
    required this.choice,
    required this.isChosen,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isChosen
          ? const Color(0xFF6C63FF).withOpacity(0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isChosen ? const Color(0xFF6C63FF) : Colors.transparent,
                  border: Border.all(
                    color:
                        isChosen ? const Color(0xFF6C63FF) : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isChosen
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.source,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(choice.timestamp / 1000).toStringAsFixed(2)} ثانیه',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isChosen ? const Color(0xFF6C63FF) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onPlay,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern Fine Tune Panel
class _ModernFineTunePanel extends StatelessWidget {
  final CalibrationProvider provider;
  const _ModernFineTunePanel({super.key, required this.provider});

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'تنظیم دقیق زمان',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(chosenTimestamp / 1000).toStringAsFixed(2)}s',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildNudgeButton(
                  label: '-100ms',
                  onPressed: () => provider.nudgeTimestamp(-100),
                ),
                const SizedBox(width: 8),
                _buildNudgeButton(
                  label: '-10ms',
                  onPressed: () => provider.nudgeTimestamp(-10),
                ),
                const Spacer(),
                _buildControlButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red,
                  onPressed: provider.deleteSelectedTimestamp,
                ),
                const SizedBox(width: 8),
                _buildControlButton(
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF6C63FF),
                  onPressed: provider.playFromSelected,
                ),
                const Spacer(),
                _buildNudgeButton(
                  label: '+10ms',
                  onPressed: () => provider.nudgeTimestamp(10),
                ),
                const SizedBox(width: 8),
                _buildNudgeButton(
                  label: '+100ms',
                  onPressed: () => provider.nudgeTimestamp(100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Modern Range Selection Panel
class _ModernRangeSelectionPanel extends StatelessWidget {
  final CalibrationProvider provider;
  const _ModernRangeSelectionPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final canDelete =
        provider.rangeStartKey != null && provider.rangeEndKey != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.select_all_rounded,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.rangeStartKey == null
                    ? 'کلمه شروع را انتخاب کنید'
                    : provider.rangeEndKey == null
                        ? 'کلمه پایان را انتخاب کنید'
                        : 'محدوده انتخاب شده',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (canDelete)
              ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(context, provider),
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('حذف محدوده'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, CalibrationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تایید حذف'),
        content: const Text(
          'آیا از حذف زمان‌بندی کلمات انتخاب شده اطمینان دارید؟\nاین عمل قابل بازگشت است.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteTimestampsInRange();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// Modern Calibration Drawer
class _ModernCalibrationDrawer extends StatelessWidget {
  final CalibrationProvider provider;
  const _ModernCalibrationDrawer({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6C63FF),
                    const Color(0xFF5753C9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.project.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'پروژه کالیبراسیون',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.audiotrack_rounded,
              title: 'فایل صوتی',
              subtitle: _getFileName(provider.project.audioPath),
              color: Colors.purple,
            ),
            _buildDrawerItem(
              icon: Icons.text_fields_rounded,
              title: 'فایل متن اصلی',
              subtitle: _getFileName(provider.project.mainTextPath),
              color: Colors.blue,
            ),
            if (provider.project.translationTextPath != null)
              _buildDrawerItem(
                icon: Icons.translate_rounded,
                title: 'فایل ترجمه',
                subtitle: _getFileName(provider.project.translationTextPath!),
                color: Colors.green,
              ),
            const Divider(height: 32),
            _buildDrawerItem(
              icon: Icons.sync_alt_rounded,
              title: 'حالت پردازش متن',
              subtitle: provider.project.textParsingMode == 'interleaved'
                  ? 'ترکیبی (عربی و ترجمه)'
                  : 'مجزا',
              color: Colors.orange,
              onTap: () {
                // Implementation for changing text parsing mode
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'میانبرهای صفحه‌کلید',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutItem('Space', 'پخش/توقف'),
                  _buildShortcutItem('Enter', 'ثبت زمان کلمه فعلی'),
                  _buildShortcutItem('→', 'کلمه بعدی'),
                  _buildShortcutItem('←', 'کلمه قبلی'),
                  _buildShortcutItem('Ctrl+Z', 'Undo'),
                  _buildShortcutItem('Ctrl+Y', 'Redo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
    );
  }

  Widget _buildShortcutItem(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// Export Options Sheet
class _ExportOptionsSheet extends StatelessWidget {
  final CalibrationProvider provider;
  const _ExportOptionsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'انتخاب نوع خروجی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildExportOption(
            context,
            icon: Icons.code_rounded,
            title: 'فایل JSON',
            subtitle: 'خروجی زمان‌بندی کلمات',
            color: Colors.blue,
            onTap: () => _exportJSON(context),
          ),
          _buildExportOption(
            context,
            icon: Icons.archive_rounded,
            title: 'بسته کامل ZIP',
            subtitle: 'شامل صوت، متن و زمان‌بندی',
            color: Colors.green,
            onTap: () => _exportZIP(context),
          ),
          _buildExportOption(
            context,
            icon: Icons.share_rounded,
            title: 'اشتراک‌گذاری',
            subtitle: 'ارسال فایل به دیگران',
            color: Colors.orange,
            onTap: () => _shareFiles(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportJSON(BuildContext context) async {
    final jsonString = provider.exportTimestampsToJson();
    final bytes = jsonString.codeUnits;

    await FileSaver.instance.saveFile(
      name: '${provider.project.title}_calibration',
      bytes: Uint8List.fromList(bytes),
      ext: 'json',
      mimeType: MimeType.json,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فایل JSON با موفقیت ذخیره شد'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportZIP(BuildContext context) async {
    final zipData = await provider.packageProjectAsZip();
    if (zipData != null) {
      await FileSaver.instance.saveFile(
        name: '${provider.project.title}_package',
        bytes: zipData,
        ext: 'zip',
        mimeType: MimeType.zip,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بسته ZIP با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareFiles(BuildContext context) async {
    final jsonString = provider.exportTimestampsToJson();
    await Share.share(
      jsonString,
      subject: 'کالیبراسیون ${provider.project.title}',
    );
    Navigator.pop(context);
  }
}
