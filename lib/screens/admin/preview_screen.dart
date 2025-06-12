import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komeyl_app/models/calibration_project_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  late AnimationController _progressAnimController;
  late AnimationController _waveAnimController;

  int _currentWordLine = -1;
  int _currentWordIndex = -1;
  bool _isFullscreen = false;
  double _playbackSpeed = 1.0;
  bool _showControls = true;
  bool _autoScroll = true;

  // برای انیمیشن موج صوتی
  final List<double> _waveHeights = List.generate(20, (index) => 0.3);

  @override
  void initState() {
    super.initState();
    _playPauseAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _waveAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initAudio();
    _setupWaveAnimation();
  }

  void _setupWaveAnimation() {
    _waveAnimController.addListener(() {
      if (_audioPlayer.playing) {
        setState(() {
          for (int i = 0; i < _waveHeights.length; i++) {
            _waveHeights[i] = 0.3 +
                0.7 *
                    (0.5 +
                        0.5 *
                            (i % 2 == 0
                                ? _waveAnimController.value
                                : 1 - _waveAnimController.value));
          }
        });
      }
    });
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
        if (playing) {
          _playPauseAnimController.forward();
        } else {
          _playPauseAnimController.reverse();
        }
      });
    } catch (e) {
      print("Error setting audio source in preview: $e");
    }
  }

  void _updateHighlighting(Duration position) {
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playPauseAnimController.dispose();
    _progressAnimController.dispose();
    _waveAnimController.dispose();
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
        appBar: _buildModernAppBar(),
        body: Stack(
          children: [
            _buildBackgroundGradient(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _buildTextContent(),
                  ),
                  _buildModernPlayerControls(),
                ],
              ),
            ),
            if (_isFullscreen) _buildFullscreenOverlay(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              children: [
                Text(
                  'پیش‌نمایش',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  widget.project.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_autoScroll
                    ? Icons.sync_rounded
                    : Icons.sync_disabled_rounded),
                onPressed: () {
                  setState(() => _autoScroll = !_autoScroll);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _autoScroll
                            ? 'اسکرول خودکار فعال شد'
                            : 'اسکرول خودکار غیرفعال شد',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                tooltip: 'اسکرول خودکار',
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded),
                onPressed: () => setState(() => _isFullscreen = true),
                tooltip: 'تمام صفحه',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: widget.linesOfWords.length,
      itemBuilder: (context, lineIndex) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (lineIndex * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _currentWordLine == lineIndex
                      ? const Color(0xFF6C63FF).withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _currentWordLine == lineIndex ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _currentWordLine == lineIndex
                    ? const Color(0xFF6C63FF).withOpacity(0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _currentWordLine == lineIndex
                            ? const Color(0xFF6C63FF)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'آیه ${lineIndex + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _currentWordLine == lineIndex
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    if (_currentWordLine == lineIndex) _buildMiniWaveform(),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 12.0,
                  textDirection: TextDirection.rtl,
                  alignment: WrapAlignment.center,
                  children: _buildLineSpans(lineIndex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniWaveform() {
    return SizedBox(
      width: 60,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 3,
            height: _audioPlayer.playing
                ? 20 * _waveHeights[index % _waveHeights.length]
                : 4,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildLineSpans(int lineIndex) {
    List<Widget> spans = [];
    for (int wordIndex = 0;
        wordIndex < widget.linesOfWords[lineIndex].length;
        wordIndex++) {
      final key = '$lineIndex-$wordIndex';
      final bool isTimestamped = widget.timestamps.containsKey(key);
      final bool isPast = lineIndex < _currentWordLine ||
          (lineIndex == _currentWordLine && wordIndex < _currentWordIndex);
      final bool isCurrent =
          lineIndex == _currentWordLine && wordIndex == _currentWordIndex;
      final word = widget.linesOfWords[lineIndex][wordIndex];

      spans.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getWordBackgroundColor(isCurrent, isPast, isTimestamped),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            word,
            style: TextStyle(
              fontFamily: 'Alhura',
              fontSize: isCurrent ? 32 : 28,
              color: _getWordTextColor(isCurrent, isPast, isTimestamped),
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return spans;
  }

  Color _getWordBackgroundColor(
      bool isCurrent, bool isPast, bool isTimestamped) {
    if (isCurrent) {
      return Colors.amber[100]!;
    } else if (isPast && isTimestamped) {
      return const Color(0xFF6C63FF).withOpacity(0.1);
    } else if (isTimestamped) {
      return Colors.grey[100]!;
    }
    return Colors.transparent;
  }

  Color _getWordTextColor(bool isCurrent, bool isPast, bool isTimestamped) {
    if (isCurrent) {
      return Colors.amber[900]!;
    } else if (isPast && isTimestamped) {
      return const Color(0xFF6C63FF);
    } else if (isTimestamped) {
      return Colors.grey[700]!;
    }
    return Colors.grey[400]!;
  }

  Widget _buildModernPlayerControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWaveformVisualizer(),
          const SizedBox(height: 20),
          _buildProgressBar(),
          const SizedBox(height: 20),
          _buildControlButtons(),
          const SizedBox(height: 16),
          _buildSpeedControl(),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualizer() {
    return StreamBuilder<bool>(
      stream: _audioPlayer.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.1),
                const Color(0xFF8B80F8).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_waveHeights.length, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: isPlaying ? 100 : 300),
                width: 4,
                height: isPlaying ? 40 * _waveHeights[index] : 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF8B80F8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: _audioPlayer.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF),
                              const Color(0xFF8B80F8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          thumbColor: const Color(0xFF6C63FF),
                          overlayColor:
                              const Color(0xFF6C63FF).withOpacity(0.2),
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds:
                                  (duration.inMilliseconds * value).round(),
                            );
                            _audioPlayer.seek(newPosition);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: Icons.replay_10_rounded,
          onPressed: () => _seek(-10),
          tooltip: '10 ثانیه عقب',
        ),
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          onPressed: _previousVerse,
          tooltip: 'آیه قبلی',
        ),
        StreamBuilder<bool>(
          stream: _audioPlayer.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return GestureDetector(
              onTap: () {
                if (isPlaying) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF8B80F8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: _playPauseAnimController,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            );
          },
        ),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: _nextVerse,
          tooltip: 'آیه بعدی',
        ),
        _ControlButton(
          icon: Icons.forward_10_rounded,
          onPressed: () => _seek(10),
          tooltip: '10 ثانیه جلو',
        ),
      ],
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            'سرعت پخش:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(4, (index) {
            final speeds = [0.5, 0.75, 1.0, 1.25];
            final speed = speeds[index];
            final isSelected = _playbackSpeed == speed;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() => _playbackSpeed = speed);
                  _audioPlayer.setSpeed(speed);
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFullscreenOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentWordLine >= 0 &&
                      _currentWordLine < widget.linesOfWords.length)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 20,
                        textDirection: TextDirection.rtl,
                        alignment: WrapAlignment.center,
                        children: _buildFullscreenWords(),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_fullscreen_rounded),
                color: Colors.white,
                iconSize: 32,
                onPressed: () => setState(() => _isFullscreen = false),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: _buildFullscreenControls(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFullscreenWords() {
    if (_currentWordLine < 0) return [];

    final words = widget.linesOfWords[_currentWordLine];
    return List.generate(words.length, (index) {
      final isCurrent = index == _currentWordIndex;
      final isPast = index < _currentWordIndex;

      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontFamily: 'Alhura',
          fontSize: isCurrent ? 48 : 40,
          color: isCurrent
              ? Colors.amber
              : isPast
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
        child: Text(words[index]),
      );
    });
  }

  Widget _buildFullscreenControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10_rounded),
          color: Colors.white,
          iconSize: 32,
          onPressed: () => _seek(-10),
        ),
        const SizedBox(width: 16),
        StreamBuilder<bool>(
          stream: _audioPlayer.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
              ),
              color: Colors.white,
              iconSize: 64,
              onPressed: () {
                if (isPlaying) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
            );
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_10_rounded),
          color: Colors.white,
          iconSize: 32,
          onPressed: () => _seek(10),
        ),
      ],
    );
  }

  void _seek(int seconds) {
    final newPosition = _audioPlayer.position + Duration(seconds: seconds);
    _audioPlayer.seek(newPosition);
    HapticFeedback.lightImpact();
  }

  void _previousVerse() {
    if (_currentWordLine > 0) {
      final prevLineKey = '${_currentWordLine - 1}-0';
      if (widget.timestamps.containsKey(prevLineKey)) {
        _audioPlayer.seek(
          Duration(milliseconds: widget.timestamps[prevLineKey]!),
        );
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _nextVerse() {
    if (_currentWordLine < widget.linesOfWords.length - 1) {
      final nextLineKey = '${_currentWordLine + 1}-0';
      if (widget.timestamps.containsKey(nextLineKey)) {
        _audioPlayer.seek(
          Duration(milliseconds: widget.timestamps[nextLineKey]!),
        );
        HapticFeedback.mediumImpact();
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// Control Button Widget
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
