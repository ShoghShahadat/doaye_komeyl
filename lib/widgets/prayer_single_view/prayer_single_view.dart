import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:komeyl_app/models/word_timing_model.dart';
import 'package:provider/provider.dart';
import 'background_video.dart';
import 'loading_view.dart';

part 'prayer_single_view_builders.dart';
part 'prayer_single_view_rich_text.dart';

class ModernPrayerSingleView extends StatefulWidget {
  const ModernPrayerSingleView({super.key});

  @override
  State<ModernPrayerSingleView> createState() => _ModernPrayerSingleViewState();
}

class _ModernPrayerSingleViewState extends State<ModernPrayerSingleView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (prayerProvider.verses.isEmpty ||
        prayerProvider.currentVerseIndex == -1) {
      return const SingleViewLoading();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const SingleViewBackgroundVideo(),
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),
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
                  ),
                ),
              ),
            );
          },
        ),
        _buildDecorations(context, settingsProvider),
      ],
    );
  }
}
