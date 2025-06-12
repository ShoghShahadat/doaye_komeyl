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
  final bool isVisible;

  const ModernVerseListItem({
    super.key,
    required this.verse,
    required this.index,
    this.isVisible = true,
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
      duration: const Duration(milliseconds: 300),
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

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bool isCurrent = prayerProvider.currentVerseIndex == widget.index;
    final bool isPassed = prayerProvider.currentVerseIndex > widget.index;

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
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: isCurrent ? 12.0 : 16.0,
                  vertical: isCurrent ? 12.0 : 8.0,
                ),
                transform: Matrix4.identity()
                  ..scale(_isPressed ? 0.98 : 1.0)
                  ..translate(0.0, isCurrent ? -2.0 : 0.0),
                child: Stack(
                  children: [
                    // کارت اصلی
                    _buildMainCard(
                      context,
                      isCurrent,
                      isPassed,
                      settingsProvider,
                      currentWordTimings,
                      prayerProvider.currentWordIndex,
                    ),
                    // اورلی گرادیان برای حالت فعلی
                    if (isCurrent) _buildActiveOverlay(context),
                    // شماره آیه
                    _buildVerseNumber(context, isCurrent, isPassed),
                    // نشانگر پخش
                    if (isCurrent) _buildPlayingIndicator(context),
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
    bool isPassed,
    SettingsProvider settingsProvider,
    List<WordTiming>? wordTimings,
    int currentWordIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.white
            : isPassed
                ? Colors.white.withOpacity(0.95)
                : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: settingsProvider.appColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isCurrent
              ? settingsProvider.appColor.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(isCurrent ? 24.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // متن عربی
                _buildArabicText(
                  context,
                  isCurrent,
                  isPassed,
                  settingsProvider,
                  wordTimings,
                  currentWordIndex,
                ),
                const SizedBox(height: 20),
                // خط جداکننده زیبا
                _buildDivider(context, isCurrent, settingsProvider),
                const SizedBox(height: 20),
                // ترجمه فارسی
                _buildTranslationText(
                  context,
                  isCurrent,
                  isPassed,
                  settingsProvider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArabicText(
    BuildContext context,
    bool isCurrent,
    bool isPassed,
    SettingsProvider settingsProvider,
    List<WordTiming>? wordTimings,
    int currentWordIndex,
  ) {
    if (isCurrent && wordTimings != null) {
      return RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: _buildRichTextVerse(
          context,
          wordTimings,
          currentWordIndex,
          settingsProvider,
        ),
      );
    }

    return Text(
      widget.verse.arabic,
      style: TextStyle(
        fontFamily: 'Alhura',
        fontSize: settingsProvider.arabicFontSize,
        color: isPassed
            ? settingsProvider.appColor.withOpacity(0.9)
            : Colors.grey.shade700,
        height: 1.8,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildTranslationText(
    BuildContext context,
    bool isCurrent,
    bool isPassed,
    SettingsProvider settingsProvider,
  ) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontFamily: 'Nabi',
        fontSize: isCurrent
            ? settingsProvider.translationFontSize + 1
            : settingsProvider.translationFontSize,
        color: isCurrent
            ? Colors.grey.shade800
            : isPassed
                ? Colors.grey.shade700
                : Colors.grey.shade600,
        height: 1.6,
      ),
      child: Text(
        widget.verse.translation,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDivider(
    BuildContext context,
    bool isCurrent,
    SettingsProvider settingsProvider,
  ) {
    return Center(
      child: Container(
        width: isCurrent ? 80 : 60,
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCurrent
                ? [
                    Colors.transparent,
                    settingsProvider.appColor,
                    Colors.transparent,
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

  Widget _buildActiveOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Provider.of<SettingsProvider>(context).appColor.withOpacity(0.05),
              Colors.transparent,
              Provider.of<SettingsProvider>(context).appColor.withOpacity(0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseNumber(
      BuildContext context, bool isCurrent, bool isPassed) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Positioned(
      top: 12,
      right: 12,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? settingsProvider.appColor
              : isPassed
                  ? settingsProvider.appColor.withOpacity(0.1)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: settingsProvider.appColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'آیه',
              style: TextStyle(
                fontFamily: 'Nabi',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrent
                    ? Colors.white
                    : isPassed
                        ? settingsProvider.appColor
                        : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.verse.id,
              style: TextStyle(
                fontFamily: 'Nabi',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCurrent
                    ? Colors.white
                    : isPassed
                        ? settingsProvider.appColor
                        : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingIndicator(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _PlayingAnimation(
          color: Provider.of<SettingsProvider>(context).appColor,
        ),
      ),
    );
  }

  TextSpan _buildRichTextVerse(
    BuildContext context,
    List<WordTiming> wordTimings,
    int currentWordIndex,
    SettingsProvider settingsProvider,
  ) {
    final Color readColor = settingsProvider.appColor;
    const Color readingColor =
        Color(0xFFE91E63); // رنگ صورتی زیبا برای کلمه در حال خواندن
    const Color specialWordColor = Color(0xFF1F9671);
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
        fontSize += 2;
        fontWeight = FontWeight.bold;
        shadows = [
          Shadow(
            blurRadius: 12.0,
            color: readingColor.withOpacity(0.3),
            offset: const Offset(0, 2),
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

  void _handleTap(PrayerProvider prayerProvider) {
    HapticFeedback.lightImpact();
    prayerProvider.seek(Duration(milliseconds: widget.verse.startTime));
    if (!prayerProvider.isPlaying) {
      prayerProvider.play();
    }
  }
}

// انیمیشن زیبا برای نشان دادن پخش
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
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(
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
          children: List.generate(3, (index) {
            return Container(
              width: 3,
              height: 12 * _animations[index].value,
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
