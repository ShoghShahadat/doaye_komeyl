class CalibrationChoice {
  int timestamp;
  final String source; // منبع این زمان‌بندی (مثلا: 'شما' یا 'فایل وارد شده')
  bool isChosen; // آیا این گزینه به عنوان گزینه نهایی انتخاب شده است؟

  CalibrationChoice({
    required this.timestamp,
    required this.source,
    this.isChosen = false,
  });

  // متدهای لازم برای ذخیره‌سازی در تاریخچه Undo/Redo
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'source': source,
        'isChosen': isChosen,
      };

  factory CalibrationChoice.fromJson(Map<String, dynamic> json) =>
      CalibrationChoice(
        timestamp: json['timestamp'],
        source: json['source'],
        isChosen: json['isChosen'],
      );
}
