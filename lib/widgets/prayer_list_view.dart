import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/widgets/verse_list_item.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PrayerListView extends StatefulWidget {
  const PrayerListView({super.key});

  @override
  State<PrayerListView> createState() => _PrayerListViewState();
}

class _PrayerListViewState extends State<PrayerListView>
    with TickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _lastScrolledIndex = -1;
  late AnimationController _fabAnimationController;
  late AnimationController _progressAnimationController;
  bool _showScrollButtons = false;
  int _visibleItemIndex = 0;

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

    // Listen to scroll position
    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final firstVisibleIndex = positions
            .where((position) => position.itemLeadingEdge < 1)
            .reduce((min, position) =>
                position.itemLeadingEdge < min.itemLeadingEdge ? position : min)
            .index;

        setState(() {
          _visibleItemIndex = firstVisibleIndex;
          _showScrollButtons = firstVisibleIndex > 2;
        });

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
    return Consumer<PrayerProvider>(
      builder: (context, prayerProvider, child) {
        if (prayerProvider.verses.isEmpty) {
          return const _LoadingView();
        }

        // Smart scrolling logic
        if (prayerProvider.currentVerseIndex != _lastScrolledIndex &&
            _itemScrollController.isAttached) {
          _lastScrolledIndex = prayerProvider.currentVerseIndex;
          _progressAnimationController.forward(from: 0);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _itemScrollController.scrollTo(
              index: prayerProvider.currentVerseIndex,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              alignment: 0.4,
            );
          });
        }

        return Stack(
          children: [
            // Background decoration
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
            // Main list
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
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 30)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: ModernVerseListItem(
                    verse: verse,
                    index: index,
                    isVisible: index >= _visibleItemIndex - 1 &&
                        index <= _visibleItemIndex + 5,
                  ),
                );
              },
            ),
            // Progress indicator
            _buildProgressIndicator(prayerProvider),
            // Floating action buttons
            _buildFloatingButtons(prayerProvider),
          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator(PrayerProvider prayerProvider) {
    final progress =
        prayerProvider.currentVerseIndex / (prayerProvider.verses.length - 1);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _progressAnimationController,
        builder: (context, child) {
          return Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingButtons(PrayerProvider prayerProvider) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scroll to current button
          ScaleTransition(
            scale: _fabAnimationController,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.small(
                heroTag: 'scrollToCurrent',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_itemScrollController.isAttached) {
                    _itemScrollController.scrollTo(
                      index: prayerProvider.currentVerseIndex,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      alignment: 0.4,
                    );
                  }
                },
                backgroundColor: Colors.white,
                elevation: 4,
                child: Icon(
                  Icons.my_location_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          // Scroll to top button
          ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              heroTag: 'scrollToTop',
              onPressed: () {
                HapticFeedback.lightImpact();
                if (_itemScrollController.isAttached) {
                  _itemScrollController.scrollTo(
                    index: 0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Loading View Widget
class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'در حال بارگذاری...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Nabi',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'صبر کنید تا نور معنویت بدرخشد',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontFamily: 'Nabi',
            ),
          ),
        ],
      ),
    );
  }
}
