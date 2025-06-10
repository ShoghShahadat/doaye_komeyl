class Verse {
  final String arabic;
  final String translation;
  final String id;
  final int startTime; // زمان شروع به میلی‌ثانیه

  Verse({
    required this.arabic,
    required this.translation,
    required this.id,
    required this.startTime,
  });

  // یک کارخانه (Factory) برای ساختن نمونه Verse از داده‌های JSON
  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      arabic: json['آیه'] as String,
      translation: json['ترجمه'] as String,
      id: json['ایدی'] as String,
      // اطمینان از اینکه زمان به صورت عدد صحیح خوانده می‌شود
      startTime: double.parse(json['شروع'].toString()).toInt(),
    );
  }
}
