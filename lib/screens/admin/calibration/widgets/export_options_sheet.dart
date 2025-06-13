import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:share_plus/share_plus.dart';

/// شیت پایینی برای نمایش گزینه‌های خروجی گرفتن از پروژه
class ExportOptionsSheet extends StatelessWidget {
  final CalibrationProvider provider;
  const ExportOptionsSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'انتخاب نوع خروجی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildExportOption(
            context,
            icon: Icons.code_rounded,
            title: 'فایل JSON',
            subtitle: 'خروجی زمان‌بندی کلمات',
            color: Colors.blue,
            onTap: () => _exportJSON(context),
          ),
          _buildExportOption(
            context,
            icon: Icons.archive_rounded,
            title: 'بسته کامل ZIP',
            subtitle: 'شامل صوت، متن و زمان‌بندی',
            color: Colors.green,
            onTap: () => _exportZIP(context),
          ),
          _buildExportOption(
            context,
            icon: Icons.share_rounded,
            title: 'اشتراک‌گذاری',
            subtitle: 'ارسال فایل به دیگران',
            color: Colors.orange,
            onTap: () => _shareFiles(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportJSON(BuildContext context) async {
    final jsonString = provider.exportTimestampsToJson();
    final bytes = jsonString.codeUnits;

    await FileSaver.instance.saveFile(
      name: '${provider.project.title}_calibration',
      bytes: Uint8List.fromList(bytes),
      ext: 'json',
      mimeType: MimeType.json,
    );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فایل JSON با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _exportZIP(BuildContext context) async {
    final zipData = await provider.packageProjectAsZip();
    if (zipData != null) {
      await FileSaver.instance.saveFile(
        name: '${provider.project.title}_package',
        bytes: zipData,
        ext: 'zip',
        mimeType: MimeType.zip,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بسته ZIP با موفقیت ذخیره شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _shareFiles(BuildContext context) async {
    final jsonString = provider.exportTimestampsToJson();
    await Share.share(
      jsonString,
      subject: 'کالیبراسیون ${provider.project.title}',
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
