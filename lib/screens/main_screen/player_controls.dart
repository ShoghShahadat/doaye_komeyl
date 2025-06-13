import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ModernPlayerControlsWidget extends StatefulWidget {
  const ModernPlayerControlsWidget({super.key});

  @override
  State<ModernPlayerControlsWidget> createState() =>
      _ModernPlayerControlsWidgetState();
}

class _ModernPlayerControlsWidgetState extends State<ModernPlayerControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _expandController;
  late AnimationController _pulseController;
  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _expandAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _expandController.forward();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _expandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // شرط مطمئن برای جلوگیری از خطای انیمیشن
    if (prayerProvider.isPlaying &&
        !_lottieController.isAnimating &&
        _lottieController.duration != null) {
      _lottieController.repeat();
    } else if (!prayerProvider.isPlaying && _lottieController.isAnimating) {
      _lottieController.reset();
    }

    return Visibility(
      visible: settingsProvider.showTimeline,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? 140 : 70,
                  child: Column(
                    children: [
                      _buildMainControls(
                          context, prayerProvider, settingsProvider),
                      if (_isExpanded)
                        _buildFullSlider(context, prayerProvider),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainControls(BuildContext context, PrayerProvider prayerProvider,
      SettingsProvider settingsProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildPlayPauseButton(prayerProvider),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(prayerProvider.currentPosition),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'از ${_formatDuration(prayerProvider.totalDuration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildModernProgressBar(prayerProvider),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (settingsProvider.showEqualizer)
            _buildEqualizer(settingsProvider, prayerProvider),
          _buildExpandButton(),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(PrayerProvider prayerProvider) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: prayerProvider.isPlaying ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (prayerProvider.isPlaying) {
                    prayerProvider.pause();
                  } else {
                    prayerProvider.play();
                  }
                },
                borderRadius: BorderRadius.circular(25),
                child: Icon(
                  prayerProvider.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernProgressBar(PrayerProvider prayerProvider) {
    final progress = prayerProvider.totalDuration.inMilliseconds > 0
        ? (prayerProvider.currentPosition.inMilliseconds /
                prayerProvider.totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizer(
      SettingsProvider settingsProvider, PrayerProvider prayerProvider) {
    return Visibility(
      visible: prayerProvider.isPlaying,
      child: SizedBox(
        width: 60,
        height: 40,
        child: Lottie.asset(
          'assets/lottie/equalizer.json',
          controller: _lottieController,
          onLoaded: (composition) {
            _lottieController.duration = composition.duration;
          },
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(
                const ['**'],
                value: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return IconButton(
      icon: AnimatedRotation(
        turns: _isExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 300),
        child: Icon(Icons.expand_more_rounded, color: Colors.grey[600]),
      ),
      onPressed: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
    );
  }

  Widget _buildFullSlider(BuildContext context, PrayerProvider prayerProvider) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              _formatDuration(prayerProvider.currentPosition),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: prayerProvider.currentPosition.inMilliseconds
                      .toDouble()
                      .clamp(
                          0.0,
                          prayerProvider.totalDuration.inMilliseconds
                              .toDouble()),
                  min: 0,
                  max: prayerProvider.totalDuration.inMilliseconds > 0
                      ? prayerProvider.totalDuration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    prayerProvider.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
            ),
            Text(
              _formatDuration(prayerProvider.totalDuration),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return d.toString().split('.').first.padLeft(8, "0");
    }
    return d.toString().split('.').first.padLeft(8, "0").substring(3);
  }
}
