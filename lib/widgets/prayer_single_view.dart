import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class ModernPrayerSingleView extends StatefulWidget {
  const ModernPrayerSingleView({super.key});

  @override
  State<ModernPrayerSingleView> createState() => _ModernPrayerSingleViewState();
}

class _ModernPrayerSingleViewState extends State<ModernPrayerSingleView>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (prayerProvider.verses.isEmpty ||
        prayerProvider.currentVerseIndex == -1) {
      return const _ModernLoadingView();
    }

    final currentVerse =
        prayerProvider.verses[prayerProvider.currentVerseIndex];
    final verseKey = 'آیه${currentVerse.id}';
    final List<WordTiming>? currentWordTimings =
        prayerProvider.wordTimings[verseKey];

    return Stack(
      fit: StackFit.expand,
      children: [
        // ویدیو پس‌زمینه
        const _ModernBackgroundVideo(),

        // افکت blur
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),

        // محتوای اصلی
        AnimatedBuilder(
          animation: Listenable.merge([
            _slideController,
            _fadeController,
            _scaleController,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildVerseContent(
                    context,
                    prayerProvider,
                    settingsProvider,
                    currentVerse,
                    currentWordTimings,
                  ),
                ),
              ),
            );
          },
        ),

        // دکوریشن‌های تزئینی
        _buildDecorations(context, settingsProvider),
      ],
    );
  }

  Widget _buildVerseContent(
    BuildContext context,
    PrayerProvider prayerProvider,
    SettingsProvider settingsProvider,
    Verse currentVerse,
    List<WordTiming>? wordTimings,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>(currentVerse.id),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white
                  .withOpacity(settingsProvider.backgroundOpacity * 0.9),
              Colors.white.withOpacity(settingsProvider.backgroundOpacity),
              Colors.white
                  .withOpacity(settingsProvider.backgroundOpacity * 0.9),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شماره آیه با طراحی زیبا
                _buildVerseNumber(currentVerse, settingsProvider),
                const SizedBox(height: 32),

                // کانتینر متن عربی
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: settingsProvider.appColor.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildArabicText(
                    wordTimings,
                    prayerProvider,
                    settingsProvider,
                    currentVerse,
                  ),
                ),

                const SizedBox(height: 40),

                // خط جداکننده انیمیشنی
                _buildAnimatedDivider(settingsProvider),

                const SizedBox(height: 40),

                // کانتینر ترجمه
                Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        settingsProvider.appColor.withOpacity(0.05),
                        settingsProvider.appColor.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: settingsProvider.appColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    currentVerse.translation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nabi',
                      fontSize: settingsProvider.translationFontSize,
                      color: Colors.grey.shade800,
                      height: 2.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseNumber(Verse verse, SettingsProvider settingsProvider) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  settingsProvider.appColor,
                  settingsProvider.appColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: settingsProvider.appColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'آیه ${verse.id}',
                  style: const TextStyle(
                    fontFamily: 'Nabi',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArabicText(
    List<WordTiming>? wordTimings,
    PrayerProvider prayerProvider,
    SettingsProvider settingsProvider,
    Verse currentVerse,
  ) {
    if (wordTimings != null) {
      return RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: _buildRichTextVerse(
          settingsProvider,
          wordTimings,
          prayerProvider.currentWordIndex,
          settingsProvider.arabicFontSize,
        ),
      );
    } else {
      return Text(
        currentVerse.arabic,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Alhura',
          fontSize: settingsProvider.arabicFontSize,
          color: Colors.grey.shade800,
          height: 2.2,
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAnimatedDivider(SettingsProvider settingsProvider) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50 * value,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    settingsProvider.appColor.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.rotate(
                angle: value * 3.14159,
                child: Icon(
                  Icons.star,
                  size: 24,
                  color: settingsProvider.appColor.withOpacity(0.5),
                ),
              ),
            ),
            Container(
              width: 50 * value,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    settingsProvider.appColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDecorations(
      BuildContext context, SettingsProvider settingsProvider) {
    return Stack(
      children: [
        // دایره تزئینی بالا راست
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  settingsProvider.appColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // دایره تزئینی پایین چپ
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  settingsProvider.appColor.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

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

// ویو لودینگ مدرن
class _ModernLoadingView extends StatefulWidget {
  const _ModernLoadingView();

  @override
  State<_ModernLoadingView> createState() => _ModernLoadingViewState();
}

class _ModernLoadingViewState extends State<_ModernLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.5),
                ],
                transform: GradientRotation(_controller.value * 2 * 3.14159),
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.mosque,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ویدیو پس‌زمینه مدرن
class _ModernBackgroundVideo extends StatefulWidget {
  const _ModernBackgroundVideo();

  @override
  State<_ModernBackgroundVideo> createState() => _ModernBackgroundVideoState();
}

class _ModernBackgroundVideoState extends State<_ModernBackgroundVideo> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/video.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return AnimatedOpacity(
        duration: const Duration(seconds: 2),
        opacity: _isInitialized ? 1.0 : 0.0,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
      ),
    );
  }
}
