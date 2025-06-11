import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; // برای تشخیص پلتفرم وب
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart';

class PrayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Verse> _verses = [];
  Map<String, List<WordTiming>> _wordTimings = {};

  int _currentVerseIndex = -1;
  int _currentWordIndex = -1;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  // Getter ها بدون تغییر
  List<Verse> get verses => _verses;
  Map<String, List<WordTiming>> get wordTimings => _wordTimings;
  int get currentVerseIndex => _currentVerseIndex;
  int get currentWordIndex => _currentWordIndex;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  AudioPlayer get audioPlayer => _audioPlayer;

  PrayerProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadVerses(),
      _loadWordTimings(),
    ]);
    await _initAudioPlayer();
    _listenToPlayerState();
  }

  // این متدها بدون تغییر هستند
  Future<void> _loadVerses() async {
    final String response = await rootBundle.loadString('assets/data/json.txt');
    final List<dynamic> data = json.decode(response);
    _verses = data.map((item) => Verse.fromJson(item)).toList();
  }

  Future<void> _loadWordTimings() async {
    final String response = await rootBundle.loadString('assets/data/klm.json');
    final Map<String, dynamic> data = json.decode(response);
    _wordTimings = data.map((key, value) {
      final List<dynamic> wordList = value;
      return MapEntry(
        key,
        wordList.map((item) => WordTiming.fromJson(item)).toList(),
      );
    });
  }

  Future<void> _initAudioPlayer() async {
    try {
      // --- این بخش به طور کامل بازنویسی شده است ---
      // برای هر پلتفرم، روش بارگذاری متفاوتی را انتخاب می‌کنیم
      if (kIsWeb) {
        // در وب، از URL استریم می‌کنیم تا بلافاصله پخش شود.
        // آدرس دارایی‌های محلی در وب به این شکل است.
        final duration =
            await _audioPlayer.setUrl('assets/assets/audio/alifani.mp3');
        _totalDuration = duration ?? Duration.zero;
      } else {
        // در موبایل (اندروید/iOS)، از setAsset استفاده می‌کنیم که بهینه‌تر است.
        final duration =
            await _audioPlayer.setAsset('assets/audio/alifani.mp3');
        _totalDuration = duration ?? Duration.zero;
      }
      // --- پایان تغییرات ---
    } catch (e) {
      print("Error loading audio source: $e");
    }

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _updateCurrentVerseAndWordIndex(position);
      notifyListeners();
    });
  }

  void _listenToPlayerState() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  void _updateCurrentVerseAndWordIndex(Duration position) {
    if (_verses.isEmpty) return;

    final newVerseIndex = _verses
        .lastIndexWhere((verse) => verse.startTime <= position.inMilliseconds);
    if (newVerseIndex != _currentVerseIndex) {
      _currentVerseIndex = newVerseIndex;
      _currentWordIndex = -1;
    }

    if (_currentVerseIndex != -1) {
      final verseKey = 'آیه${_verses[_currentVerseIndex].id}';
      final timings = _wordTimings[verseKey];
      if (timings != null) {
        final newWordIndex = timings.lastIndexWhere(
            (word) => word.startTime <= position.inMilliseconds);
        if (newWordIndex != _currentWordIndex) {
          _currentWordIndex = newWordIndex;
        }
      }
    }
  }

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void seek(Duration position) => _audioPlayer.seek(position);

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
