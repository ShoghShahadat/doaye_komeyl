import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:komeyl_app/widgets/app_drawer.dart';
import 'package:komeyl_app/widgets/prayer_list_view.dart';
import 'package:komeyl_app/widgets/prayer_single_view.dart';
import 'package:komeyl_app/widgets/settings_sheet.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ModernMainScreen extends StatefulWidget {
  const ModernMainScreen({super.key});

  @override
  State<ModernMainScreen> createState() => _ModernMainScreenState();
}

class _ModernMainScreenState extends State<ModernMainScreen>
    with TickerProviderStateMixin {
  late AnimationController _appBarAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _appBarAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _tabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _appBarAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _tabSlideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeOutBack,
    ));

    // --- شروع اصلاحات: اجرای انیمیشن‌ها پس از ساخت اولین فریم برای جلوگیری از لگ ---
    final prayerProvider = context.read<PrayerProvider>();

    void runAnimationsAfterBuild() {
      // این تضمین می‌کند که فریم اولیه رندر شده و سپس انیمیشن‌های سنگین شروع می‌شوند.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startAnimations();
        }
      });
    }

    if (prayerProvider.isReady) {
      runAnimationsAfterBuild();
    } else {
      // منتظر می‌مانیم تا Provider آماده شود.
      prayerProvider.onReady.first.then((_) {
        if (mounted) {
          runAnimationsAfterBuild();
        }
      });
    }
    // --- پایان اصلاحات ---
  }

  void _startAnimations() {
    _appBarAnimationController.forward();
    _fabAnimationController.forward();
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _appBarAnimationController.dispose();
    _fabAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    // نمایش یک Loading Indicator تا زمانی که Provider آماده شود
    if (!prayerProvider.isReady) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
            ),
            Column(
              children: [
                AnimatedBuilder(
                  animation: _appBarAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _appBarAnimation.value),
                      child: _buildModernAppBar(context),
                    );
                  },
                ),
                const ModernPlayerControlsWidget(),
                AnimatedBuilder(
                  animation: _tabSlideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _tabSlideAnimation.value),
                      child: _buildModernTabBar(context),
                    );
                  },
                ),
                const Expanded(
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      PrayerListView(),
                      ModernPrayerSingleView(),
                    ],
                  ),
                ),
              ],
            ),
            _buildFloatingSettingsButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Scaffold.of(context).openDrawer();
                },
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.7),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'د',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Alhura',
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دعای کمیل',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alhura',
                          ),
                        ),
                        Text(
                          'با صدای استاد علیفانی',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'Nabi',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontFamily: 'Nabi',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Nabi',
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        splashBorderRadius: BorderRadius.circular(25),
        tabs: const [
          Tab(text: 'نمای لیست'),
          Tab(text: 'نمای تک صفحه'),
        ],
      ),
    );
  }

  Widget _buildFloatingSettingsButton(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return FloatingActionButton(
              heroTag: 'settings',
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 8,
              onPressed: () {
                HapticFeedback.mediumImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return ChangeNotifierProvider.value(
                      value: settings,
                      child: const ModernSettingsSheet(),
                    );
                  },
                );
              },
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

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

    // --- شروع اصلاحات: شرط مطمئن برای جلوگیری از خطای انیمیشن ---
    if (prayerProvider.isPlaying &&
        !_lottieController.isAnimating &&
        _lottieController.duration != null) {
      _lottieController.repeat();
    } else if (!prayerProvider.isPlaying && _lottieController.isAnimating) {
      _lottieController.reset();
    }
    // --- پایان اصلاحات ---

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
                      Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: prayerProvider.isPlaying
                                      ? _pulseAnimation.value
                                      : 1.0,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.3),
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _formatDuration(
                                            prayerProvider.currentPosition),
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
                              Visibility(
                                visible: prayerProvider.isPlaying,
                                child: SizedBox(
                                  width: 60,
                                  height: 40,
                                  child: Lottie.asset(
                                    'assets/lottie/equalizer.json',
                                    controller: _lottieController,
                                    onLoaded: (composition) {
                                      _lottieController.duration =
                                          composition.duration;
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
                              ),
                            IconButton(
                              icon: AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  color: Colors.grey[600],
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_isExpanded)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(
                                      prayerProvider.currentPosition),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor:
                                          Theme.of(context).primaryColor,
                                      inactiveTrackColor: Colors.grey[300],
                                      thumbColor:
                                          Theme.of(context).primaryColor,
                                      overlayColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2),
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 16),
                                    ),
                                    child: Slider(
                                      value: prayerProvider
                                          .currentPosition.inMilliseconds
                                          .toDouble()
                                          .clamp(
                                              0.0,
                                              prayerProvider
                                                  .totalDuration.inMilliseconds
                                                  .toDouble()),
                                      min: 0,
                                      max: prayerProvider.totalDuration
                                                  .inMilliseconds >
                                              0
                                          ? prayerProvider
                                              .totalDuration.inMilliseconds
                                              .toDouble()
                                          : 1.0,
                                      onChanged: (value) {
                                        prayerProvider.seek(Duration(
                                            milliseconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(prayerProvider.totalDuration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
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
