import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:komeyl_app/screens/admin/project_list_screen.dart';
import 'package:provider/provider.dart';

part 'app_drawer_builders.dart';
part 'app_drawer_actions.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final Color appColor = settingsProvider.appColor;

    return Drawer(
      backgroundColor: const Color(0xFFFAFAFA),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              appColor.withOpacity(0.03),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildModernHeader(appColor),
            const SizedBox(height: 8),
            _buildAnimatedMenuItem(
              index: 0,
              icon: Icons.home_rounded,
              title: 'صفحه اصلی',
              subtitle: 'بازگشت به دعا',
              color: appColor,
              onTap: () => Navigator.pop(context),
            ),
            _buildAnimatedMenuItem(
              index: 1,
              icon: Icons.tune_rounded,
              title: 'پنل کالیبراسیون',
              subtitle: 'مدیریت پروژه‌ها',
              color: Colors.deepOrange,
              isSpecial: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ProjectListScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _buildAnimatedMenuItem(
              index: 2,
              icon: Icons.info_outline_rounded,
              title: 'درباره ما',
              subtitle: 'اطلاعات برنامه',
              color: Colors.blue,
              onTap: () => _showAboutDialog(context, appColor),
            ),
            _buildAnimatedMenuItem(
              index: 3,
              icon: Icons.share_rounded,
              title: 'اشتراک‌گذاری',
              subtitle: 'معرفی به دوستان',
              color: Colors.purple,
              onTap: () => _shareApp(context, appColor),
            ),
            const SizedBox(height: 24),
            _buildBottomSection(appColor),
          ],
        ),
      ),
    );
  }
}
