part of 'verse_list_item.dart';

// این متدها به عنوان بخشی از _ModernVerseListItemState عمل می‌کنند
extension _UIBuilders on _ModernVerseListItemState {
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
            context, wordTimings, currentWordIndex, settingsProvider),
      );
    }

    Color textColor;
    if (isCurrent) {
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
        child: PlayingAnimation(color: settings.appColor),
      ),
    );
  }
}
