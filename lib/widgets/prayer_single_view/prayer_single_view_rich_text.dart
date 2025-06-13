part of 'prayer_single_view.dart';

// این متد به عنوان بخشی از _ModernPrayerSingleViewState عمل می‌کند
extension _RichTextBuilder on _ModernPrayerSingleViewState {
  TextSpan _buildRichTextVerse(
    SettingsProvider settingsProvider,
    List<WordTiming> wordTimings,
    int currentWordIndex,
    double fontSize,
  ) {
    final Color readColor = settingsProvider.appColor;
    const Color readingColor = Color(0xFFE91E63);
    const Color specialWordColor = Color(0xFF1F9671);
    final Color defaultColor = Colors.grey.shade600;

    final List<String> specialWords = ["رَبِّ", "اِلهى", "اَللّهُمَّ"];

    List<TextSpan> textSpans = [];
    for (int i = 0; i < wordTimings.length; i++) {
      final isCurrentWord = i == currentWordIndex;
      final isPastWord = i < currentWordIndex;
      final isSpecialWord = specialWords.contains(wordTimings[i].text);

      Color color;
      double wordFontSize = fontSize;
      FontWeight fontWeight = FontWeight.normal;
      List<Shadow> shadows = [];

      if (isCurrentWord) {
        color = readingColor;
        wordFontSize += 4;
        fontWeight = FontWeight.bold;
        shadows = [
          Shadow(
            blurRadius: 20.0,
            color: readingColor.withOpacity(0.5),
            offset: const Offset(0, 3),
          ),
        ];
      } else if (isPastWord) {
        color = isSpecialWord ? specialWordColor : readColor;
        shadows = [
          Shadow(
            blurRadius: 3.0,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(1, 1),
          ),
        ];
      } else {
        color = defaultColor;
        shadows = [
          Shadow(
            blurRadius: 2.0,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(1, 1),
          ),
        ];
      }

      textSpans.add(
        TextSpan(
          text: '${wordTimings[i].text} ',
          style: TextStyle(
            fontFamily: 'Alhura',
            fontSize: wordFontSize,
            color: color,
            fontWeight: fontWeight,
            height: 2.2,
            letterSpacing: 1.0,
            shadows: shadows,
          ),
        ),
      );
    }
    return TextSpan(children: textSpans);
  }
}
