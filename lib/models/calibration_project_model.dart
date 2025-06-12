class CalibrationProject {
  final String id;
  String title;
  String audioPath; // مسیر فایل صوتی در حافظه دستگاه
  String textPath; // مسیر فایل متنی در حافظه دستگاه

  CalibrationProject({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.textPath,
  });

  // متد برای تبدیل مدل به نقشه (Map) جهت ذخیره‌سازی در JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audioPath': audioPath,
      'textPath': textPath,
    };
  }

  // متد برای ساختن مدل از روی نقشه (Map) خوانده شده از JSON
  factory CalibrationProject.fromJson(Map<String, dynamic> json) {
    return CalibrationProject(
      id: json['id'],
      title: json['title'],
      audioPath: json['audioPath'],
      textPath: json['textPath'],
    );
  }
}
