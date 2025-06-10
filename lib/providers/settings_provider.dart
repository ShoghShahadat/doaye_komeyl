import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// کلیدهای ذخیره‌سازی
const String ARABIC_FONT_SIZE_KEY = 'سایز عربی';
const String TRANSLATION_FONT_SIZE_KEY = 'سایز ترجمه';
const String SHOW_TIMELINE_KEY = 'نمایش تایم لاین';
const String BACKGROUND_OPACITY_KEY = 'شفافیت';
const String SHOW_EQUALIZER_KEY = 'نمایش اکولایزر';
const String APP_COLOR_KEY = 'رنگ برنامه';

class SettingsProvider with ChangeNotifier {
  // مقادیر پیش‌فرض
  double _arabicFontSize = 22.0;
  double _translationFontSize = 16.0;
  bool _showTimeline = true;
  double _backgroundOpacity = 0.95;
  bool _showEqualizer = true;
  Color _appColor = const Color(0xFF1F9671);

  // Getters
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;
  bool get showTimeline => _showTimeline;
  double get backgroundOpacity => _backgroundOpacity;
  bool get showEqualizer => _showEqualizer;
  Color get appColor => _appColor;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _arabicFontSize = prefs.getDouble(ARABIC_FONT_SIZE_KEY) ?? 22.0;
    _translationFontSize = prefs.getDouble(TRANSLATION_FONT_SIZE_KEY) ?? 16.0;
    _showTimeline = prefs.getBool(SHOW_TIMELINE_KEY) ?? true;
    _showEqualizer = prefs.getBool(SHOW_EQUALIZER_KEY) ?? true;

    int? savedColorValue = prefs.getInt(APP_COLOR_KEY);
    _appColor = savedColorValue != null
        ? Color(savedColorValue)
        : const Color(0xFF1F9671);

    // --- این بخش تغییر کرده است ---
    // ١. مقدار شفافیت را از حافظه می‌خوانیم
    double loadedOpacity = prefs.getDouble(BACKGROUND_OPACITY_KEY) ?? 0.3;
    // ٢. مقدار خوانده شده را در محدوده مجاز (0.0 تا 0.8) قرار می‌دهیم
    // اگر مقدار خوانده شده 0.9 باشد، به 0.8 تبدیل می‌شود
    _backgroundOpacity = loadedOpacity.clamp(0.5, 1);
    // --- پایان تغییرات ---

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(ARABIC_FONT_SIZE_KEY, _arabicFontSize);
    await prefs.setDouble(TRANSLATION_FONT_SIZE_KEY, _translationFontSize);
    await prefs.setBool(SHOW_TIMELINE_KEY, _showTimeline);
    await prefs.setDouble(BACKGROUND_OPACITY_KEY, _backgroundOpacity);
    await prefs.setBool(SHOW_EQUALIZER_KEY, _showEqualizer);
    await prefs.setInt(APP_COLOR_KEY, _appColor.value);
  }

  // ... بقیه متدهای آپدیت بدون تغییر ...
  void updateAppColor(Color newColor) {
    _appColor = newColor;
    _saveSettings();
    notifyListeners();
  }

  void updateArabicFontSize(double newSize) {
    _arabicFontSize = newSize;
    _saveSettings();
    notifyListeners();
  }

  void updateTranslationFontSize(double newSize) {
    _translationFontSize = newSize;
    _saveSettings();
    notifyListeners();
  }

  void updateShowTimeline(bool isVisible) {
    _showTimeline = isVisible;
    _saveSettings();
    notifyListeners();
  }

  void updateBackgroundOpacity(double newOpacity) {
    _backgroundOpacity = newOpacity;
    _saveSettings();
    notifyListeners();
  }

  void updateShowEqualizer(bool isVisible) {
    _showEqualizer = isVisible;
    _saveSettings();
    notifyListeners();
  }
}
