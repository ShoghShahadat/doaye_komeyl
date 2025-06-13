part of 'prayer_single_view.dart';

// این متدها به عنوان بخشی از _ModernPrayerSingleViewState عمل می‌کنند
extension _UIBuilders on _ModernPrayerSingleViewState {
  Widget _buildVerseContent(
    BuildContext context,
    PrayerProvider prayerProvider,
    SettingsProvider settingsProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(settingsProvider.backgroundOpacity * 0.9),
            Colors.white.withOpacity(settingsProvider.backgroundOpacity),
            Colors.white.withOpacity(settingsProvider.backgroundOpacity * 0.9),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: AnimatedSwitcher(
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
            child: _buildVerseColumn(
              context,
              prayerProvider,
              settingsProvider,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseColumn(
    BuildContext context,
    PrayerProvider prayerProvider,
    SettingsProvider settingsProvider,
  ) {
    final currentVerse =
        prayerProvider.verses[prayerProvider.currentVerseIndex];
    final verseKey = 'آیه${currentVerse.id}';
    final List<WordTiming>? currentWordTimings =
        prayerProvider.wordTimings[verseKey];

    return Column(
      key: ValueKey<String>(currentVerse.id),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVerseNumber(currentVerse, settingsProvider),
        const SizedBox(height: 32),
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
            currentWordTimings,
            prayerProvider,
            settingsProvider,
            currentVerse,
          ),
        ),
        const SizedBox(height: 40),
        _buildAnimatedDivider(settingsProvider),
        const SizedBox(height: 40),
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
                const Icon(
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
}
