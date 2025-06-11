import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // ١. این import برای تشخیص پلتفرم وب اضافه شد
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:komeyl_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // ٢. کد درخواست مجوز اکنون درون یک شرط قرار گرفته است
    // این کد فقط روی پلتفرم‌های غیر وب (موبایل) اجرا می‌شود
    if (!kIsWeb) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }

    // کمی تاخیر برای نمایش صفحه اسپلش
    await Future.delayed(const Duration(seconds: 3));

    // انتقال به صفحه اصلی
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F9671),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset('assets/images/baner.png'),
            const Spacer(),
            Lottie.asset(
              'assets/lottie/lodingdot.json',
              width: 100,
              height: 100,
            ),
            const Text(
              '...التماس دعا',
              style: TextStyle(
                fontFamily: 'Nabi',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
