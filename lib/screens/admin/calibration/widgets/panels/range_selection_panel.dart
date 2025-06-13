import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';

/// پنل برای مدیریت حالت انتخاب محدوده
class RangeSelectionPanel extends StatelessWidget {
  const RangeSelectionPanel({super.key});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();
    final canDelete =
        provider.rangeStartKey != null && provider.rangeEndKey != null;

    return Padding(
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
    );
  }
}
