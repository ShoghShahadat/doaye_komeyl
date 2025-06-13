import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/widgets/export/verse_list_item.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'loading_view.dart';

part 'prayer_list_view_builders.dart';

class PrayerListView extends StatefulWidget {
  const PrayerListView({super.key});

  @override
  State<PrayerListView> createState() => _PrayerListViewState();
}

class _PrayerListViewState extends State<PrayerListView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _lastScrolledIndex = -1;
  late AnimationController _fabAnimationController;
  late AnimationController _progressAnimationController;
  bool _showScrollButtons = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _itemPositionsListener.itemPositions.addListener(() {
      if (!mounted) return;
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final firstVisibleIndex = positions
            .where((position) => position.itemLeadingEdge < 1)
            .reduce((min, position) =>
                position.itemLeadingEdge < min.itemLeadingEdge ? position : min)
            .index;

        if (mounted) {
          setState(() {
            _showScrollButtons = firstVisibleIndex > 2;
          });
        }

        if (_showScrollButtons && !_fabAnimationController.isCompleted) {
          _fabAnimationController.forward();
        } else if (!_showScrollButtons && _fabAnimationController.isCompleted) {
          _fabAnimationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<PrayerProvider>(
      builder: (context, prayerProvider, child) {
        if (prayerProvider.verses.isEmpty) {
          return const LoadingView(); // استفاده از کامپوننت جدید
        }

        if (prayerProvider.currentVerseIndex != _lastScrolledIndex &&
            _itemScrollController.isAttached) {
          _lastScrolledIndex = prayerProvider.currentVerseIndex;
          _progressAnimationController.forward(from: 0);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_itemScrollController.isAttached) {
              _itemScrollController.scrollTo(
                index: prayerProvider.currentVerseIndex,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
                alignment: 0.4,
              );
            }
          });
        }

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.03),
                    Colors.white,
                  ],
                ),
              ),
            ),
            ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 100,
                left: 8,
                right: 8,
              ),
              itemCount: prayerProvider.verses.length,
              itemBuilder: (context, index) {
                final verse = prayerProvider.verses[index];
                return ModernVerseListItem(
                  key: ValueKey(verse.id),
                  verse: verse,
                  index: index,
                );
              },
            ),
            _buildProgressIndicator(prayerProvider),
            _buildFloatingButtons(prayerProvider),
          ],
        );
      },
    );
  }
}
