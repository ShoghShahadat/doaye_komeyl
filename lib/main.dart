import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/providers/settings_provider.dart';
import 'package:komeyl_app/screens/main_screen.dart';
import 'package:komeyl_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  // ١. Provider ها را در بالاترین سطح برنامه قرار می‌دهیم
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ٢. از Consumer برای گوش دادن به تغییرات رنگ استفاده می‌کنیم
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'دعای کمیل',
          debugShowCheckedModeBanner: false,
          // ٣. تم برنامه به صورت پویا و بر اساس رنگ انتخابی ساخته می‌شود
          theme: ThemeData(
            primaryColor: settings.appColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: settings.appColor,
              primary: settings.appColor,
              secondary: const Color(0xFF9AB275),
              brightness: Brightness.light,
            ),
            fontFamily: 'Nabi',
            useMaterial3: true,
          ),
          home: const ModernSplashScreen(),
        );
      },
    );
  }
}
