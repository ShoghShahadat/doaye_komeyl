import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';

/// منوی کشویی اختصاصی برای صفحه کالیبراسیون
class CalibrationDrawer extends StatelessWidget {
  final CalibrationProvider provider;
  const CalibrationDrawer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF5753C9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.project.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'پروژه کالیبراسیون',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.audiotrack_rounded,
              title: 'فایل صوتی',
              subtitle: _getFileName(provider.project.audioPath),
              color: Colors.purple,
            ),
            _buildDrawerItem(
              icon: Icons.text_fields_rounded,
              title: 'فایل متن اصلی',
              subtitle: _getFileName(provider.project.mainTextPath),
              color: Colors.blue,
            ),
            if (provider.project.translationTextPath != null)
              _buildDrawerItem(
                icon: Icons.translate_rounded,
                title: 'فایل ترجمه',
                subtitle: _getFileName(provider.project.translationTextPath!),
                color: Colors.green,
              ),
            const Divider(height: 32),
            _buildDrawerItem(
              icon: Icons.sync_alt_rounded,
              title: 'حالت پردازش متن',
              subtitle: provider.project.textParsingMode == 'interleaved'
                  ? 'ترکیبی (عربی و ترجمه)'
                  : 'مجزا',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'میانبرهای صفحه‌کلید',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutItem('Space', 'پخش/توقف'),
                  _buildShortcutItem('Enter', 'ثبت زمان کلمه فعلی'),
                  _buildShortcutItem('→', 'کلمه بعدی'),
                  _buildShortcutItem('←', 'کلمه قبلی'),
                  _buildShortcutItem('Ctrl+Z', 'Undo'),
                  _buildShortcutItem('Ctrl+Y', 'Redo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
    );
  }

  Widget _buildShortcutItem(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
