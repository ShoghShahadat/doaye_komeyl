import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ModernVerseListItem extends StatefulWidget {
  final Verse verse;
  final int index;
  // ١. حذف پراپرتی غیر ضروری isVisible
  // final bool isVisible;

  const ModernVerseListItem({
    // ٢. افزودن کلید شناسایی (Key) برای پایداری بیشتر در لیست
    super.key,
    required this.verse,
    required this.index,
    // this.isVisible = true,
  });

  @override
  State<ModernVerseListItem> createState() => _ModernVerseListItemState();
}

class _ModernVerseListItemState extends State<ModernVerseListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // ٣. اجرای بدون قید و شرط انیمیشن
    // هر زمان که ویجت ساخته شود، انیمیشن آن اجرا می‌شود.
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(PrayerProvider prayerProvider) {
    HapticFeedback.lightImpact();
    prayerProvider.seek(Duration(milliseconds: widget.verse.startTime));
    if (!prayerProvider.isPlaying) {
      prayerProvider.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bool isCurrent = prayerProvider.currentVerseIndex == widget.index;

    final verseKey = 'آیه${widget.verse.id}';
    final List<WordTiming>? currentWordTimings =
        prayerProvider.wordTimings[verseKey];

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () => _handleTap(prayerProvider),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(
                  horizontal: isCurrent ? 12.0 : 16.0,
                  vertical: isCurrent ? 12.0 : 8.0,
                ),
                transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
                child: Stack(
                  clipBehavior: Clip.none, // اجازه می‌دهد سایه بیرون بزند
                  children: [
                    _buildMainCard(context, isCurrent, settingsProvider,
                        currentWordTimings, prayerProvider.currentWordIndex),
                    if (isCurrent)
                      _buildActiveOverlay(context, settingsProvider),
                    _buildVerseNumber(context, isCurrent, settingsProvider),
                    if (isCurrent && prayerProvider.isPlaying)
                      _buildPlayingIndicator(context, settingsProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    bool isCurrent,
    SettingsProvider settingsProvider,
    List<WordTiming>? wordTimings,
    int currentWordIndex,
  ) {
    final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
    final bool isPassed = prayerProvider.currentVerseIndex > widget.index;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: settingsProvider.appColor.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isCurrent
              ? settingsProvider.appColor.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, isCurrent ? 32 : 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildArabicText(context, isCurrent, isPassed, settingsProvider,
                  wordTimings, currentWordIndex),
              const SizedBox(height: 16),
              _buildDivider(context, isCurrent, settingsProvider),
              const SizedBox(height: 16),
              _buildTranslationText(
                  context, isCurrent, isPassed, settingsProvider),
            ],
          ),
        ),
      ),
    );
  }

  // --- کد اصلاح‌شده و بدون باگ برای نمایش متن عربی ---
  Widget _buildArabicText(
    BuildContext context,
    bool isCurrent,
    bool isPassed,
    SettingsProvider settingsProvider,
    List<WordTiming>? wordTimings,
    int currentWordIndex,
  ) {
    // اگر آیتم فعلی است و زمان‌بندی کلمات را دارد، RichText را نمایش بده
    if (isCurrent && wordTimings != null) {
      return RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: _buildRichTextVerse(
            context, wordTimings, currentWordIndex, settingsProvider),
      );
    }

    // در غیر این صورت، از Text ساده با استایل‌دهی کامل و بدون باگ استفاده کن
    Color textColor;
    if (isCurrent) {
      // این حالت fallback برای زمانی است که isCurrent=true اما wordTimings=null
      textColor = Colors.black87;
    } else if (isPassed) {
      textColor = settingsProvider.appColor;
    } else {
      textColor = Colors.grey.shade600;
    }

    return Text(
      widget.verse.arabic,
      style: TextStyle(
        fontFamily: 'Alhura',
        fontSize: settingsProvider.arabicFontSize,
        color: textColor,
        height: 1.8,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildTranslationText(BuildContext context, bool isCurrent,
      bool isPassed, SettingsProvider settingsProvider) {
    Color textColor;
    if (isCurrent) {
      textColor = Colors.black;
    } else if (isPassed) {
      textColor = Colors.grey.shade700;
    } else {
      textColor = Colors.grey.shade500;
    }

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontFamily: 'Nabi',
        fontSize: settingsProvider.translationFontSize,
        color: textColor,
        height: 1.6,
        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
      ),
      child: Text(
        widget.verse.translation,
        textAlign: TextAlign.center,
      ),
    );
  }

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

  // --- ویجت‌های کمکی برای زیبایی بیشتر ---

  Widget _buildDivider(
      BuildContext context, bool isCurrent, SettingsProvider settingsProvider) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isCurrent ? 80 : 60,
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCurrent
                ? [
                    settingsProvider.appColor.withOpacity(0.1),
                    settingsProvider.appColor.withOpacity(0.8),
                    settingsProvider.appColor.withOpacity(0.1),
                  ]
                : [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildActiveOverlay(BuildContext context, SettingsProvider settings) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                settings.appColor.withOpacity(0.1),
                Colors.white.withOpacity(0),
                settings.appColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseNumber(
      BuildContext context, bool isCurrent, SettingsProvider settings) {
    final bool isPassed =
        Provider.of<PrayerProvider>(context, listen: false).currentVerseIndex >
            widget.index;

    return Positioned(
      top: -10,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? settings.appColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isCurrent
                  ? settings.appColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isCurrent
              ? null
              : Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Text(
          'آیه ${widget.verse.id}',
          style: TextStyle(
            fontFamily: 'Nabi',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isCurrent ? Colors.white : settings.appColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayingIndicator(
      BuildContext context, SettingsProvider settings) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _PlayingAnimation(color: settings.appColor),
      ),
    );
  }
}

class _PlayingAnimation extends StatefulWidget {
  final Color color;
  const _PlayingAnimation({required this.color});

  @override
  State<_PlayingAnimation> createState() => _PlayingAnimationState();
}

class _PlayingAnimationState extends State<_PlayingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (index) {
            return Container(
              width: 3,
              height: 4 + (8 * _animations[index].value),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
