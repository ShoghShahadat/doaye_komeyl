import 'dart:ui';
import 'package:flutter/material.dart';

/// AppBar سفارشی برای صفحه پیش‌نمایش
class PreviewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String projectTitle;
  final bool isAutoScroll;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onFullscreen;

  const PreviewAppBar({
    super.key,
    required this.projectTitle,
    required this.isAutoScroll,
    required this.onToggleAutoScroll,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            children: [
              Text(
                'پیش‌نمایش',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                projectTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isAutoScroll
                  ? Icons.sync_rounded
                  : Icons.sync_disabled_rounded),
              onPressed: onToggleAutoScroll,
              tooltip: 'اسکرول خودکار',
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded),
              onPressed: onFullscreen,
              tooltip: 'تمام صفحه',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
