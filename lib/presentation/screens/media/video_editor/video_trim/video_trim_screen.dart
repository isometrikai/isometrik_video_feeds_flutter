import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_trim/video_trim_timeline.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_trim/video_trim_ui_config.dart';
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
  var _playing = false;
  var _muted = false;
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
    final playing = _controller.value.isPlaying;
    if (playing != _playing && mounted) {
      setState(() => _playing = playing);
    }
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

  void _togglePlay() {
    if (_playing) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
  }

  void _toggleMute() {
    final muted = !_muted;
    unawaited(_controller.setVolume(muted ? 0 : 1));
    setState(() => _muted = muted);
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

  double get _videoAspect {
    final size = _controller.value.size;
    if (size.width > 0 && size.height > 0) return size.width / size.height;
    final ratio = _controller.value.aspectRatio;
    if (ratio > 0) return ratio;
    return 9 / 16;
  }

  Widget _player() => AspectRatio(
        aspectRatio: _videoAspect,
        child: VideoPlayer(_controller),
      );

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
            _rangeSummary(length),
            const SizedBox(height: 8),
            _playbackRow(length),
            const SizedBox(height: 12),
            VideoTrimTimeline(
              videoPath: widget.videoPath,
              videoAspect: _videoAspect,
              totalMs: total,
              startMs: _startMs,
              endMs: _endMs,
              positionMs: _positionMs,
              pixelsPerSecond: _pixelsPerSecond(context),
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

  Color get _valueColor =>
      _durationStyle.color ?? IsrColors.primaryTextColor;

  TextStyle _timeStyle({
    required Color color,
    required FontWeight weight,
  }) =>
      _durationStyle.copyWith(
        color: color,
        fontWeight: weight,
        fontSize: _durationStyle.fontSize ?? 15,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  TextStyle get _metaLabelStyle => TextStyle(
        color: _valueColor.withValues(alpha: 0.55),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontFamily: _durationStyle.fontFamily,
      );

  Widget _rangeSummary(Duration length) => Row(
        children: [
          _rangeValue(
            label: 'Start',
            value: _clock(Duration(milliseconds: _startMs.round())),
            color: _valueColor,
            weight: FontWeight.w600,
          ),
          _rangeValue(
            label: 'End',
            value: _clock(Duration(milliseconds: _endMs.round())),
            color: _valueColor,
            weight: FontWeight.w600,
          ),
          _rangeValue(
            label: 'Selected',
            value: _clock(length),
            color: _valueColor,
            weight: FontWeight.w700,
          ),
          _rangeValue(
            label: 'Max',
            value: _clock(widget.maxDuration),
            color: _valueColor.withValues(alpha: 0.45),
            weight: FontWeight.w500,
          ),
        ],
      );

  Widget _rangeValue({
    required String label,
    required String value,
    required Color color,
    required FontWeight weight,
  }) =>
      Expanded(
        child: Column(
          children: [
            Text(label.toUpperCase(), style: _metaLabelStyle),
            const SizedBox(height: 2),
            Text(
              value,
              style: _timeStyle(color: color, weight: weight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _playbackRow(Duration length) => Row(
        children: [
          _transportButton(
            icon: _playing ? Icons.pause : Icons.play_arrow,
            tooltip: _playing ? 'Pause' : 'Play',
            onPressed: _togglePlay,
          ),
          _transportButton(
            icon: _muted ? Icons.volume_off : Icons.volume_up,
            tooltip: _muted ? 'Unmute' : 'Mute',
            onPressed: _toggleMute,
          ),
          const Spacer(),
          ValueListenableBuilder<double>(
            valueListenable: _positionMs,
            builder: (context, positionMs, _) {
              final position = Duration(milliseconds: positionMs.round());
              final total = Duration(milliseconds: _totalMs.round());
              final spanMs = math.max(0.0, _endMs - _startMs);
              final trimmedMs =
                  (positionMs - _startMs).clamp(0.0, spanMs).toDouble();
              final trimmed = Duration(milliseconds: trimmedMs.round());
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _timePair(
                    label: 'Actual',
                    value: '${_clock(position)} / ${_clock(total)}',
                    filled: false,
                    accent: _valueColor.withValues(alpha: 0.45),
                    textColor: _valueColor.withValues(alpha: 0.65),
                    weight: FontWeight.w500,
                  ),
                  const SizedBox(height: 2),
                  _timePair(
                    label: 'After trim',
                    value: '${_clock(trimmed)} / ${_clock(length)}',
                    filled: true,
                    accent: _selectionColor,
                    textColor: _valueColor,
                    weight: FontWeight.w700,
                  ),
                ],
              );
            },
          ),
        ],
      );

  Widget _timePair({
    required String label,
    required String value,
    required bool filled,
    required Color accent,
    required Color textColor,
    required FontWeight weight,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? accent : Colors.transparent,
                    border: Border.all(color: accent),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: _metaLabelStyle.copyWith(letterSpacing: 0),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: _timeStyle(color: textColor, weight: weight),
          ),
        ],
      );

  Widget _transportButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) =>
      IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: Icon(icon, size: 22, color: _valueColor),
      );

  String _clock(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
