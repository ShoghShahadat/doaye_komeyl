part of 'verse_list_item.dart';

// این متد به عنوان بخشی از _ModernVerseListItemState عمل می‌کند
// و به تمام متغیرهای آن دسترسی دارد.
extension _RichTextBuilder on _ModernVerseListItemState {
  TextSpan _buildRichTextVerse(
      BuildContext context,
      List<WordTiming> wordTimings,
      int currentWordIndex,
      SettingsProvider settingsProvider) {
    final Color readColor = settingsProvider.appColor;
    final Color readingColor = Colors.red.shade700;
    final Color specialWordColor = readColor.withBlue(150).withGreen(50);
    final Color defaultColor = Colors.grey.shade600;

    final List<String> specialWords = ["رَبِّ", "اِلهى", "اَللّهُمَّ"];

    List<TextSpan> textSpans = [];
    for (int i = 0; i < wordTimings.length; i++) {
      final isCurrentWord = i == currentWordIndex;
      final isPastWord = i < currentWordIndex;
      final isSpecialWord = specialWords.contains(wordTimings[i].text);

      Color color;
      double fontSize = settingsProvider.arabicFontSize;
      FontWeight fontWeight = FontWeight.normal;
      List<Shadow> shadows = [];

      if (isCurrentWord) {
        color = readingColor;
        fontSize += 1;
        fontWeight = FontWeight.bold;
        shadows = [
          Shadow(
            blurRadius: 10.0,
            color: readingColor.withOpacity(0.3),
            offset: const Offset(0, 1),
          ),
        ];
      } else if (isPastWord) {
        color = isSpecialWord ? specialWordColor : readColor;
      } else {
        color = defaultColor;
      }

      textSpans.add(
        TextSpan(
          text: '${wordTimings[i].text} ',
          style: TextStyle(
            fontFamily: 'Alhura',
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: 1.8,
            letterSpacing: 0.5,
            shadows: shadows,
          ),
        ),
      );
    }
    return TextSpan(children: textSpans);
  }
}
