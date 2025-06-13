import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';

/// ویجت برای نمایش یک کلمه قابل کالیبره شدن
class CalibratableWord extends StatelessWidget {
  final int lineIndex;
  final int wordIndex;

  const CalibratableWord({
    super.key,
    required this.lineIndex,
    required this.wordIndex,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();
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
