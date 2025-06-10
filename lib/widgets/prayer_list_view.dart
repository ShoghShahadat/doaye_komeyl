import 'package:flutter/material.dart';
import 'package:komeyl_app/providers/prayer_provider.dart';
import 'package:komeyl_app/widgets/verse_list_item.dart';
import 'package:provider/provider.dart';
// ١. import کردن پکیج جدید
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PrayerListView extends StatefulWidget {
  const PrayerListView({super.key});

  @override
  State<PrayerListView> createState() => _PrayerListViewState();
}

class _PrayerListViewState extends State<PrayerListView> {
  // ٢. ساخت کنترلر برای لیست جدید
  final ItemScrollController _itemScrollController = ItemScrollController();
  int _lastScrolledIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayerProvider, child) {
        if (prayerProvider.verses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // ٣. منطق اسکرول هوشمند
        // این کد چک می‌کند که آیا فراز تغییر کرده و آیا نیاز به اسکرول هست یا نه
        if (prayerProvider.currentVerseIndex != _lastScrolledIndex &&
            _itemScrollController.isAttached) {
          _lastScrolledIndex = prayerProvider.currentVerseIndex;

          // با کمی تاخیر اجرا می‌کنیم تا ویجت‌ها ساخته شده باشند
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _itemScrollController.scrollTo(
              index: prayerProvider.currentVerseIndex,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              // آیتم را در مرکز صفحه قرار می‌دهد
              alignment: 0.4,
            );
          });
        }

        // ٤. جایگزین کردن ListView.builder با ScrollablePositionedList.builder
        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          itemCount: prayerProvider.verses.length,
          itemBuilder: (context, index) {
            final verse = prayerProvider.verses[index];
            return VerseListItem(
              verse: verse,
              index: index,
            );
          },
        );
      },
    );
  }
}
