import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// نوار ابزار حرفه‌ای برای ویرایش و کالیبراسیون
class ProfessionalEditingToolbar extends StatelessWidget {
  const ProfessionalEditingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
            _buildQuickActionButton(
              icon: Icons.skip_previous_rounded,
              onPressed: provider.calibratePrevious,
              tooltip: 'کلمه قبلی (<-)',
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              icon: Icons.refresh_rounded,
              onPressed: provider.recalibrateCurrent,
              tooltip: 'ثبت مجدد (Enter)',
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              icon: Icons.skip_next_rounded,
              onPressed: provider.calibrateNext,
              tooltip: 'کلمه بعدی (->)',
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

  Future<void> _showImportDialog(
      BuildContext context, CalibrationProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final jsonContent = await file.readAsString();
        await provider.importAndMergeFromJson(jsonContent);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فایل با موفقیت وارد و ادغام شد'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در وارد کردن فایل: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
