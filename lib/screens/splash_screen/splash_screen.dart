import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'dart:math' as math;
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:komeyl_app/screens/main_screen/main_screen.dart';
import 'package:provider/provider.dart';

import 'painters/islamic_painters.dart';
import 'painters/particle_painter.dart';

part 'splash_screen_builders.dart';

class ModernSplashScreen extends StatefulWidget {
  const ModernSplashScreen({super.key});

  @override
  State<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<ModernSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _particleController;
  late AnimationController _transitionController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingFadeAnimation;
  late Animation<double> _transitionAnimation;

  final List<Particle> _particles = [];
  bool _isNavigating = false;

  StreamSubscription? _prayerProviderSubscription;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _startAnimationSequence();
    _requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prayerProviderSubscription == null) {
      final prayerProvider = context.read<PrayerProvider>();

      final List<Future> initializers = [
        Future.delayed(const Duration(seconds: 4)),
        if (!prayerProvider.isReady) prayerProvider.onReady.first,
      ];

      Future.wait(initializers).then((_) {
        _navigateToMainScreen();
      });
    }
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoRotateAnimation = Tween<double>(begin: -0.5, end: 0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic));
    _textFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _loadingFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _loadingController, curve: Curves.easeIn));
    _transitionAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _transitionController, curve: Curves.easeInOut));
  }

  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle());
    }
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _loadingController.forward();
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      await Permission.storage.request();
    }
  }

  void _navigateToMainScreen() async {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;

    await _transitionController.forward();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModernMainScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.1, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    _transitionController.dispose();
    _prayerProviderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _transitionAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1F9671),
                    Colors.white,
                    _transitionAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF2BA881),
                    Colors.white,
                    _transitionAnimation.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                _buildParticles(),
                _buildIslamicPatterns(),
                _buildMainContent(),
              ],
            ),
          );
        },
      ),
    );
  }
}
