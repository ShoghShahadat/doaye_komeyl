import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:komeyl_app/widgets/app_drawer.dart';
import 'package:komeyl_app/widgets/prayer_list_view.dart';
import 'package:komeyl_app/widgets/prayer_single_view.dart';
import 'package:komeyl_app/widgets/settings_sheet.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(
            'دعای کمیل',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Nabi',
              fontSize: 22,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 4.0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return ChangeNotifierProvider.value(
                          value: settings,
                          child: const SettingsSheet(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontFamily: 'Nabi', fontSize: 16),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'لیستی'),
              Tab(text: 'متن تنها'),
            ],
          ),
        ),
        body: const Column(
          children: [
            PlayerControlsWidget(),
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  PrayerListView(),
                  PrayerSingleView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerControlsWidget extends StatefulWidget {
  const PlayerControlsWidget({super.key});

  @override
  State<PlayerControlsWidget> createState() => _PlayerControlsWidgetState();
}

class _PlayerControlsWidgetState extends State<PlayerControlsWidget>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // منطق جدید کنترل انیمیشن
    if (prayerProvider.isPlaying && !_lottieController.isAnimating) {
      _lottieController.repeat();
    } else if (!prayerProvider.isPlaying && _lottieController.isAnimating) {
      // ٤. از reset() استفاده می‌کنیم تا انیمیشن متوقف و به فریم اول بازگردد
      _lottieController.reset();
    }

    String formatDuration(Duration d) {
      if (d.inHours > 0) return d.toString().split('.').first.padLeft(8, "0");
      return d.toString().split('.').first.padLeft(8, "0").substring(3);
    }

    final sliderMax = prayerProvider.totalDuration.inMilliseconds.toDouble();
    final sliderValue = prayerProvider.currentPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, sliderMax);

    return Visibility(
      visible: settingsProvider.showTimeline,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        color: Theme.of(context).primaryColor.withOpacity(0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(formatDuration(prayerProvider.currentPosition),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: sliderValue,
                      min: 0.0,
                      max: sliderMax > 0 ? sliderMax : 1.0,
                      onChanged: (value) {
                        prayerProvider
                            .seek(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: Color.lerp(
                          settingsProvider.appColor, Colors.black, 0.3),
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  Text(formatDuration(prayerProvider.totalDuration),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      prayerProvider.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    onPressed: () {
                      prayerProvider.isPlaying
                          ? prayerProvider.pause()
                          : prayerProvider.play();
                    },
                  ),
                  Align(
                    alignment: const Alignment(0.6, 0.0),
                    child: Visibility(
                      // ٣. ویجت Visibility دیگر به isPlaying وابسته نیست
                      visible: settingsProvider.showEqualizer,
                      child: Lottie.asset(
                        'assets/lottie/equalizer.json',
                        width: 250, // ٢. اندازه به مقدار مناسب تغییر کرد
                        height: 80,
                        controller: _lottieController,
                        onLoaded: (composition) {
                          _lottieController.duration = composition.duration;
                        },
                        delegates: LottieDelegates(
                          values: [
                            ValueDelegate.color(
                              // در اینجا '**' به این معنی است که تمام لایه‌ها و اَشکال را هدف قرار می‌دهیم
                              // شما می‌توانید برای هدف قرار دادن یک لایه یا شکل خاص، نام آن را مشخص کنید
                              const ['**'],
                              value: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
