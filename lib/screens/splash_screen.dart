import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:komeyl_app/screens/main_screen.dart';

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

  final List<_Particle> _particles = [];
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _startAnimationSequence();
    _checkPermissionsAndNavigate();
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

    _logoScaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotateAnimation = Tween<double>(
      begin: -0.5,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlideAnimation = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _loadingFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeIn,
    ));

    _transitionAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle());
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

  Future<void> _checkPermissionsAndNavigate() async {
    if (!kIsWeb) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }

    await Future.delayed(const Duration(seconds: 4));

    if (mounted && !_isNavigating) {
      _isNavigating = true;
      _transitionController.forward();
      await Future.delayed(const Duration(milliseconds: 300));

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModernMainScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.1,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    _transitionController.dispose();
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
                // پارتیکل‌های پس‌زمینه
                _buildParticles(),
                // نقش‌های اسلامی
                _buildIslamicPatterns(),
                // محتوای اصلی
                _buildMainContent(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildIslamicPatterns() {
    return Stack(
      children: [
        // نقش بالا راست
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _logoController.value * 0.5,
                child: Opacity(
                  opacity: 0.1 * _logoController.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: _buildIslamicStar(),
                  ),
                ),
              );
            },
          ),
        ),
        // نقش پایین چپ
        Positioned(
          bottom: -150,
          left: -150,
          child: AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_logoController.value * 0.3,
                child: Opacity(
                  opacity: 0.08 * _logoController.value,
                  child: Container(
                    width: 400,
                    height: 400,
                    child: _buildIslamicPattern(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // لوگو با انیمیشن
            AnimatedBuilder(
              animation: Listenable.merge([_logoController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _logoRotateAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // حلقه‌های تزئینی
                          ...List.generate(3, (index) {
                            return Container(
                              width: 140 - (index * 20),
                              height: 140 - (index * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1F9671)
                                      .withOpacity(0.2 - (index * 0.05)),
                                  width: 1,
                                ),
                              ),
                            );
                          }),
                          // تصویر لوگو
                          ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Image.asset(
                                'assets/images/baner.png',
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // عنوان اصلی
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _textSlideAnimation.value),
                    child: Column(
                      children: [
                        Text(
                          'دعای کمیل',
                          style: TextStyle(
                            fontFamily: 'Alhura',
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'با صدای استاد علیفانی',
                            style: TextStyle(
                              fontFamily: 'Nabi',
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Spacer(flex: 2),
            // بخش لودینگ
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingFadeAnimation.value,
                  child: Column(
                    children: [
                      // لودینگ سفارشی
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // حلقه چرخان بیرونی
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(seconds: 3),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 2 * math.pi,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      children: List.generate(8, (index) {
                                        return Transform.rotate(
                                          angle: index * math.pi / 4,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.8 - (index * 0.1),
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // انیمیشن لاتی
                            Lottie.asset(
                              'assets/lottie/lodingdot.json',
                              width: 80,
                              height: 80,
                              delegates: LottieDelegates(
                                values: [
                                  ValueDelegate.color(
                                    const ['**'],
                                    value: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Column(
                              children: [
                                Text(
                                  'در حال آماده‌سازی...',
                                  style: TextStyle(
                                    fontFamily: 'Nabi',
                                    fontSize: 18,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      Colors.white,
                                      Colors.white,
                                      Colors.white.withOpacity(0),
                                    ],
                                    stops: const [0, 0.3, 0.7, 1],
                                  ).createShader(bounds),
                                  child: const Text(
                                    '✦ التماس دعا ✦',
                                    style: TextStyle(
                                      fontFamily: 'Nabi',
                                      fontSize: 14,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildIslamicStar() {
    return CustomPaint(
      painter: _IslamicStarPainter(),
      size: const Size(300, 300),
    );
  }

  Widget _buildIslamicPattern() {
    return CustomPaint(
      painter: _IslamicPatternPainter(),
      size: const Size(400, 400),
    );
  }
}

// پارتیکل برای انیمیشن پس‌زمینه
class _Particle {
  late double x;
  late double y;
  late double speed;
  late double radius;
  late double opacity;

  _Particle() {
    final random = math.Random();
    x = random.nextDouble();
    y = random.nextDouble();
    speed = 0.1 + random.nextDouble() * 0.3;
    radius = 2 + random.nextDouble() * 4;
    opacity = 0.3 + random.nextDouble() * 0.5;
  }

  void update(double progress) {
    y = (y - speed * progress) % 1.0;
    if (y < 0) y = 1.0;
  }
}

// پینتر برای رسم پارتیکل‌ها
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var particle in particles) {
      particle.update(0.01);
      paint.color = Colors.white.withOpacity(particle.opacity * 0.5);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// پینتر برای رسم ستاره اسلامی
class _IslamicStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // رسم ستاره 8 پر
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi / 8) - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// پینتر برای رسم نقش اسلامی
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    // رسم دوایر متحدالمرکز
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(center, 40.0 + i * 30, paint);
    }

    // رسم خطوط شعاعی
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final start = center;
      final end = Offset(
        center.dx + 200 * math.cos(angle),
        center.dy + 200 * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
