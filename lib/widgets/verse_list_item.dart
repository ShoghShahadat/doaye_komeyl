import 'package:flutter/material.dart';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart'; // import جدید
import 'package:provider/provider.dart';

class VerseListItem extends StatelessWidget {
  final Verse verse;
  final int index;

  const VerseListItem({
    super.key,
    required this.verse,
    required this.index,
  });

  TextSpan _buildListRichTextVerse(BuildContext context,
      List<WordTiming> wordTimings, int currentWordIndex) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // const Color readColor = Color(0xFF1F9671);
    const Color readingColor = Color(0xFFAD0A10);
    const Color defaultColor = Colors.black54;

    final fontSize =
        Provider.of<SettingsProvider>(context, listen: false).arabicFontSize;

    List<TextSpan> textSpans = [];
    for (int i = 0; i < wordTimings.length; i++) {
      Color color;
      if (i < currentWordIndex) {
        color = settingsProvider.appColor;
      } else if (i == currentWordIndex) {
        color = readingColor;
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
          ),
        ),
      );
    }
    return TextSpan(children: textSpans);
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bool isCurrent = prayerProvider.currentVerseIndex == index;

    final verseKey = 'آیه${verse.id}';
    final List<WordTiming>? currentWordTimings =
        prayerProvider.wordTimings[verseKey];

    Color cardColor;
    TextStyle arabicTextStyle;
    TextStyle translationTextStyle;

    if (isCurrent) {
      cardColor = Colors.grey.shade200;
      arabicTextStyle = TextStyle();
      translationTextStyle = TextStyle(
          fontFamily: 'Nabi',
          fontSize: settingsProvider.translationFontSize,
          color: const Color.fromARGB(255, 60, 59, 59));
    } else if (prayerProvider.currentVerseIndex > index) {
      cardColor = Colors.white;
      arabicTextStyle = TextStyle(
          fontFamily: 'Alhura',
          fontSize: settingsProvider.arabicFontSize,
          color: settingsProvider.appColor);
      translationTextStyle = TextStyle(
          fontFamily: 'Nabi',
          fontSize: settingsProvider.translationFontSize,
          color: Colors.grey.shade700);
    } else {
      cardColor = Colors.white;
      arabicTextStyle = TextStyle(
          fontFamily: 'Alhura',
          fontSize: settingsProvider.arabicFontSize,
          color: Colors.grey.shade700);
      translationTextStyle = TextStyle(
          fontFamily: 'Nabi',
          fontSize: settingsProvider.translationFontSize,
          color: Colors.grey.shade600);
    }

    return Card(
      elevation: isCurrent ? 4.0 : 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          prayerProvider.seek(Duration(milliseconds: verse.startTime));
          if (!prayerProvider.isPlaying) {
            prayerProvider.play();
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCurrent && currentWordTimings != null)
                RichText(
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  text: _buildListRichTextVerse(context, currentWordTimings,
                      prayerProvider.currentWordIndex),
                )
              else
                Text(
                  verse.arabic,
                  style: arabicTextStyle,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              const SizedBox(height: 12),
              Text(
                verse.translation,
                style: translationTextStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
