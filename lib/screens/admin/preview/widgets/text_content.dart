import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'mini_waveform.dart';

/// ویجت برای نمایش لیست آیات با قابلیت اسکرول و هایلایت
class TextContent extends StatelessWidget {
  final int lineCount;
  final int currentLine;
  final List<List<String>> linesOfWords;
  final Map<String, int> timestamps;
  final int currentWordIndex;
  final bool isPlaying;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  const TextContent({
    super.key,
    required this.lineCount,
    required this.currentLine,
    required this.linesOfWords,
    required this.timestamps,
    required this.currentWordIndex,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: lineCount,
      itemBuilder: (context, lineIndex) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (lineIndex * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildVerseCard(context, lineIndex),
        );
      },
    );
  }

  Widget _buildVerseCard(BuildContext context, int lineIndex) {
    final bool isCurrentLine = currentLine == lineIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isCurrentLine
                ? const Color(0xFF6C63FF).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: isCurrentLine ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCurrentLine
              ? const Color(0xFF6C63FF).withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentLine
                      ? const Color(0xFF6C63FF)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'آیه ${lineIndex + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCurrentLine ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
              if (isCurrentLine) MiniWaveform(isPlaying: isPlaying),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 12.0,
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.center,
            children: _buildLineSpans(lineIndex),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLineSpans(int lineIndex) {
    List<Widget> spans = [];
    for (int wordIndex = 0;
        wordIndex < linesOfWords[lineIndex].length;
        wordIndex++) {
      final key = '$lineIndex-$wordIndex';
      final bool isTimestamped = timestamps.containsKey(key);
      final bool isPast = lineIndex < currentLine ||
          (lineIndex == currentLine && wordIndex < currentWordIndex);
      final bool isCurrent =
          lineIndex == currentLine && wordIndex == currentWordIndex;
      final word = linesOfWords[lineIndex][wordIndex];

      spans.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getWordBackgroundColor(isCurrent, isPast, isTimestamped),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            word,
            style: TextStyle(
              fontFamily: 'Alhura',
              fontSize: isCurrent ? 32 : 28,
              color: _getWordTextColor(isCurrent, isPast, isTimestamped),
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return spans;
  }

  Color _getWordBackgroundColor(
      bool isCurrent, bool isPast, bool isTimestamped) {
    if (isCurrent) return Colors.amber[100]!;
    if (isPast && isTimestamped)
      return const Color(0xFF6C63FF).withOpacity(0.1);
    if (isTimestamped) return Colors.grey[100]!;
    return Colors.transparent;
  }

  Color _getWordTextColor(bool isCurrent, bool isPast, bool isTimestamped) {
    if (isCurrent) return Colors.amber[900]!;
    if (isPast && isTimestamped) return const Color(0xFF6C63FF);
    if (isTimestamped) return Colors.grey[700]!;
    return Colors.grey[400]!;
  }
}
