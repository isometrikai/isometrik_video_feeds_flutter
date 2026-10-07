import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_trim/video_trim_timeline.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_trim/video_trim_ui_config.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_button.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/ism_custom_app_bar_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:video_player/video_player.dart';

/// Start and length chosen on [VideoTrimScreen]. The screen does not export.
class VideoTrimSelection {
  const VideoTrimSelection({
    required this.start,
    required this.length,
  });

  final Duration start;
  final Duration length;
}

/// Lightweight trimmer. The selected span cannot exceed [maxDuration].
class VideoTrimScreen extends StatefulWidget {
  const VideoTrimScreen({
    super.key,
    required this.videoPath,
    required this.maxDuration,
    this.pixelsPerSecond,
  });

  /// Share of the screen width used to draw [maxDuration].
  static const maxDurationScreenFraction = 0.6;

  final String videoPath;
  final Duration maxDuration;

  /// Logical pixels per second. When null, [maxDuration] fills
  /// [maxDurationScreenFraction] of the screen width.
  final double? pixelsPerSecond;

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  late final VideoPlayerController _controller;
  var _ready = false;
  var _failed = false;
  var _seeking = false;
  double _startMs = 0;
  double _endMs = 0;
  final _positionMs = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      final totalMs = _controller.value.duration.inMilliseconds.toDouble();
      final capMs = widget.maxDuration.inMilliseconds.toDouble();
      _startMs = 0;
      _endMs = totalMs <= 0 ? 0 : (totalMs < capMs ? totalMs : capMs);
      _controller.addListener(_onPosition);
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onPosition)
      ..dispose();
    _positionMs.dispose();
    super.dispose();
  }

  void _onPosition() {
    if (!_ready || !_controller.value.isInitialized) return;
    _positionMs.value = _controller.value.position.inMilliseconds.toDouble();
    if (_seeking) return;
    final pos = _controller.value.position.inMilliseconds;
    final end = _endMs.round();
    if (pos < end - 80) return;
    _seeking = true;
    unawaited(
      _controller.seekTo(Duration(milliseconds: _startMs.round())).whenComplete(
        () {
          _seeking = false;
          if (_controller.value.isPlaying) {
            unawaited(_controller.play());
          }
        },
      ),
    );
  }

  double get _totalMs => _controller.value.duration.inMilliseconds.toDouble();

  double get _maxSpanMs {
    final cap = widget.maxDuration.inMilliseconds.toDouble();
    final total = _totalMs;
    if (total <= 0) return cap;
    return total < cap ? total : cap;
  }

  double _pixelsPerSecond(BuildContext context) {
    final explicit = widget.pixelsPerSecond;
    if (explicit != null && explicit > 0) return explicit;
    final seconds = widget.maxDuration.inMilliseconds / 1000;
    final width = MediaQuery.sizeOf(context).width;
    if (seconds <= 0 || width <= 0) return 1;
    final configured = _ui?.maxDurationScreenFraction;
    final fraction = configured != null && configured > 0
        ? configured
        : VideoTrimScreen.maxDurationScreenFraction;
    return width * fraction / seconds;
  }

  VideoTrimUIConfig? get _ui => IsrVideoReelConfig
      .createEditPostConfig
      .createEditPostUIConfig
      ?.videoTrimUIConfig;

  Color get _selectionColor => _ui?.selectionColor ?? IsrColors.appColor;

  Color get _foreground =>
      _ui?.appBarForegroundColor ?? IsrColors.appBarIconTextColor;

  TextStyle get _titleStyle => (_ui?.titleStyle ?? const TextStyle()).copyWith(
        color: _ui?.titleStyle?.color ?? _foreground,
        fontFamily:
            _ui?.titleStyle?.fontFamily ?? IsrAppConstants.primaryFontFamily,
      );

  TextStyle get _durationStyle {
    final style = _ui?.durationTextStyle;
    return TextStyle(
      color: style?.color ?? IsrColors.primaryTextColor,
      fontSize: style?.fontSize,
      fontWeight: style?.fontWeight,
      fontFamily: style?.fontFamily ?? IsrAppConstants.primaryFontFamily,
    );
  }

  void _onRangeChanged(RangeValues values) {
    final total = _totalMs;
    if (total <= 0) return;
    final span = _maxSpanMs;
    var start = values.start;
    var end = values.end;
    if (end - start > span) {
      final startMoved = (start - _startMs).abs() >= (end - _endMs).abs();
      if (startMoved) {
        end = start + span;
        if (end > total) {
          end = total;
          start = end - span;
        }
      } else {
        start = end - span;
        if (start < 0) {
          start = 0;
          end = span;
        }
      }
    }
    final minSpan = total < 1000 ? total : 1000.0;
    if (end - start < minSpan) {
      end = start + minSpan;
      if (end > total) {
        end = total;
        start = end - minSpan;
      }
    }
    setState(() {
      _startMs = start.clamp(0, total);
      _endMs = end.clamp(0, total);
    });
    unawaited(_controller.seekTo(Duration(milliseconds: _startMs.round())));
  }

  void _done() {
    final lengthMs = (_endMs - _startMs).round();
    if (lengthMs <= 0) return;
    Navigator.of(context).pop(
      VideoTrimSelection(
        start: Duration(milliseconds: _startMs.round()),
        length: Duration(milliseconds: lengthMs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _ui?.title ?? 'Trim video';
    return Scaffold(
      backgroundColor: _ui?.scaffoldBackgroundColor ?? IsrColors.scaffoldColor,
      appBar: IsmCustomAppBarWidget(
        backgroundColor: _ui?.appBarBackgroundColor,
        iconColor: _foreground,
        titleColor: _foreground,
        isCrossIcon: true,
        centerTitle: true,
        onTap: () => Navigator.of(context).pop(),
        titleWidget: Text(title, style: _titleStyle),
      ),
      body: _failed
          ? Center(
              child: Text(
                _ui?.errorText ?? 'Could not open this video',
                style: TextStyle(
                  color: IsrColors.primaryTextColor,
                  fontFamily: IsrAppConstants.primaryFontFamily,
                ),
              ),
            )
          : !_ready
              ? Center(
                  child: CircularProgressIndicator(
                    color: _ui?.progressColor ?? _selectionColor,
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: Center(child: _player())),
                    _controls(),
                  ],
                ),
    );
  }

  Widget _player() {
    final size = _controller.value.size;
    final ratio = size.width <= 0 || size.height <= 0
        ? _controller.value.aspectRatio
        : size.width / size.height;
    return AspectRatio(
      aspectRatio: ratio == 0 ? 9 / 16 : ratio,
      child: VideoPlayer(_controller),
    );
  }

  Widget _controls() {
    final total = _totalMs;
    final length = Duration(milliseconds: (_endMs - _startMs).round());
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_clock(length)} selected · max ${_clock(widget.maxDuration)}',
              style: _durationStyle,
            ),
            const SizedBox(height: 12),
            VideoTrimTimeline(
              videoPath: widget.videoPath,
              totalMs: total,
              startMs: _startMs,
              endMs: _endMs,
              positionMs: _positionMs,
              pixelsPerSecond: _pixelsPerSecond(context),
              selectionColor: _selectionColor,
              handleColor: _ui?.handleColor ?? IsrColors.white,
              playheadColor: _ui?.playheadColor ?? IsrColors.white,
              trackColor: _ui?.trackColor ?? const Color(0xFF1A1A1A),
              dimColor: _ui?.dimColor ?? const Color(0x99000000),
              placeholderColor: _ui?.placeholderColor ?? const Color(0xFF2C2C2E),
              progressColor: _ui?.progressColor ?? _selectionColor,
              onChanged: _onRangeChanged,
            ),
            const SizedBox(height: 12),
            AppButton(
              title: _ui?.doneButtonText ?? 'Done',
              onPress: _done,
              backgroundColor: _ui?.buttonBackgroundColor,
              textColor: _ui?.buttonForegroundColor,
            ),
          ],
        ),
      ),
    );
  }

  String _clock(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
