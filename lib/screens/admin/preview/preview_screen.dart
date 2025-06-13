import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'widgets/preview_app_bar.dart';
import 'widgets/player_controls.dart';
import 'widgets/text_content.dart';
import 'widgets/fullscreen_overlay.dart';

class PreviewScreen extends StatefulWidget {
  final CalibrationProject project;
  final Map<String, int> timestamps;
  final List<List<String>> linesOfWords;
  final int? initialSeekMilliseconds;

  const PreviewScreen({
    super.key,
    required this.project,
    required this.timestamps,
    required this.linesOfWords,
    this.initialSeekMilliseconds,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late AnimationController _playPauseAnimController;

  int _currentWordLine = -1;
  int _currentWordIndex = -1;
  bool _isFullscreen = false;
  double _playbackSpeed = 1.0;
  bool _autoScroll = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playPauseAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setFilePath(widget.project.audioPath);
      if (widget.initialSeekMilliseconds != null) {
        await _audioPlayer
            .seek(Duration(milliseconds: widget.initialSeekMilliseconds!));
      }
      _audioPlayer.positionStream.listen(_updateHighlighting);
      _audioPlayer.playingStream.listen((playing) {
        if (!mounted) return;
        setState(() => _isPlaying = playing);
        if (playing) {
          _playPauseAnimController.forward();
        } else {
          _playPauseAnimController.reverse();
        }
      });
    } catch (e) {
      debugPrint("Error setting audio source in preview: $e");
    }
  }

  void _updateHighlighting(Duration position) {
    if (!mounted) return;
    final ms = position.inMilliseconds;
    String? foundKey;

    widget.timestamps.forEach((key, value) {
      if (value <= ms) {
        if (foundKey == null || value > widget.timestamps[foundKey]!) {
          foundKey = key;
        }
      }
    });

    if (foundKey != null) {
      final parts = foundKey!.split('-').map(int.parse).toList();
      if (parts[0] != _currentWordLine) {
        if (_itemScrollController.isAttached && _autoScroll) {
          _itemScrollController.scrollTo(
            index: parts[0],
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            alignment: 0.4,
          );
        }
      }
      if (parts[0] != _currentWordLine || parts[1] != _currentWordIndex) {
        setState(() {
          _currentWordLine = parts[0];
          _currentWordIndex = parts[1];
        });
      }
    }
  }

  void _seek(int seconds) {
    final newPosition = _audioPlayer.position + Duration(seconds: seconds);
    _audioPlayer.seek(newPosition);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playPauseAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        extendBodyBehindAppBar: true,
        appBar: PreviewAppBar(
          projectTitle: widget.project.title,
          isAutoScroll: _autoScroll,
          onToggleAutoScroll: () {
            setState(() => _autoScroll = !_autoScroll);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_autoScroll
                    ? 'اسکرول خودکار فعال شد'
                    : 'اسکرول خودکار غیرفعال شد'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          onFullscreen: () => setState(() => _isFullscreen = true),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.05),
                    Colors.white
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: TextContent(
                      lineCount: widget.linesOfWords.length,
                      currentLine: _currentWordLine,
                      linesOfWords: widget.linesOfWords,
                      timestamps: widget.timestamps,
                      currentWordIndex: _currentWordIndex,
                      isPlaying: _isPlaying,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                    ),
                  ),
                  PreviewPlayerControls(
                    audioPlayer: _audioPlayer,
                    playPauseAnimController: _playPauseAnimController,
                    playbackSpeed: _playbackSpeed,
                    onSpeedChanged: (speed) {
                      setState(() => _playbackSpeed = speed);
                      _audioPlayer.setSpeed(speed);
                    },
                  ),
                ],
              ),
            ),
            if (_isFullscreen)
              FullscreenOverlay(
                words: _currentWordLine >= 0
                    ? widget.linesOfWords[_currentWordLine]
                    : [],
                currentWordIndex: _currentWordIndex,
                isPlaying: _isPlaying,
                onClose: () => setState(() => _isFullscreen = false),
                onPlayPause: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
                onSeek: _seek,
              ),
          ],
        ),
      ),
    );
  }
}
