import 'dart:math' as math;
import 'package:flutter/material.dart';

/// کلاس مدل برای هر ذره در انیمیشن
class Particle {
  late double x, y, speed, radius, opacity;

  Particle() {
    final r = math.Random();
    x = r.nextDouble();
    y = r.nextDouble();
    speed = 0.1 + r.nextDouble() * 0.3;
    radius = 2 + r.nextDouble() * 4;
    opacity = 0.3 + r.nextDouble() * 0.5;
  }

  /// به‌روزرسانی موقعیت ذره بر اساس پیشرفت انیمیشن
  void update(double progress) {
    y = (y - speed * progress) % 1.0;
    if (y < 0) {
      y = 1.0;
    }
  }
}

/// نقاش برای رسم تمام ذرات روی صفحه
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var p in particles) {
      p.update(0.01);
      paint.color = Colors.white.withAlpha((255 * p.opacity * 0.5).round());
      canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
