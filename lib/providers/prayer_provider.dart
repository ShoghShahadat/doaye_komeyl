import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/verse_model.dart';
// --- شروع اصلاحات: رفع خطای تایپی در آدرس‌دهی ---
import 'package:komeyl_app/models/word_timing_model.dart';
// --- پایان اصلاحات ---

class PrayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Verse> _verses = [];
  Map<String, List<WordTiming>> _wordTimings = {};

  int _currentVerseIndex = -1;
  int _currentWordIndex = -1;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  // --- شروع اصلاحات: افزودن مکانیزم Stream برای اعلام آمادگی ---
  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get onReady => _readyController.stream;
  bool _isReady = false;
  bool get isReady => _isReady;
  // --- پایان اصلاحات ---

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
      _initAudioPlayer(),
    ]);

    _listenToPlayerState();

    _isReady = true;
    // به همه اطلاع می‌دهیم که Provider آماده است
    if (!_readyController.isClosed) {
      _readyController.add(true);
    }
    notifyListeners();
  }

  Future<void> _loadVerses() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/json.txt');
      final List<dynamic> data = json.decode(response);
      _verses = data.map((item) => Verse.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error loading verses: $e");
      _verses = [];
    }
  }

  Future<void> _loadWordTimings() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/klm.json');
      final Map<String, dynamic> data = json.decode(response);
      _wordTimings = data.map((key, value) {
        final List<dynamic> wordList = value;
        return MapEntry(
          key,
          wordList.map((item) => WordTiming.fromJson(item)).toList(),
        );
      });
    } catch (e) {
      debugPrint("Error loading word timings: $e");
      _wordTimings = {};
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      if (kIsWeb) {
        final duration =
            await _audioPlayer.setUrl('assets/assets/audio/alifani.mp3');
        _totalDuration = duration ?? Duration.zero;
      } else {
        final duration =
            await _audioPlayer.setAsset('assets/audio/alifani.mp3');
        _totalDuration = duration ?? Duration.zero;
      }
    } catch (e) {
      debugPrint("Error loading audio source: $e");
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
    _readyController.close();
    super.dispose();
  }
}
