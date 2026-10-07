import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Scrollable filmstrip for choosing a trim range.
///
/// One second of video is [pixelsPerSecond] logical pixels wide.
/// A still is taken every 5 seconds with FFmpeg.
class VideoTrimTimeline extends StatefulWidget {
  const VideoTrimTimeline({
    super.key,
    required this.videoPath,
    required this.totalMs,
    required this.startMs,
    required this.endMs,
    required this.positionMs,
    required this.pixelsPerSecond,
    required this.selectionColor,
    required this.handleColor,
    required this.playheadColor,
    required this.trackColor,
    required this.dimColor,
    required this.placeholderColor,
    required this.progressColor,
    required this.onChanged,
  });

  final String videoPath;
  final double totalMs;
  final double startMs;
  final double endMs;
  final ValueListenable<double> positionMs;

  /// Logical pixels drawn for each second of video.
  final double pixelsPerSecond;

  final Color selectionColor;
  final Color handleColor;
  final Color playheadColor;
  final Color trackColor;
  final Color dimColor;
  final Color placeholderColor;
  final Color progressColor;

  final ValueChanged<RangeValues> onChanged;

  @override
  State<VideoTrimTimeline> createState() => _VideoTrimTimelineState();
}

class _VideoTrimTimelineState extends State<VideoTrimTimeline> {
  static const _thumbnailEverySeconds = 5.0;
  static const _trackHeight = 58.0;
  static const _handleHitWidth = 28.0;
  static const _radius = 6.0;

  final _scroll = ScrollController();
  final _scrollOffset = ValueNotifier<double>(0);

  var _generation = 0;
  var _thumbsReady = false;
  var _thumbPaths = const <String>[];
  Directory? _thumbDir;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_publishScroll);
    unawaited(_loadThumbs());
  }

  @override
  void didUpdateWidget(covariant VideoTrimTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      unawaited(_loadThumbs());
    }
  }

  @override
  void dispose() {
    _generation++;
    final sessionId = _sessionId;
    if (sessionId != null) unawaited(FFmpegKit.cancel(sessionId));
    final dir = _thumbDir;
    final paths = _thumbPaths;
    if (dir != null) unawaited(_deleteDir(dir, paths));
    _scroll
      ..removeListener(_publishScroll)
      ..dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _publishScroll() {
    _scrollOffset.value = _scroll.offset;
  }

  double get _pixelsPerSecond {
    final scale = widget.pixelsPerSecond;
    return scale > 0 ? scale : 1;
  }

  double get _timelineWidth {
    final seconds = widget.totalMs / 1000;
    if (seconds <= 0) return 1;
    return seconds * _pixelsPerSecond;
  }

  int get _slotCount {
    final seconds = widget.totalMs / 1000;
    if (seconds <= 0) return 1;
    return math.max(1, (seconds / _thumbnailEverySeconds).ceil());
  }

  double _msToX(double ms) {
    final total = widget.totalMs;
    final clamped = total <= 0 ? 0.0 : ms.clamp(0.0, total);
    return clamped / 1000 * _pixelsPerSecond;
  }

  double _sideInset(double viewport, double timelineWidth) =>
      timelineWidth < viewport ? (viewport - timelineWidth) / 2 : 0;

  void _moveEdge({required bool isStart, required double dx}) {
    if (widget.totalMs <= 0) return;
    final deltaMs = dx / _pixelsPerSecond * 1000;
    widget.onChanged(
      RangeValues(
        widget.startMs + (isStart ? deltaMs : 0),
        widget.endMs + (isStart ? 0 : deltaMs),
      ),
    );
  }

  void _moveSelection(double dx) {
    final total = widget.totalMs;
    if (total <= 0 || dx == 0) return;
    final length = math.min(
      math.max(0.0, widget.endMs - widget.startMs),
      total,
    );
    final deltaMs = dx / _pixelsPerSecond * 1000;
    var start = widget.startMs + deltaMs;
    if (start < 0) start = 0;
    final maxStart = math.max(0.0, total - length);
    if (start > maxStart) start = maxStart;
    widget.onChanged(RangeValues(start, start + length));
  }

  Future<void> _loadThumbs() async {
    final generation = ++_generation;
    final previousSession = _sessionId;
    _sessionId = null;
    if (previousSession != null) unawaited(FFmpegKit.cancel(previousSession));

    final previousDir = _thumbDir;
    final previousPaths = _thumbPaths;
    _thumbDir = null;
    if (previousDir != null && mounted) {
      setState(() {
        _thumbsReady = false;
        _thumbPaths = const [];
      });
      unawaited(_deleteDir(previousDir, previousPaths));
    }

    final frames = _slotCount;
    final temp = await getTemporaryDirectory();
    if (!mounted || generation != _generation) return;
    final dir = Directory(
      '${temp.path}/trim_thumbs_${DateTime.now().microsecondsSinceEpoch}',
    );
    await dir.create(recursive: true);
    if (!mounted || generation != _generation) {
      await _deleteDir(dir, const []);
      return;
    }
    _thumbDir = dir;

    var paths = await _extract(
      generation: generation,
      dir: dir,
      frames: frames,
      extension: 'webp',
      codec: const ['-c:v', 'libwebp', '-quality', '70'],
    );
    if (!mounted || generation != _generation || paths == null) return;
    if (paths.isEmpty) {
      paths = await _extract(
        generation: generation,
        dir: dir,
        frames: frames,
        extension: 'png',
        codec: const [],
      );
      if (!mounted || generation != _generation || paths == null) return;
    }
    final thumbs = paths;
    setState(() {
      _thumbPaths = thumbs;
      _thumbsReady = true;
    });
  }

  /// Null when this generation was cancelled. Empty when FFmpeg wrote nothing.
  Future<List<String>?> _extract({
    required int generation,
    required Directory dir,
    required int frames,
    required String extension,
    required List<String> codec,
  }) async {
    final output = '${dir.path}/thumb_%03d.$extension';
    final completer = Completer<bool>();
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        [
          '-y',
          '-i',
          widget.videoPath,
          '-an',
          '-vf',
          'fps=1/${_thumbnailEverySeconds.toInt()},scale=-2:160',
          '-frames:v',
          '$frames',
          ...codec,
          output,
        ],
        (completed) async {
          if (completer.isCompleted) return;
          final code = await completed.getReturnCode();
          if (ReturnCode.isCancel(code)) {
            completer.complete(false);
            return;
          }
          completer.complete(ReturnCode.isSuccess(code));
        },
      );
      final id = session.getSessionId();
      _sessionId = id;
      if (generation != _generation && id != null) {
        unawaited(FFmpegKit.cancel(id));
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    final ok = await completer.future;
    if (!mounted || generation != _generation) return null;
    if (!ok) return const [];
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where(
            (file) => file.path.toLowerCase().endsWith('.$extension'),
          )
          .toList()
        ..sort(
          (a, b) => _frameIndex(a.path).compareTo(_frameIndex(b.path)),
        );
      return files.map((file) => file.path).toList();
    } catch (_) {
      return const [];
    }
  }

  int _frameIndex(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final match = RegExp(r'(\d+)').firstMatch(name);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  Future<void> _deleteDir(Directory dir, List<String> paths) async {
    for (final thumb in paths) {
      try {
        await FileImage(File(thumb)).evict();
      } catch (_) {
        // Cache eviction is best-effort.
      }
    }
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {
      // Temp thumbnail cleanup is best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineWidth = _timelineWidth;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(_radius)),
      child: SizedBox(
        height: _trackHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = constraints.maxWidth;
            final inset = _sideInset(viewport, timelineWidth);
            return Stack(
              fit: StackFit.expand,
              children: [
                SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: Padding(
                    padding: EdgeInsets.only(left: inset, right: inset),
                    child: _strip(timelineWidth),
                  ),
                ),
                _handles(inset: inset),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _strip(double timelineWidth) {
    final start = _msToX(widget.startMs);
    final end = _msToX(widget.endMs);
    final selection = math.max(0.0, end - start);
    return SizedBox(
      width: timelineWidth,
      height: _trackHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(_radius)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: widget.trackColor),
            ),
            Row(children: _slots(timelineWidth)),
            if (start > 0)
              Positioned(
                left: 0,
                width: start,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: widget.dimColor),
              ),
            if (end < timelineWidth)
              Positioned(
                left: end,
                right: 0,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: widget.dimColor),
              ),
            Positioned(
              left: start,
              width: selection,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(_radius),
                    ),
                    border: Border.all(color: widget.selectionColor, width: 3),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: widget.positionMs,
              builder: (context, ms, _) {
                final maxX = math.max(0.0, timelineWidth - 2);
                final x = _msToX(ms).clamp(0.0, maxX).toDouble();
                return Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.playheadColor,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xAA000000),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!_thumbsReady)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.progressColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _slots(double timelineWidth) {
    final count = _slotCount;
    final seconds = widget.totalMs <= 0 ? 0.0 : widget.totalMs / 1000;
    final children = <Widget>[];
    var used = 0.0;
    for (var i = 0; i < count; i++) {
      final width = i == count - 1
          ? math.max(0.0, timelineWidth - used)
          : _spanWidth(i, seconds);
      used += width;
      if (width <= 0) continue;
      children.add(
        SizedBox(
          width: width,
          height: _trackHeight,
          child: _thumbImage(i),
        ),
      );
    }
    return children;
  }

  double _spanWidth(int index, double seconds) {
    final start = index * _thumbnailEverySeconds;
    final span = math.min(
      _thumbnailEverySeconds,
      math.max(0.0, seconds - start),
    );
    return span * _pixelsPerSecond;
  }

  Widget _thumbImage(int index) {
    if (_thumbPaths.isEmpty) {
      return ColoredBox(color: widget.placeholderColor);
    }
    final path = _thumbPaths[math.min(index, _thumbPaths.length - 1)];
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheHeight: 160,
      errorBuilder: (_, __, ___) =>
          ColoredBox(color: widget.placeholderColor),
    );
  }

  Widget _handles({required double inset}) => ValueListenableBuilder<double>(
        valueListenable: _scrollOffset,
        builder: (context, offset, _) {
          final start = inset + _msToX(widget.startMs) - offset;
          final end = inset + _msToX(widget.endMs) - offset;
          final bodyLeft = start + 6 + _handleHitWidth;
          final bodyWidth = end - 6 - _handleHitWidth - bodyLeft;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (bodyWidth > 0)
                Positioned(
                  left: bodyLeft,
                  width: bodyWidth,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onHorizontalDragUpdate: (details) =>
                        _moveSelection(details.delta.dx),
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned(
                left: start + 6,
                top: 0,
                bottom: 0,
                child: _TrimHandle(
                  alignEnd: false,
                  color: widget.handleColor,
                  onDragUpdate: (details) => _moveEdge(
                    isStart: true,
                    dx: details.delta.dx,
                  ),
                ),
              ),
              Positioned(
                left: end - 6 - _handleHitWidth,
                top: 0,
                bottom: 0,
                child: _TrimHandle(
                  alignEnd: true,
                  color: widget.handleColor,
                  onDragUpdate: (details) => _moveEdge(
                    isStart: false,
                    dx: details.delta.dx,
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _TrimHandle extends StatelessWidget {
  const _TrimHandle({
    required this.alignEnd,
    required this.color,
    required this.onDragUpdate,
  });

  final bool alignEnd;
  final Color color;
  final GestureDragUpdateCallback onDragUpdate;

  @override
  Widget build(BuildContext context) => Semantics(
        label: alignEnd ? 'Trim end' : 'Trim start',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragUpdate: onDragUpdate,
          child: SizedBox(
            width: _VideoTrimTimelineState._handleHitWidth,
            child: Align(
              alignment:
                  alignEnd ? Alignment.centerRight : Alignment.centerLeft,
              child: SizedBox(
                width: 4,
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
