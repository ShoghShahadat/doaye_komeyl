import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/verse_model.dart';
import 'package:komeyl_app/models/word_timing_model.dart'; // مدل جدید

class PrayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Verse> _verses = [];
  Map<String, List<WordTiming>> _wordTimings =
      {}; // برای نگهداری زمان‌بندی کلمات

  int _currentVerseIndex = -1;
  int _currentWordIndex = -1; // ایندکس کلمه فعلی

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  // Getters
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
    // بارگذاری همزمان هر دو فایل
    await Future.wait([
      _loadVerses(),
      _loadWordTimings(),
    ]);
    await _initAudioPlayer();
    _listenToPlayerState();
  }

  Future<void> _loadVerses() async {
    final String response = await rootBundle.loadString('assets/data/json.txt');
    final List<dynamic> data = json.decode(response);
    _verses = data.map((item) => Verse.fromJson(item)).toList();
  }

  // متد جدید برای بارگذاری زمان‌بندی کلمات
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
      final duration = await _audioPlayer.setAsset('assets/audio/alifani.mp3');
      _totalDuration = duration ?? Duration.zero;
    } catch (e) {
      print("Error loading audio source: $e");
    }

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _updateCurrentVerseAndWordIndex(position);
      notifyListeners(); // یکبار اطلاع‌رسانی در انتها کافیست
    });
  }

  void _listenToPlayerState() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  // متد آپدیت شده برای پیدا کردن فراز و کلمه فعلی
  void _updateCurrentVerseAndWordIndex(Duration position) {
    if (_verses.isEmpty) return;

    // پیدا کردن فراز فعلی
    final newVerseIndex = _verses
        .lastIndexWhere((verse) => verse.startTime <= position.inMilliseconds);
    if (newVerseIndex != _currentVerseIndex) {
      _currentVerseIndex = newVerseIndex;
      _currentWordIndex = -1; // با تغییر فراز، ایندکس کلمه ریست می‌شود
    }

    // پیدا کردن کلمه فعلی در فراز جاری
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
