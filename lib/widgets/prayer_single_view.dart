import 'package:flutter/material.dart';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart'; // import جدید
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PrayerSingleView extends StatelessWidget {
  const PrayerSingleView({super.key});

  @override
  Widget build(BuildContext context) {
    // هر دو Provider را یکجا میخوانیم
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (prayerProvider.verses.isEmpty ||
        prayerProvider.currentVerseIndex == -1) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentVerse =
        prayerProvider.verses[prayerProvider.currentVerseIndex];
    final verseKey = 'آیه${currentVerse.id}';
    final List<WordTiming>? currentWordTimings =
        prayerProvider.wordTimings[verseKey];

    return Stack(
      fit: StackFit.expand,
      children: [
        const _BackgroundVideo(),
        _buildVerseContent(context, prayerProvider, settingsProvider,
            currentVerse, currentWordTimings),
      ],
    );
  }

  Widget _buildVerseContent(
      BuildContext context,
      PrayerProvider prayerProvider,
      SettingsProvider settingsProvider,
      Verse currentVerse,
      List<WordTiming>? wordTimings) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>(currentVerse.id),
        padding: const EdgeInsets.all(24.0),
        color: const Color.fromARGB(255, 255, 255, 255)
            .withOpacity(settingsProvider.backgroundOpacity),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (wordTimings != null)
              RichText(
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                text: _buildRichTextVerse(
                    settingsProvider,
                    wordTimings,
                    prayerProvider.currentWordIndex,
                    settingsProvider.arabicFontSize),
              )
            else
              Text(
                currentVerse.arabic,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Alhura',
                    fontSize: settingsProvider.arabicFontSize,
                    color: Colors.white),
              ),
            const SizedBox(height: 20),
            Text(
              currentVerse.translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nabi',
                  fontSize: settingsProvider.translationFontSize,
                  color: const Color.fromARGB(255, 60, 59, 59)),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildRichTextVerse(SettingsProvider settingsProvider,
      List<WordTiming> wordTimings, int currentWordIndex, double fontSize) {
    final Color readColor = settingsProvider.appColor;
    const Color readingColor = Color(0xFFAD0A10);
    const Color specialWordColor = Color(0xFF1F9671);
    const Color defaultColor = Color.fromARGB(255, 139, 139, 139);

    final List<String> specialWords = ["رَبِّ", "اِلهى", "اَللّهُمَّ"];

    List<TextSpan> textSpans = [];
    for (int i = 0; i < wordTimings.length; i++) {
      Color color;
      if (i < currentWordIndex) {
        color = specialWords.contains(wordTimings[i].text)
            ? specialWordColor
            : readColor;
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
            // shadows: const [
            //   Shadow(
            //       blurRadius: 8.0,
            //       color: Colors.black54,
            //       offset: Offset(2, 2))
            // ]
          ),
        ),
      );
    }
    return TextSpan(children: textSpans);
  }
}

class _BackgroundVideo extends StatefulWidget {
  const _BackgroundVideo();
  @override
  State<_BackgroundVideo> createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<_BackgroundVideo> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/video.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    }
    return Container(color: Colors.black);
  }
}
