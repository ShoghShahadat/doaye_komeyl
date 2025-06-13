part of 'prayer_list_view.dart';

// این متدها به عنوان بخشی از _PrayerListViewState عمل می‌کنند
extension _PrayerListViewBuilders on _PrayerListViewState {
  Widget _buildProgressIndicator(PrayerProvider prayerProvider) {
    if (prayerProvider.verses.isEmpty) return const SizedBox.shrink();
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
