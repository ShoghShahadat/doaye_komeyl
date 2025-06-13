import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:komeyl_app/screens/admin/preview_screen.dart';
import 'package:provider/provider.dart';
import 'widgets/app_bar.dart';
import 'widgets/bottom_panel_handler.dart';
import 'widgets/calibration_drawer.dart';
import 'widgets/editing_toolbar.dart';
import 'widgets/export_options_sheet.dart';
import 'widgets/player_controls.dart';
import 'widgets/text_display.dart';

class CalibrationScreen extends StatelessWidget {
  final CalibrationProject project;
  const CalibrationScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalibrationProvider(project: project),
      // از یک Builder استفاده می‌کنیم تا context جدیدی که شامل provider است را دریافت کنیم
      child: Builder(builder: (context) {
        // provider را اینجا یک بار می‌خوانیم تا در متدها از آن استفاده کنیم
        final provider = context.read<CalibrationProvider>();
        return Theme(
          data: _buildCustomTheme(context),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            autofocus: true,
            onKey: (event) => _handleKeyPress(event, provider),
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              drawer: CalibrationDrawer(provider: provider),
              appBar: CalibrationAppBar(provider: provider),
              body: SafeArea(
                child: Column(
                  children: [
                    PlayerControls(provider: provider),
                    const SizedBox(height: 8),
                    const ProfessionalEditingToolbar(),
                    const Expanded(
                      child: TextDisplay(),
                    ),
                    const BottomPanelHandler(),
                  ],
                ),
              ),
              floatingActionButton: _buildFloatingButtons(context),
            ),
          ),
        );
      }),
    );
  }

  ThemeData _buildCustomTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _handleKeyPress(RawKeyEvent event, CalibrationProvider provider) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (provider.audioPlayer.playing) {
          provider.audioPlayer.pause();
        } else {
          provider.audioPlayer.play();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        provider.recalibrateCurrent();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        provider.calibrateNext();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        provider.calibratePrevious();
      } else if (event.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyZ) {
        provider.undo();
      } else if (event.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyY) {
        provider.redo();
      }
    }
  }

  Widget _buildFloatingButtons(BuildContext context) {
    final provider = context.read<CalibrationProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'preview',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6C63FF),
          elevation: 4,
          onPressed: () => _showPreview(context, provider),
          child: const Icon(Icons.preview_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'export',
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[700],
          elevation: 4,
          onPressed: () => _showExportOptions(context, provider),
          child: const Icon(Icons.save_alt_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'calibrate',
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: provider.calibrateNext,
          child: const Icon(Icons.fiber_manual_record_rounded, size: 20),
        ),
      ],
    );
  }

  void _showPreview(BuildContext context, CalibrationProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          project: provider.project,
          timestamps: provider.timestamps.map((key, choices) {
            final chosen = choices.firstWhere(
              (c) => c.isChosen,
              orElse: () => choices.first,
            );
            return MapEntry(key, chosen.timestamp);
          }),
          linesOfWords: provider.arabicLinesOfWords,
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, CalibrationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider, // Pass the existing provider instance
        child: ExportOptionsSheet(provider: provider),
      ),
    );
  }
}
