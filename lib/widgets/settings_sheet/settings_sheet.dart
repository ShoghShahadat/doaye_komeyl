import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

part 'settings_sheet_builders.dart';
part 'settings_sheet_dialogs.dart';

class ModernSettingsSheet extends StatefulWidget {
  const ModernSettingsSheet({super.key});

  @override
  State<ModernSettingsSheet> createState() => _ModernSettingsSheetState();
}

class _ModernSettingsSheetState extends State<ModernSettingsSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late List<Animation<double>> _itemAnimations;

  static const int _itemCount = 7; // تعداد کل آیتم‌های انیمیشنی

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _itemAnimations = List.generate(_itemCount, (index) {
      const double staggerFraction = 0.08;
      const double itemDuration = 0.5;

      final double startTime = index * staggerFraction;
      final double endTime = (startTime + itemDuration).clamp(0.0, 1.0);

      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            startTime,
            endTime,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildSheetHandle(),
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAnimatedItem(
                        index: 0,
                        child: _buildColorSection(settingsProvider),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedItem(
                        index: 1,
                        child: _buildFontSizeSection(
                          'اندازه متن عربی',
                          settingsProvider.arabicFontSize,
                          (value) =>
                              settingsProvider.updateArabicFontSize(value),
                          Icons.text_fields_rounded,
                          16.0,
                          40.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedItem(
                        index: 2,
                        child: _buildFontSizeSection(
                          'اندازه متن ترجمه',
                          settingsProvider.translationFontSize,
                          (value) =>
                              settingsProvider.updateTranslationFontSize(value),
                          Icons.translate_rounded,
                          12.0,
                          30.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedItem(
                        index: 3,
                        child: _buildOpacitySection(settingsProvider),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedItem(
                        index: 4,
                        child: _buildSwitchSection(
                          'نمایش نوار زمان',
                          'کنترل پیشرفت پخش دعا',
                          Icons.timeline_rounded,
                          settingsProvider.showTimeline,
                          (value) => settingsProvider.updateShowTimeline(value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedItem(
                        index: 5,
                        child: _buildSwitchSection(
                          'نمایش اکولایزر',
                          'انیمیشن موج صوتی هنگام پخش',
                          Icons.equalizer_rounded,
                          settingsProvider.showEqualizer,
                          (value) =>
                              settingsProvider.updateShowEqualizer(value),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildAnimatedItem(
                        index: 6,
                        child: _buildResetButton(context, settingsProvider),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
