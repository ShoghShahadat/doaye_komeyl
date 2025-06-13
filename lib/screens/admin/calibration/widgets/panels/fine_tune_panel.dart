import 'package:flutter/material.dart';
import 'package:komeyl_app/models/calibration_choice_model.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';

/// پنل برای تنظیم دقیق زمان یک کلمه انتخاب شده
class FineTunePanel extends StatelessWidget {
  const FineTunePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();
    final key = provider.selectedWordKey;
    final choices = (key != null && provider.timestamps.containsKey(key))
        ? provider.timestamps[key]!
        : <CalibrationChoice>[];
    final chosenTimestamp = choices.isNotEmpty
        ? choices
            .firstWhere((c) => c.isChosen, orElse: () => choices.first)
            .timestamp
        : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
        ),
      ],
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
