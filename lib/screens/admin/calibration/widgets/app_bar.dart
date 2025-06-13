import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';

/// AppBar سفارشی برای صفحه کالیبراسیون
class CalibrationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CalibrationProvider provider;
  const CalibrationAppBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.project.title,
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
    final color = percentage == 100 ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percentage == 100 ? Icons.check_circle : Icons.timeline,
            size: 16,
            color: color[700],
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color[700],
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
