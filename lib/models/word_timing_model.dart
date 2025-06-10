class WordTiming {
  final String text;
  final int startTime; // زمان شروع به میلی‌ثانیه

  WordTiming({required this.text, required this.startTime});

  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      text: json['متن'] as String,
      startTime: int.parse(json['شروع'].toString()),
    );
  }
}
