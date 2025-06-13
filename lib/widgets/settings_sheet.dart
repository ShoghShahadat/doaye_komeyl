import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

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

  // --- شروع اصلاحات: افزایش تعداد آیتم‌ها برای انیمیشن ---
  // تعداد آیتم‌ها از 7 به 9 افزایش یافت (دو اسلایدر جدید)
  static const int _itemCount = 9;
  // --- پایان اصلاحات ---

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
          height: MediaQuery.of(context).size.height * 0.9, // کمی افزایش ارتفاع
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

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'تنظیمات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
          child: Opacity(
            opacity: _itemAnimations[index].value,
            child: child,
          ),
        );
      },
    );
  }

  // --- شروع اصلاحات: بازسازی بخش رنگ ---
  Widget _buildColorSection(SettingsProvider settingsProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            settingsProvider.appColor.withOpacity(0.1),
            settingsProvider.appColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: settingsProvider.appColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_rounded,
                color: settingsProvider.appColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'رنگ اصلی برنامه',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // اسلایدر فام رنگ (Hue)
          _buildColorSlider(
            trackType: TrackType.hue,
            settingsProvider: settingsProvider,
          ),
          const SizedBox(height: 12),
          // اسلایدر غلظت رنگ (Saturation)
          _buildColorSlider(
            trackType: TrackType.saturation,
            settingsProvider: settingsProvider,
          ),
          const SizedBox(height: 12),
          // اسلایدر روشنایی (Value/Brightness)
          _buildColorSlider(
            trackType: TrackType.value,
            settingsProvider: settingsProvider,
          ),
          const SizedBox(height: 16),
          _buildColorPresets(settingsProvider),
        ],
      ),
    );
  }

  Widget _buildColorSlider({
    required TrackType trackType,
    required SettingsProvider settingsProvider,
  }) {
    String label;
    switch (trackType) {
      case TrackType.hue:
        label = 'فام رنگ';
        break;
      case TrackType.saturation:
        label = 'غلظت';
        break;
      case TrackType.value:
        label = 'روشنایی';
        break;
      default:
        label = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorPickerSlider(
              trackType,
              HSVColor.fromColor(settingsProvider.appColor),
              (HSVColor color) {
                HapticFeedback.lightImpact();
                settingsProvider.updateAppColor(color.toColor());
              },
              displayThumbColor: true,
              fullThumbColor: true,
            ),
          ),
        ),
      ],
    );
  }
  // --- پایان اصلاحات ---

  Widget _buildColorPresets(SettingsProvider settingsProvider) {
    final List<Color> presetColors = [
      const Color(0xFF1F9671), // رنگ پیش‌فرض
      const Color(0xFF2196F3), // آبی
      const Color(0xFF9C27B0), // بنفش
      const Color(0xFFE91E63), // صورتی
      const Color(0xFFFF9800), // نارنجی
      const Color(0xFF4CAF50), // سبز
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: presetColors.map((color) {
        final isSelected = settingsProvider.appColor.value == color.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            settingsProvider.updateAppColor(color);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 36 : 32,
            height: isSelected ? 36 : 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontSizeSection(
    String title,
    double value,
    Function(double) onChanged,
    IconData icon,
    double min,
    double max,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.round().toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                max.round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpacitySection(SettingsProvider settingsProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.purple[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.opacity_rounded, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شفافیت پس‌زمینه',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تنظیم میزان شفافیت در نمای تک صفحه',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(settingsProvider.backgroundOpacity * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[400]!,
                    ],
                  ),
                ),
              ),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white
                      .withOpacity(settingsProvider.backgroundOpacity),
                ),
                child: Center(
                  child: Text(
                    'پیش‌نمایش',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue[700],
              inactiveTrackColor: Colors.blue[200],
              thumbColor: Colors.blue[700],
              overlayColor: Colors.blue.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: settingsProvider.backgroundOpacity,
              min: 0.5,
              max: 1.0,
              divisions: 50,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                settingsProvider.updateBackgroundOpacity(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSection(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: value
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: value
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: value,
                    onChanged: (newValue) {
                      HapticFeedback.lightImpact();
                      onChanged(newValue);
                    },
                    activeColor: Theme.of(context).primaryColor,
                    trackColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).primaryColor.withOpacity(0.5);
                      }
                      return Colors.grey[300];
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(
      BuildContext context, SettingsProvider settingsProvider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.red[50]!,
            Colors.orange[50]!,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showResetDialog(context, settingsProvider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restore_rounded,
                  color: Colors.red[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'بازگشت به تنظیمات پیش‌فرض',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(width: 12),
              const Text('بازگشت به پیش‌فرض'),
            ],
          ),
          content: const Text(
            'آیا از بازگشت تمام تنظیمات به حالت پیش‌فرض اطمینان دارید؟',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                settingsProvider.updateAppColor(const Color(0xFF1F9671));
                settingsProvider.updateArabicFontSize(22.0);
                settingsProvider.updateTranslationFontSize(16.0);
                settingsProvider.updateShowTimeline(true);
                settingsProvider.updateBackgroundOpacity(0.95);
                settingsProvider.updateShowEqualizer(true);

                Navigator.pop(dialogContext);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تنظیمات به حالت پیش‌فرض بازگشت'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('تایید'),
            ),
          ],
        ),
      ),
    );
  }
}
