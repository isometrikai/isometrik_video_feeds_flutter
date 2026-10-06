import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
  });

  final String videoPath;
  final Duration maxDuration;

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
    super.dispose();
  }

  void _onPosition() {
    if (!_ready || _seeking || !_controller.value.isInitialized) return;
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

  double get _totalMs =>
      _controller.value.duration.inMilliseconds.toDouble();

  double get _maxSpanMs {
    final cap = widget.maxDuration.inMilliseconds.toDouble();
    final total = _totalMs;
    if (total <= 0) return cap;
    return total < cap ? total : cap;
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Trim video'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _failed
            ? const Center(
                child: Text(
                  'Could not open this video',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : !_ready
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(child: Center(child: _player())),
                      _controls(),
                    ],
                  ),
      );

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
              style: const TextStyle(color: Colors.white),
            ),
            RangeSlider(
              values: RangeValues(
                _startMs.clamp(0, total),
                _endMs.clamp(_startMs.clamp(0, total), total <= 0 ? 1 : total),
              ),
              max: total <= 0 ? 1 : total,
              activeColor: IsrColors.appColor,
              onChanged: total <= 0 ? null : _onRangeChanged,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _done,
                style: FilledButton.styleFrom(
                  backgroundColor: IsrColors.appColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
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
