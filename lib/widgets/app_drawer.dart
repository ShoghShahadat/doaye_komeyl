import 'package:flutter/material.dart';
import 'package:komeyl_app/screens/admin/project_list_screen.dart'; // import صفحه جدید

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/baner.png', height: 60),
                const SizedBox(height: 10),
                const Text(
                  'دعای کمیل',
                  style: TextStyle(
                      color: Colors.white, fontSize: 24, fontFamily: 'Nabi'),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('صفحه اصلی'),
            onTap: () {
              Navigator.pop(context); // بستن منو
            },
          ),
          const Divider(),
          // گزینه جدید برای ورود به پنل
          ListTile(
            leading: const Icon(Icons.tune_rounded, color: Colors.deepOrange),
            title: const Text('پنل کالیبراسیون',
                style: TextStyle(color: Colors.deepOrange)),
            onTap: () {
              Navigator.pop(context); // ابتدا منو را ببند
              Navigator.of(context).push(
                // سپس به صفحه لیست پروژه‌ها برو
                MaterialPageRoute(
                    builder: (context) => const ProjectListScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('درباره ما'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('اشتراک گذاری'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
