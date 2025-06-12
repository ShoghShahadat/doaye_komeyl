import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/calibration_choice_model.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalibrationProvider with ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  final CalibrationProject project;

  List<List<String>> _arabicLinesOfWords = [];
  Map<String, List<CalibrationChoice>> _timestamps = {};
  String? _selectedWordKey;

  bool _isRangeSelectionMode = false;
  String? _rangeStartKey;
  String? _rangeEndKey;

  List<String> _undoStack = [];
  List<String> _redoStack = [];
  List<String> _translationLines = [];

  List<List<String>> get arabicLinesOfWords => _arabicLinesOfWords;
  List<String> get translationLines => _translationLines;
  Map<String, List<CalibrationChoice>> get timestamps => _timestamps;
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
    await _loadState();
    await audioPlayer.setFilePath(project.audioPath);
  }

  String _serializeState() {
    final serializableTimestamps = _timestamps.map((key, value) =>
        MapEntry(key, value.map((choice) => choice.toJson()).toList()));
    return json.encode(serializableTimestamps);
  }

  void _deserializeAndSetState(String jsonState) {
    try {
      final decodedState = json.decode(jsonState) as Map<String, dynamic>;
      _timestamps = decodedState.map((key, value) {
        final choices = (value as List)
            .map((item) =>
                CalibrationChoice.fromJson(item as Map<String, dynamic>))
            .toList();
        return MapEntry(key, choices);
      });
    } catch (e) {
      _timestamps = {};
    }
  }

  void _saveSnapshot() {
    _undoStack.add(_serializeState());
    _redoStack.clear();
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timestamps_${project.id}', _serializeState());
    await prefs.setStringList('undo_${project.id}', _undoStack);
    await prefs.setStringList('redo_${project.id}', _redoStack);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonTimestamps = prefs.getString('timestamps_${project.id}');
    if (jsonTimestamps != null) {
      _deserializeAndSetState(jsonTimestamps);
    }
    _undoStack = prefs.getStringList('undo_${project.id}') ?? [];
    _redoStack = prefs.getStringList('redo_${project.id}') ?? [];
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_serializeState());
    final lastState = _undoStack.removeLast();
    _deserializeAndSetState(lastState);
    _saveState();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_serializeState());
    final nextState = _redoStack.removeLast();
    _deserializeAndSetState(nextState);
    _saveState();
    notifyListeners();
  }

  void _performAction(Function action) {
    _saveSnapshot();
    action();
    _saveState();
    notifyListeners();
  }

  void assignTimestamp(int lineIndex, int wordIndex,
      {bool isResamping = false}) {
    _performAction(() {
      final key = '$lineIndex-$wordIndex';
      final newChoice = CalibrationChoice(
        timestamp: audioPlayer.position.inMilliseconds,
        source: 'شما',
        isChosen: true,
      );
      if (_timestamps.containsKey(key) && !isResamping) {
        _timestamps[key]!.forEach((c) => c.isChosen = false);
        _timestamps[key]!.add(newChoice);
      } else {
        _timestamps[key] = [newChoice];
      }
    });
  }

  void selectWord(int lineIndex, int wordIndex) {
    final key = '$lineIndex-$wordIndex';
    _selectedWordKey = (_selectedWordKey == key) ? null : key;
    notifyListeners();
  }

  void nudgeTimestamp(int milliseconds) {
    if (_selectedWordKey == null || !_timestamps.containsKey(_selectedWordKey))
      return;
    _performAction(() {
      final choices = _timestamps[_selectedWordKey]!;
      if (choices.isNotEmpty) {
        final chosenOne =
            choices.firstWhere((c) => c.isChosen, orElse: () => choices.first);
        chosenOne.timestamp = (chosenOne.timestamp + milliseconds)
            .clamp(0, audioPlayer.duration?.inMilliseconds ?? 0);
      }
    });
  }

  void deleteSelectedTimestamp() {
    if (_selectedWordKey == null) return;
    _performAction(() {
      _timestamps.remove(_selectedWordKey);
      _selectedWordKey = null;
    });
  }

  void resolveConflict(String wordKey, CalibrationChoice chosenChoice) {
    if (!_timestamps.containsKey(wordKey)) return;
    _performAction(() {
      for (var choice in _timestamps[wordKey]!) {
        choice.isChosen = (choice == chosenChoice);
      }
    });
  }

  void restampCurrentWord() {
    if (_selectedWordKey == null) return;
    final parts = _selectedWordKey!.split('-').map(int.parse).toList();
    assignTimestamp(parts[0], parts[1], isResamping: true);
  }

  String? _findNextKey(String? currentKey) {
    if (currentKey == null) return '0-0';
    var parts = currentKey.split('-').map(int.parse).toList();
    int line = parts[0];
    int word = parts[1];

    if (word + 1 < _arabicLinesOfWords[line].length) {
      return '$line-${word + 1}';
    } else if (line + 1 < _arabicLinesOfWords.length) {
      return '${line + 1}-0';
    }
    return null; // End of text
  }

  String? _findPreviousKey(String? currentKey) {
    if (currentKey == null || currentKey == '0-0') return null; // Start of text
    var parts = currentKey.split('-').map(int.parse).toList();
    int line = parts[0];
    int word = parts[1];

    if (word - 1 >= 0) {
      return '$line-${word - 1}';
    } else if (line - 1 >= 0) {
      int prevLine = line - 1;
      int lastWordOfPrevLine = _arabicLinesOfWords[prevLine].length - 1;
      return '$prevLine-$lastWordOfPrevLine';
    }
    return null;
  }

  void stampNextWord() {
    final nextKey = _findNextKey(_selectedWordKey);
    if (nextKey != null) {
      final parts = nextKey.split('-').map(int.parse).toList();
      assignTimestamp(parts[0], parts[1]);
      _selectedWordKey = nextKey;
    }
  }

  void stampPreviousWord() {
    final prevKey = _findPreviousKey(_selectedWordKey);
    if (prevKey != null) {
      final parts = prevKey.split('-').map(int.parse).toList();
      assignTimestamp(parts[0], parts[1]);
      _selectedWordKey = prevKey;
    }
  }

  void _selectAndTimestamp(int line, int word) {
    _saveSnapshot();
    final key = '$line-$word';
    _timestamps[key] = [
      CalibrationChoice(
        timestamp: audioPlayer.position.inMilliseconds,
        source: 'شما',
        isChosen: true,
      )
    ];
    _selectedWordKey = key; // کلمه جدید را به عنوان انتخاب شده فعلی قرار بده
    _saveState();
    notifyListeners();
  }

  void recalibrateCurrent() {
    if (_selectedWordKey == null) return;
    final parts = _selectedWordKey!.split('-').map(int.parse).toList();
    _selectAndTimestamp(parts[0], parts[1]);
  }

  void calibrateNext() {
    int currentLine = 0;
    int currentWord = -1; // شروع از قبل از اولین کلمه

    if (_selectedWordKey != null) {
      final parts = _selectedWordKey!.split('-').map(int.parse).toList();
      currentLine = parts[0];
      currentWord = parts[1];
    }

    // پیدا کردن کلمه بعدی
    if (currentWord + 1 < _arabicLinesOfWords[currentLine].length) {
      // کلمه بعدی در همین خط است
      _selectAndTimestamp(currentLine, currentWord + 1);
    } else if (currentLine + 1 < _arabicLinesOfWords.length) {
      // کلمه بعدی در خط بعدی است
      _selectAndTimestamp(currentLine + 1, 0);
    }
    // اگر آخرین کلمه بود، کاری نکن
  }

  void calibratePrevious() {
    if (_selectedWordKey == null) return;

    final parts = _selectedWordKey!.split('-').map(int.parse).toList();
    int currentLine = parts[0];
    int currentWord = parts[1];

    // پیدا کردن کلمه قبلی
    if (currentWord - 1 >= 0) {
      // کلمه قبلی در همین خط است
      _selectAndTimestamp(currentLine, currentWord - 1);
    } else if (currentLine - 1 >= 0) {
      // کلمه قبلی در انتهای خط قبلی است
      final prevLineIndex = currentLine - 1;
      final lastWordIndex = _arabicLinesOfWords[prevLineIndex].length - 1;
      _selectAndTimestamp(prevLineIndex, lastWordIndex);
    }
  }

  void toggleRangeSelectionMode() {
    _isRangeSelectionMode = !_isRangeSelectionMode;
    _rangeStartKey = null;
    _rangeEndKey = null;
    _selectedWordKey = null;
    notifyListeners();
  }

  void setRangeMarker(int lineIndex, int wordIndex) {
    final key = '$lineIndex-$wordIndex';
    if (_rangeStartKey == null ||
        (_rangeStartKey != null && _rangeEndKey != null)) {
      _rangeStartKey = key;
      _rangeEndKey = null;
    } else {
      final startParts = _rangeStartKey!.split('-').map(int.parse).toList();
      if (lineIndex > startParts[0] ||
          (lineIndex == startParts[0] && wordIndex > startParts[1])) {
        _rangeEndKey = key;
      } else {
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
    toggleRangeSelectionMode();
    _saveState();
    notifyListeners();
  }

  Future<void> importAndMergeFromJson(String jsonContent) async {
    _saveSnapshot();
    try {
      final Map<String, dynamic> externalJson = json.decode(jsonContent);
      externalJson.forEach((verseKey, wordsList) {
        if (wordsList is List) {
          final lineIndexStr = verseKey.replaceFirst('آیه', '');
          final lineIndex = int.tryParse(lineIndexStr);
          if (lineIndex == null || lineIndex >= _arabicLinesOfWords.length)
            return;

          for (var wordData in wordsList) {
            if (wordData is Map &&
                wordData.containsKey('متن') &&
                wordData.containsKey('شروع')) {
              final wordText = wordData['متن'];
              final timestamp = int.tryParse(wordData['شروع'].toString());
              if (wordText != null && timestamp != null) {
                int wordIndex =
                    _arabicLinesOfWords[lineIndex].indexOf(wordText);
                if (wordIndex != -1) {
                  final key = '$lineIndex-$wordIndex';
                  final newChoice = CalibrationChoice(
                      timestamp: timestamp,
                      source: 'فایل وارد شده',
                      isChosen: false);
                  if (_timestamps.containsKey(key)) {
                    if (!_timestamps[key]!
                        .any((c) => c.timestamp == timestamp)) {
                      _timestamps[key]!.add(newChoice);
                    }
                  } else {
                    newChoice.isChosen = true;
                    _timestamps[key] = [newChoice];
                  }
                }
              }
            }
          }
        }
      });
      await _saveState();
      notifyListeners();
    } catch (e) {
      print('Error merging data: $e');
      undo();
    }
  }

  String exportTimestampsToJson() {
    Map<String, List<Map<String, String>>> finalJson = {};
    _timestamps.forEach((key, choices) {
      if (choices.isNotEmpty) {
        final chosen =
            choices.firstWhere((c) => c.isChosen, orElse: () => choices.first);
        final parts = key.split('-');
        final lineIndex = int.parse(parts[0]);
        final wordIndex = int.parse(parts[1]);
        if (lineIndex < _arabicLinesOfWords.length &&
            wordIndex < _arabicLinesOfWords[lineIndex].length) {
          final verseKey = 'آیه$lineIndex';
          final wordText = _arabicLinesOfWords[lineIndex][wordIndex];

          if (!finalJson.containsKey(verseKey)) {
            finalJson[verseKey] = [];
          }
          finalJson[verseKey]!
              .add({'متن': wordText, 'شروع': chosen.timestamp.toString()});
        }
      }
    });
    finalJson.forEach((key, value) {
      value.sort(
          (a, b) => int.parse(a['شروع']!).compareTo(int.parse(b['شروع']!)));
    });
    return const JsonEncoder.withIndent('  ').convert(finalJson);
  }

  Future<void> _loadTextFromFile() async {
    try {
      if (project.textParsingMode == 'interleaved') {
        final file = File(project.mainTextPath);
        final List<String> lines = await file.readAsLines();
        _arabicLinesOfWords.clear();
        _translationLines.clear();
        for (int i = 0; i < lines.length; i++) {
          final trimmedLine = lines[i].trim();
          if (trimmedLine.isNotEmpty) {
            if (i.isEven) {
              // خطوط زوج: عربی
              _arabicLinesOfWords.add(trimmedLine.split(' '));
            } else {
              // خطوط فرد: ترجمه
              _translationLines.add(trimmedLine);
            }
          }
        }
      } else {
        // حالت مجزا
        final arabicFile = File(project.mainTextPath);
        final List<String> arabicLines = await arabicFile.readAsLines();
        _arabicLinesOfWords = arabicLines
            .map((line) => line.trim().split(' '))
            .where((words) => words.isNotEmpty && words.first != '')
            .toList();

        if (project.translationTextPath != null) {
          final translationFile = File(project.translationTextPath!);
          _translationLines = (await translationFile.readAsLines())
              .map((line) => line.trim())
              .toList();
        } else {
          _translationLines = [];
        }
      }
    } catch (e) {
      print('Error reading text file(s): $e');
      _arabicLinesOfWords = [];
      _translationLines = [];
    }
    notifyListeners();
  }

  void playFromSelected() {
    if (_selectedWordKey != null && _timestamps.containsKey(_selectedWordKey)) {
      final choices = _timestamps[_selectedWordKey]!;
      if (choices.isNotEmpty) {
        final chosen =
            choices.firstWhere((c) => c.isChosen, orElse: () => choices.first);
        audioPlayer.seek(Duration(milliseconds: chosen.timestamp));
        if (!audioPlayer.playing) audioPlayer.play();
      }
    }
  }

  Future<Uint8List?> packageProjectAsZip() async {
    try {
      final archive = Archive();
      final jsonString = exportTimestampsToJson();
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(
          ArchiveFile('calibration.json', jsonBytes.length, jsonBytes));

      final audioFile = File(project.audioPath);
      if (await audioFile.exists()) {
        final audioBytes = await audioFile.readAsBytes();
        archive
            .addFile(ArchiveFile('audio.mp3', audioBytes.length, audioBytes));
      }

      final textFile = File(project.mainTextPath);
      if (await textFile.exists()) {
        final textBytes = await textFile.readAsBytes();
        archive.addFile(ArchiveFile('text.txt', textBytes.length, textBytes));
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      return zipData != null ? Uint8List.fromList(zipData) : null;
    } catch (e) {
      print('Error packaging project: $e');
      return null;
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
