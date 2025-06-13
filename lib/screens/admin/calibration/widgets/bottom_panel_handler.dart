import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/calibration_provider.dart';
import 'package:provider/provider.dart';
import 'panels/conflict_resolution_panel.dart';
import 'panels/fine_tune_panel.dart';
import 'panels/range_selection_panel.dart';

/// این ویجت هوشمند، پنل مناسب پایینی را بر اساس وضعیت برنامه نمایش می‌دهد.
class BottomPanelHandler extends StatelessWidget {
  const BottomPanelHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();
    final selectedKey = provider.selectedWordKey;
    final bool hasConflict = selectedKey != null &&
        provider.timestamps.containsKey(selectedKey) &&
        provider.timestamps[selectedKey]!.length > 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _getBottomPanelHeight(provider, hasConflict),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _selectBottomPanel(provider, hasConflict),
      ),
    );
  }

  double _getBottomPanelHeight(CalibrationProvider provider, bool hasConflict) {
    if (hasConflict) return 220; // ارتفاع بیشتر برای پنل تداخل
    if (provider.isRangeSelectionMode) return 90;
    if (provider.selectedWordKey != null) return 160;
    return 0;
  }

  Widget _selectBottomPanel(CalibrationProvider provider, bool hasConflict) {
    if (hasConflict) {
      return const ConflictResolutionPanel(key: ValueKey('conflict'));
    }
    if (provider.isRangeSelectionMode) {
      return const RangeSelectionPanel(key: ValueKey('range'));
    }
    if (provider.selectedWordKey != null) {
      return const FineTunePanel(key: ValueKey('finetune'));
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}
