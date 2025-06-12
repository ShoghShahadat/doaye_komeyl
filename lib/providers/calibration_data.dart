class CalibrationChoice {
  final int timestamp;
  final String source; // منبع این کالیبراسیون، مثلا "محلی" یا "فایل وارداتی"

  CalibrationChoice({required this.timestamp, required this.source});

  Map<String, dynamic> toJson() => {'timestamp': timestamp, 'source': source};

  factory CalibrationChoice.fromJson(Map<String, dynamic> json) =>
      CalibrationChoice(
        timestamp: int.parse(json['timestamp'].toString()),
        source: json['source'],
      );
}

class WordCalibrationData {
  List<CalibrationChoice> choices;
  int activeChoiceIndex; // ایندکس گزینه فعال از لیست بالا

  WordCalibrationData({required this.choices, this.activeChoiceIndex = 0});

  CalibrationChoice get activeChoice => choices[activeChoiceIndex];

  Map<String, dynamic> toJson() => {
        'choices': choices.map((c) => c.toJson()).toList(),
        'activeChoiceIndex': activeChoiceIndex,
      };

  factory WordCalibrationData.fromJson(Map<String, dynamic> json) =>
      WordCalibrationData(
        choices: (json['choices'] as List)
            .map((c) => CalibrationChoice.fromJson(c))
            .toList(),
        activeChoiceIndex: json['activeChoiceIndex'],
      );
}
