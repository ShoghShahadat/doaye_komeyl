import 'package:flutter/material.dart';
import 'package:komeyl_app/models/calibration_choice_model.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';

/// پنل برای حل تداخل بین چند زمان‌بندی مختلف برای یک کلمه
class ConflictResolutionPanel extends StatelessWidget {
  const ConflictResolutionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();
    final choices = provider.timestamps[provider.selectedWordKey] ?? [];

    return Column(
      children: [
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
                  provider.audioPlayer
                      .seek(Duration(milliseconds: choice.timestamp));
                  provider.audioPlayer.play();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

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
