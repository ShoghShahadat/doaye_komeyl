part of 'splash_screen.dart';

// این متدها به عنوان بخشی از _ModernSplashScreenState عمل می‌کنند
extension _SplashScreenUIBuilders on _ModernSplashScreenState {
  Widget _buildParticles() => AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => CustomPaint(
          painter: ParticlePainter(
              particles: _particles, progress: _particleController.value),
          size: Size.infinite));

  Widget _buildIslamicPatterns() => Stack(children: [
        Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) => Transform.rotate(
                    angle: _logoController.value * 0.5,
                    child: Opacity(
                        opacity: 0.1 * _logoController.value,
                        child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2)),
                            child: CustomPaint(
                                painter: IslamicStarPainter(),
                                size: const Size(300, 300))))))),
        Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) => Transform.rotate(
                    angle: -_logoController.value * 0.3,
                    child: Opacity(
                        opacity: 0.08 * _logoController.value,
                        child: SizedBox(
                            width: 400,
                            height: 400,
                            child: CustomPaint(
                                painter: IslamicPatternPainter(),
                                size: const Size(400, 400)))))))
      ]);

  Widget _buildMainContent() => SafeArea(
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            const Spacer(flex: 2),
            AnimatedBuilder(
                animation: Listenable.merge([_logoController]),
                builder: (context, child) => Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Transform.rotate(
                        angle: _logoRotateAnimation.value,
                        child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                                color: Colors.white.withAlpha(230),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15)),
                                  BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, -5))
                                ]),
                            child:
                                Stack(alignment: Alignment.center, children: [
                              ...List.generate(
                                  3,
                                  (index) => Container(
                                      width: 140 - (index * 20),
                                      height: 140 - (index * 20),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: const Color(0xFF1F9671)
                                                  .withAlpha((255 *
                                                          (0.2 -
                                                              (index * 0.05)))
                                                      .round()),
                                              width: 1)))),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(80),
                                  child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 5, sigmaY: 5),
                                      child: Image.asset(
                                          'assets/images/baner.png',
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.contain)))
                            ]))))),
            const SizedBox(height: 40),
            AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Column(children: [
                          const Text('دعای کمیل',
                              style: TextStyle(
                                  fontFamily: 'Alhura',
                                  fontSize: 48,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black38,
                                        blurRadius: 10,
                                        offset: Offset(0, 5))
                                  ])),
                          const SizedBox(height: 16),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withAlpha(77),
                                      width: 1)),
                              child: const Text('با صدای استاد علیفانی',
                                  style: TextStyle(
                                      fontFamily: 'Nabi',
                                      fontSize: 16,
                                      color: Colors.white,
                                      letterSpacing: 1)))
                        ])))),
            const Spacer(flex: 2),
            AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) => Opacity(
                    opacity: _loadingFadeAnimation.value,
                    child: Column(children: [
                      SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(alignment: Alignment.center, children: [
                            TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(seconds: 3),
                                builder: (context, value, child) => Transform.rotate(
                                    angle: value * 2 * math.pi,
                                    child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color:
                                                    Colors.white.withAlpha(77),
                                                width: 2)),
                                        child: Stack(
                                            children: List.generate(
                                                8,
                                                (index) => Transform.rotate(
                                                    angle: index * math.pi / 4,
                                                    child: Align(
                                                        alignment:
                                                            Alignment.topCenter,
                                                        child: Container(
                                                            width: 8,
                                                            height: 8,
                                                            margin: const EdgeInsets.only(top: 4),
                                                            decoration: BoxDecoration(color: Colors.white.withAlpha((255 * (0.8 - (index * 0.1))).round()), shape: BoxShape.circle))))))))),
                            Lottie.asset('assets/lottie/lodingdot.json',
                                width: 80,
                                height: 80,
                                delegates: LottieDelegates(values: [
                                  ValueDelegate.color(const ['**'],
                                      value: Colors.white)
                                ]))
                          ])),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Column(children: [
                                Text('در حال آماده‌سازی...',
                                    style: TextStyle(
                                        fontFamily: 'Nabi',
                                        fontSize: 18,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                        shadows: [
                                          Shadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2))
                                        ])),
                                const SizedBox(height: 8),
                                ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(colors: [
                                          Colors.transparent,
                                          Colors.white,
                                          Colors.white,
                                          Colors.transparent
                                        ], stops: [
                                          0,
                                          0.3,
                                          0.7,
                                          1
                                        ]).createShader(bounds),
                                    child: const Text('✦ التماس دعا ✦',
                                        style: TextStyle(
                                            fontFamily: 'Nabi',
                                            fontSize: 14,
                                            color: Colors.white,
                                            letterSpacing: 2)))
                              ])))
                    ]))),
            const SizedBox(height: 60)
          ])));
}
