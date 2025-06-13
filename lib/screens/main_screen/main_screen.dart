import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:komeyl_app/widgets/export/app_drawer.dart';
import 'package:komeyl_app/widgets/export/prayer_list_view.dart';
import 'package:komeyl_app/widgets/export/prayer_single_view.dart';
import 'package:komeyl_app/widgets/export/settings_sheet.dart';
import 'package:provider/provider.dart';

import 'player_controls.dart';

part 'main_screen_builders.dart';

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

    _startAnimationsAfterBuild();
  }

  void _startAnimationsAfterBuild() {
    final prayerProvider = context.read<PrayerProvider>();

    void runAnimations() {
      if (mounted) {
        _appBarAnimationController.forward();
        _fabAnimationController.forward();
        _tabAnimationController.forward();
      }
    }

    if (prayerProvider.isReady) {
      runAnimations();
    } else {
      prayerProvider.onReady.first.then((_) => runAnimations());
    }
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
}
