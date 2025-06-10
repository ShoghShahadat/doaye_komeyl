import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'تنظیمات',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('رنگ اصلی برنامه'),
                ),
                SizedBox(
                  height: 50,
                  child: ColorPickerSlider(
                    TrackType.hue,
                    HSVColor.fromColor(settingsProvider.appColor),
                    (HSVColor color) {
                      settingsProvider.updateAppColor(color.toColor());
                    },
                  ),
                ),
                const Divider(),
                _buildSliderTile(
                  label: 'اندازه متن عربی',
                  value: settingsProvider.arabicFontSize,
                  onChanged: (newSize) =>
                      settingsProvider.updateArabicFontSize(newSize),
                  min: 16.0,
                  max: 40.0,
                ),
                const Divider(),
                _buildSliderTile(
                  label: 'اندازه متن ترجمه',
                  value: settingsProvider.translationFontSize,
                  onChanged: (newSize) =>
                      settingsProvider.updateTranslationFontSize(newSize),
                  min: 12.0,
                  max: 30.0,
                ),
                const Divider(),
                _buildSliderTile(
                  label: 'شفافیت پس‌زمینه (نمای تنها)',
                  value: settingsProvider.backgroundOpacity,
                  onChanged: (newOpacity) =>
                      settingsProvider.updateBackgroundOpacity(newOpacity),
                  min: 0.5,
                  max: 1,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('نمایش نوار زمان'),
                  value: settingsProvider.showTimeline,
                  onChanged: (isVisible) =>
                      settingsProvider.updateShowTimeline(isVisible),
                ),
                SwitchListTile(
                  title: const Text('نمایش اکولایزر'),
                  value: settingsProvider.showEqualizer,
                  onChanged: (isVisible) =>
                      settingsProvider.updateShowEqualizer(isVisible),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required Function(double) onChanged,
    double min = 10.0,
    double max = 40.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(label),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round() * 10,
          label: (min == 0.0)
              ? value.toStringAsFixed(1)
              : value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
