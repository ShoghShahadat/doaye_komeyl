part of 'app_drawer.dart';

// این متدها به عنوان بخشی از _AppDrawerState عمل می‌کنند
extension _DrawerActions on _AppDrawerState {
  void _showAboutDialog(BuildContext context, Color appColor) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appColor,
                        Color.lerp(appColor, Colors.black, 0.2)!,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'دعای کمیل',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alhura',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نسخه 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'این برنامه با هدف ترویج فرهنگ دعا و نیایش\nو آسان‌سازی دسترسی به دعای شریف کمیل\nتوسعه یافته است',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('بستن'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareApp(BuildContext context, Color appColor) {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    // در اینجا می‌توانید از پکیج share_plus استفاده کنید
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('لینک برنامه کپی شد'),
        backgroundColor: appColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
