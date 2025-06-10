import 'package:flutter/material.dart';

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
