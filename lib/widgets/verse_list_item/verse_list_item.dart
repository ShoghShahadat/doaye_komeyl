import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'playing_animation.dart';

// اعلام می‌کند که فایل‌های زیر، بخشی از این فایل هستند
part 'verse_list_item_builders.dart';
part 'verse_list_item_rich_text.dart';

class ModernVerseListItem extends StatefulWidget {
  final Verse verse;
  final int index;

  const ModernVerseListItem({
    super.key,
    required this.verse,
    required this.index,
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
                  clipBehavior: Clip.none,
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
}
