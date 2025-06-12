class CalibrationProject {
  final String id;
  String title;
  String audioPath;
  // نوع ورود متن: 'interleaved' یا 'separate'
  String textParsingMode;
  String mainTextPath; // مسیر فایل اصلی (عربی)
  String? translationTextPath; // مسیر فایل ترجمه (در حالت مجزا)

  CalibrationProject({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.textParsingMode,
    required this.mainTextPath,
    this.translationTextPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audioPath': audioPath,
      'textParsingMode': textParsingMode,
      'mainTextPath': mainTextPath,
      'translationTextPath': translationTextPath,
    };
  }

  factory CalibrationProject.fromJson(Map<String, dynamic> json) {
    return CalibrationProject(
      id: json['id'],
      title: json['title'],
      audioPath: json['audioPath'],
      textParsingMode: json['textParsingMode'] ?? 'interleaved',
      mainTextPath: json['mainTextPath'],
      translationTextPath: json['translationTextPath'],
    );
  }
}
