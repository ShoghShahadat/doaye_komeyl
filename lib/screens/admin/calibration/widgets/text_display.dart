import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';
import 'calibratable_word.dart';

/// ویجت اصلی برای نمایش متن قابل کالیبره شدن
class TextDisplay extends StatelessWidget {
  const TextDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();

    if (provider.arabicLinesOfWords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 200), // فضای بیشتر در پایین
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6C63FF),
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
                        return CalibratableWord(
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
