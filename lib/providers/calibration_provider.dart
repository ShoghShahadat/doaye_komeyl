import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart'; // import پکیج جدید

class CalibrationProvider with ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  final CalibrationProject project;

  List<List<String>> _linesOfWords = [];
  Map<String, int> _timestamps = {};
  String? _selectedWordKey;

  // --- State برای انتخاب گروهی ---
  bool _isRangeSelectionMode = false;
  String? _rangeStartKey;
  String? _rangeEndKey;

  // --- State برای Undo/Redo ---
  List<Map<String, int>> _undoStack = [];
  List<Map<String, int>> _redoStack = [];

  // --- Getters ---
  List<List<String>> get linesOfWords => _linesOfWords;
  Map<String, int> get timestamps => _timestamps;
  String? get selectedWordKey => _selectedWordKey;
  bool get isRangeSelectionMode => _isRangeSelectionMode;
  String? get rangeStartKey => _rangeStartKey;
  String? get rangeEndKey => _rangeEndKey;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  CalibrationProvider({required this.project}) {
    _init();
  }

  Future<void> _init() async {
    await _loadTextFromFile();
    await _loadState(); // بارگذاری کل وضعیت، شامل تاریخچه
    await audioPlayer.setFilePath(project.audioPath);
  }

  Future<Uint8List?> packageProjectAsZip() async {
    try {
      final archive = Archive();

      // ١. افزودن فایل JSON کالیبراسیون
      final jsonString = exportTimestampsToJson();
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(
          ArchiveFile('calibration.json', jsonBytes.length, jsonBytes));

      // ٢. افزودن فایل صوتی
      final audioFile = File(project.audioPath);
      if (await audioFile.exists()) {
        final audioBytes = await audioFile.readAsBytes();
        archive
            .addFile(ArchiveFile('audio.mp3', audioBytes.length, audioBytes));
      }

      // ٣. افزودن فایل متنی
      final textFile = File(project.textPath);
      if (await textFile.exists()) {
        final textBytes = await textFile.readAsBytes();
        archive.addFile(ArchiveFile('text.txt', textBytes.length, textBytes));
      }

      // ٤. فشرده‌سازی و بازگرداندن بایت‌های فایل zip
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      return zipData != null ? Uint8List.fromList(zipData) : null;
    } catch (e) {
      print('Error packaging project: $e');
      return null;
    }
  }

  // --- مدیریت تاریخچه (Undo/Redo) ---
  void _saveSnapshot() {
    _undoStack.add(Map<String, int>.from(_timestamps));
    _redoStack.clear(); // هر تغییر جدید، تاریخچه Redo را پاک می‌کند
    if (_undoStack.length > 30) {
      // محدود کردن تاریخچه برای جلوگیری از مصرف زیاد حافظه
      _undoStack.removeAt(0);
    }
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(Map<String, int>.from(_timestamps));
    _timestamps = _undoStack.removeLast();
    _saveState();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(Map<String, int>.from(_timestamps));
    _timestamps = _redoStack.removeLast();
    _saveState();
    notifyListeners();
  }

  // --- ذخیره و بارگذاری کل وضعیت (شامل تاریخچه) ---
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = {
      'timestamps': _timestamps,
      'undoStack': _undoStack,
      'redoStack': _redoStack,
    };
    final String jsonState = json.encode(state);
    await prefs.setString('state_${project.id}', jsonState);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonState = prefs.getString('state_${project.id}');
    if (jsonState != null) {
      final decodedState = json.decode(jsonState) as Map<String, dynamic>;
      _timestamps = Map<String, int>.from(decodedState['timestamps']
          .map((key, value) => MapEntry(key, int.parse(value.toString()))));
      _undoStack = (decodedState['undoStack'] as List)
          .map((item) => Map<String, int>.from(item
              .map((key, value) => MapEntry(key, int.parse(value.toString())))))
          .toList();
      _redoStack = (decodedState['redoStack'] as List)
          .map((item) => Map<String, int>.from(item
              .map((key, value) => MapEntry(key, int.parse(value.toString())))))
          .toList();
      notifyListeners();
    }
  }

  // --- متدهای کالیبراسیون که اکنون از سیستم تاریخچه استفاده می‌کنند ---
  void assignTimestamp(int lineIndex, int wordIndex) {
    _saveSnapshot();
    final key = '$lineIndex-$wordIndex';
    _timestamps[key] = audioPlayer.position.inMilliseconds;
    _saveState();
    notifyListeners();
  }

  void nudgeTimestamp(int milliseconds) {
    if (_selectedWordKey == null) return;
    _saveSnapshot();
    _timestamps[_selectedWordKey!] =
        (_timestamps[_selectedWordKey]! + milliseconds)
            .clamp(0, audioPlayer.duration?.inMilliseconds ?? 0);
    _saveState();
    notifyListeners();
  }

  void deleteSelectedTimestamp() {
    if (_selectedWordKey == null) return;
    _saveSnapshot();
    _timestamps.remove(_selectedWordKey);
    _selectedWordKey = null;
    _saveState();
    notifyListeners();
  }

  // --- منطق انتخاب گروهی ---
  void toggleRangeSelectionMode() {
    _isRangeSelectionMode = !_isRangeSelectionMode;
    _rangeStartKey = null;
    _rangeEndKey = null;
    _selectedWordKey = null; // از حالت انتخاب تکی خارج شو
    notifyListeners();
  }

  void setRangeMarker(int lineIndex, int wordIndex) {
    final key = '$lineIndex-$wordIndex';
    if (_rangeStartKey == null ||
        (_rangeStartKey != null && _rangeEndKey != null)) {
      _rangeStartKey = key;
      _rangeEndKey = null;
    } else {
      // اطمینان از اینکه نقطه پایان بعد از نقطه شروع است
      final startParts = _rangeStartKey!.split('-').map(int.parse).toList();
      if (lineIndex > startParts[0] ||
          (lineIndex == startParts[0] && wordIndex > startParts[1])) {
        _rangeEndKey = key;
      } else {
        // اگر کاربر نقطه پایان را قبل از شروع انتخاب کرد، آن را به عنوان شروع جدید در نظر بگیر
        _rangeStartKey = key;
        _rangeEndKey = null;
      }
    }
    notifyListeners();
  }

  void deleteTimestampsInRange() {
    if (_rangeStartKey == null || _rangeEndKey == null) return;
    _saveSnapshot();

    final startParts = _rangeStartKey!.split('-').map(int.parse).toList();
    final endParts = _rangeEndKey!.split('-').map(int.parse).toList();

    List<String> keysToRemove = [];
    _timestamps.forEach((key, value) {
      final keyParts = key.split('-').map(int.parse).toList();
      bool isAfterStart = keyParts[0] > startParts[0] ||
          (keyParts[0] == startParts[0] && keyParts[1] >= startParts[1]);
      bool isBeforeEnd = keyParts[0] < endParts[0] ||
          (keyParts[0] == endParts[0] && keyParts[1] <= endParts[1]);
      if (isAfterStart && isBeforeEnd) {
        keysToRemove.add(key);
      }
    });

    for (var key in keysToRemove) {
      _timestamps.remove(key);
    }

    toggleRangeSelectionMode(); // خروج از حالت انتخاب گروهی پس از حذف
    _saveState();
    notifyListeners();
  }

  Future<void> _loadTextFromFile() async {
    try {
      final file = File(project.textPath);
      final String fullText = await file.readAsString();
      final List<String> lines = fullText.split('\n');
      _linesOfWords = lines
          .map((line) => line.trim().split(' '))
          .where((words) => words.isNotEmpty && words.first != '')
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error reading text file: $e');
    }
  }

  Future<void> _saveTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonMap = json.encode(
        _timestamps.map((key, value) => MapEntry(key, value.toString())));
    await prefs.setString('timestamps_${project.id}', jsonMap);
  }

  Future<void> _loadTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonMap = prefs.getString('timestamps_${project.id}');
    if (jsonMap != null) {
      final decodedMap = json.decode(jsonMap) as Map<String, dynamic>;
      _timestamps = decodedMap
          .map((key, value) => MapEntry(key, int.parse(value.toString())));
      notifyListeners();
    }
  }

  void selectWord(int lineIndex, int wordIndex) {
    final key = '$lineIndex-$wordIndex';
    if (_selectedWordKey == key) {
      _selectedWordKey = null;
    } else {
      _selectedWordKey = key;
    }
    notifyListeners();
  }

  void playFromSelected() {
    if (_selectedWordKey != null && _timestamps.containsKey(_selectedWordKey)) {
      final position = _timestamps[_selectedWordKey]!;
      audioPlayer.seek(Duration(milliseconds: position));
      if (!audioPlayer.playing) {
        audioPlayer.play();
      }
    }
  }

  String exportTimestampsToJson() {
    Map<String, List<Map<String, String>>> finalJson = {};
    for (var entry in _timestamps.entries) {
      final parts = entry.key.split('-');
      final lineIndex = int.parse(parts[0]);
      final wordIndex = int.parse(parts[1]);
      final verseKey = 'آیه$lineIndex';
      final wordText = _linesOfWords[lineIndex][wordIndex];
      final timestamp = entry.value.toString();
      if (!finalJson.containsKey(verseKey)) {
        finalJson[verseKey] = [];
      }
      finalJson[verseKey]!.add({'متن': wordText, 'شروع': timestamp});
    }
    finalJson.forEach((key, value) {
      value.sort(
          (a, b) => int.parse(a['شروع']!).compareTo(int.parse(b['شروع']!)));
    });
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(finalJson);
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
