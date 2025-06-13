part of 'settings_sheet.dart';

// این متد به عنوان بخشی از _ModernSettingsSheetState عمل می‌کند
// و به تمام متغیرها و پراپرتی‌های آن دسترسی دارد.
extension _Dialogs on _ModernSettingsSheetState {
  void _showResetDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(width: 12),
              const Text('بازگشت به پیش‌فرض'),
            ],
          ),
          content: const Text(
            'آیا از بازگشت تمام تنظیمات به حالت پیش‌فرض اطمینان دارید؟',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // بازگشت به تنظیمات پیش‌فرض
                settingsProvider.updateAppColor(const Color(0xFF1F9671));
                settingsProvider.updateArabicFontSize(22.0);
                settingsProvider.updateTranslationFontSize(16.0);
                settingsProvider.updateShowTimeline(true);
                settingsProvider.updateBackgroundOpacity(0.95);
                settingsProvider.updateShowEqualizer(true);

                Navigator.pop(dialogContext);
                // بستن شیت تنظیمات پس از تایید
                if (mounted) {
                  Navigator.pop(context);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تنظیمات به حالت پیش‌فرض بازگشت'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('تایید'),
            ),
          ],
        ),
      ),
    );
  }
}
