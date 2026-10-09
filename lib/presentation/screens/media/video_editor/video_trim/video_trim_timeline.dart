import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_trim/video_trim_ui_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:path_provider/path_provider.dart';

/// Scrollable filmstrip for choosing a trim range.
///
/// One second of video is [pixelsPerSecond] logical pixels wide.
/// The strip is never narrower than the allotted track width.
/// Each still matches the frame at the strip height, and pages of stills
/// load as the strip scrolls.
class VideoTrimTimeline extends StatefulWidget {
  const VideoTrimTimeline({
    super.key,
    required this.videoPath,
    required this.videoAspect,
    required this.totalMs,
    required this.startMs,
    required this.endMs,
    required this.positionMs,
    required this.pixelsPerSecond,
    required this.onChanged,
  });

  final String videoPath;

  /// Video width divided by video height.
  final double videoAspect;

  final double totalMs;
  final double startMs;
  final double endMs;
  final ValueListenable<double> positionMs;

  /// Logical pixels drawn for each second of video.
  final double pixelsPerSecond;

  final ValueChanged<RangeValues> onChanged;

  @override
  State<VideoTrimTimeline> createState() => _VideoTrimTimelineState();
}

class _VideoTrimTimelineState extends State<VideoTrimTimeline> {
  static const _defaultPageSize = 20;
  static const _defaultTrackHeight = 58.0;
  static const _defaultRadius = 6.0;
  static const _defaultBorderWidth = 3.0;
  static const _defaultHandleHitWidth = 28.0;
  static const _defaultHandleWidth = 4.0;
  static const _defaultHandleHeight = 36.0;

  final _scroll = ScrollController();
  final _scrollOffset = ValueNotifier<double>(0);
  var _layoutScale = 1.0;
  var _viewport = 0.0;
  var _scheduledEnsure = false;

  var _generation = 0;
  int? _loadingPage;
  var _preferPng = false;
  final _loadedPages = <int>{};
  final _thumbs = <int, String>{};
  Directory? _thumbDir;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_publishScroll);
  }

  @override
  void didUpdateWidget(covariant VideoTrimTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pathChanged = oldWidget.videoPath != widget.videoPath;
    final aspectChanged =
        (oldWidget.videoAspect - widget.videoAspect).abs() > 0.001;
    if (!pathChanged && !aspectChanged) return;
    _invalidateThumbs();
    _viewport = 0;
  }

  @override
  void dispose() {
    _invalidateThumbs();
    _scroll
      ..removeListener(_publishScroll)
      ..dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _publishScroll() {
    _scrollOffset.value = _scroll.offset;
    _ensureVisiblePages();
  }

  VideoTrimUIConfig? get _ui => IsrVideoReelConfig
      .createEditPostConfig
      .createEditPostUIConfig
      ?.videoTrimUIConfig;

  double _positive(double? value, double fallback) =>
      value != null && value > 0 ? value : fallback;

  int get _pageSize {
    final size = _ui?.thumbnailPageSize;
    return size != null && size > 0 ? size : _defaultPageSize;
  }

  double get _trackHeight => _positive(_ui?.trackHeight, _defaultTrackHeight);

  double get _radius => _positive(_ui?.borderRadius, _defaultRadius);

  double get _borderWidth =>
      _positive(_ui?.selectionBorderWidth, _defaultBorderWidth);

  double get _handleHitWidth =>
      _positive(_ui?.handleHitWidth, _defaultHandleHitWidth);

  double get _handleWidth => _positive(_ui?.handleWidth, _defaultHandleWidth);

  double get _handleHeight =>
      _positive(_ui?.handleHeight, _defaultHandleHeight);

  Color get _selectionColor => _ui?.selectionColor ?? IsrColors.appColor;

  Color get _handleColor => _ui?.handleColor ?? IsrColors.white;

  Color get _playheadColor => _ui?.playheadColor ?? IsrColors.white;

  Color get _trackColor => _ui?.trackColor ?? const Color(0xFF1A1A1A);

  Color get _dimColor => _ui?.dimColor ?? const Color(0x99000000);

  Color get _placeholderColor =>
      _ui?.placeholderColor ?? const Color(0xFF2C2C2E);

  Color get _progressColor => _ui?.progressColor ?? _selectionColor;

  double get _basePixelsPerSecond {
    final scale = widget.pixelsPerSecond;
    return scale > 0 ? scale : 1;
  }

  /// Raises the base scale when the video would be shorter than [allottedWidth].
  double _scaleFor(double allottedWidth) {
    final seconds = widget.totalMs / 1000;
    final base = _basePixelsPerSecond;
    if (seconds <= 0 || !allottedWidth.isFinite || allottedWidth <= 0) {
      return base;
    }
    final minimum = allottedWidth / seconds;
    return base < minimum ? minimum : base;
  }

  double get _pixelsPerSecond => _layoutScale;

  double get _timelineWidth {
    final seconds = widget.totalMs / 1000;
    if (seconds <= 0) return 1;
    return seconds * _pixelsPerSecond;
  }

  double get _thumbWidth {
    final aspect = widget.videoAspect > 0 ? widget.videoAspect : 9 / 16;
    final width = _trackHeight * aspect;
    return width < 1 ? 1 : width;
  }

  double get _intervalSeconds {
    final interval = _thumbWidth / _pixelsPerSecond;
    return interval < 0.05 ? 0.05 : interval;
  }

  int get _slotCount {
    final seconds = widget.totalMs / 1000;
    if (seconds <= 0) return 1;
    return math.max(1, (seconds / _intervalSeconds).ceil());
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

  void _noteLayout(double allotted) {
    final scale = _scaleFor(allotted);
    final viewport = allotted.isFinite && allotted > 0 ? allotted : 0.0;
    final scaleChanged = (scale - _layoutScale).abs() > 0.01;
    final viewportChanged = (viewport - _viewport).abs() > 1;
    if (!scaleChanged && !viewportChanged) return;
    final hadThumbs = _thumbs.isNotEmpty || _loadingPage != null;
    _layoutScale = scale;
    if (viewport <= 0) return;
    _viewport = viewport;
    if (scaleChanged && hadThumbs) _invalidateThumbs();
    _scheduleEnsure();
  }

  void _scheduleEnsure() {
    if (_scheduledEnsure) return;
    _scheduledEnsure = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledEnsure = false;
      if (!mounted) return;
      _ensureVisiblePages();
    });
  }

  void _ensureVisiblePages() {
    if (!mounted || _viewport <= 0 || _slotCount <= 0) return;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final needed = _pagesCovering(offset)
        .where((page) => !_loadedPages.contains(page))
        .toList();
    if (needed.isEmpty) return;
    final next = needed.first;
    if (_loadingPage == next) return;
    unawaited(_loadPage(next));
  }

  List<int> _pagesCovering(double offset) {
    final width = _thumbWidth;
    final lastSlot = _slotCount - 1;
    final first = (offset / width).floor().clamp(0, lastSlot);
    final last = ((offset + _viewport) / width).ceil().clamp(0, lastSlot);
    final startPage = first ~/ _pageSize;
    final endPage = last ~/ _pageSize;
    return [for (var page = startPage; page <= endPage; page++) page];
  }

  void _invalidateThumbs() {
    _generation++;
    final sessionId = _sessionId;
    _sessionId = null;
    _loadingPage = null;
    if (sessionId != null) unawaited(FFmpegKit.cancel(sessionId));
    final dir = _thumbDir;
    final paths = _thumbs.values.toList();
    _thumbs.clear();
    _loadedPages.clear();
    _preferPng = false;
    _thumbDir = null;
    if (dir != null) unawaited(_deleteDir(dir, paths));
  }

  Future<void> _loadPage(int page) async {
    if (_loadedPages.contains(page)) return;
    final start = page * _pageSize;
    final total = _slotCount;
    if (start >= total) return;
    final count = math.min(_pageSize, total - start);
    final interval = _intervalSeconds;
    final generation = ++_generation;
    final previousSession = _sessionId;
    _sessionId = null;
    if (previousSession != null) unawaited(FFmpegKit.cancel(previousSession));
    if (!mounted || generation != _generation) return;
    setState(() => _loadingPage = page);

    final dir = await _ensureDir();
    if (dir == null || !mounted || generation != _generation) return;

    final extension = _preferPng ? 'png' : 'webp';
    final codec = _preferPng
        ? const <String>[]
        : const ['-c:v', 'libwebp', '-quality', '70'];
    var paths = await _extract(
      generation: generation,
      dir: dir,
      page: page,
      startSeconds: start * interval,
      frames: count,
      interval: interval,
      extension: extension,
      codec: codec,
    );
    if (!mounted || generation != _generation || paths == null) return;
    if (paths.isEmpty && !_preferPng) {
      _preferPng = true;
      paths = await _extract(
        generation: generation,
        dir: dir,
        page: page,
        startSeconds: start * interval,
        frames: count,
        interval: interval,
        extension: 'png',
        codec: const [],
      );
      if (!mounted || generation != _generation || paths == null) return;
    }
    final thumbs = paths;
    setState(() {
      for (var i = 0; i < thumbs.length && i < count; i++) {
        _thumbs[start + i] = thumbs[i];
      }
      _loadedPages.add(page);
      if (_loadingPage == page) _loadingPage = null;
    });
    _ensureVisiblePages();
  }

  Future<Directory?> _ensureDir() async {
    final existing = _thumbDir;
    if (existing != null) return existing;
    final temp = await getTemporaryDirectory();
    if (!mounted) return null;
    final dir = Directory(
      '${temp.path}/trim_thumbs_${DateTime.now().microsecondsSinceEpoch}',
    );
    await dir.create(recursive: true);
    if (!mounted) {
      await _deleteDir(dir, const []);
      return null;
    }
    _thumbDir = dir;
    return dir;
  }

  /// Null when this generation was cancelled. Empty when FFmpeg wrote nothing.
  Future<List<String>?> _extract({
    required int generation,
    required Directory dir,
    required int page,
    required double startSeconds,
    required int frames,
    required double interval,
    required String extension,
    required List<String> codec,
  }) async {
    final output = '${dir.path}/p${page}_%05d.$extension';
    final completer = Completer<bool?>();
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        [
          '-y',
          '-ss',
          startSeconds.toStringAsFixed(3),
          '-i',
          widget.videoPath,
          '-an',
          '-vf',
          'fps=1/${interval.toStringAsFixed(4)},scale=-2:160',
          '-frames:v',
          '$frames',
          ...codec,
          output,
        ],
        (completed) async {
          if (completer.isCompleted) return;
          final code = await completed.getReturnCode();
          if (ReturnCode.isCancel(code)) {
            completer.complete(null);
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
    if (!mounted || generation != _generation || ok == null) return null;
    if (!ok) return const [];
    try {
      final prefix = 'p${page}_';
      final files = dir
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = file.path.split(Platform.pathSeparator).last;
            return name.startsWith(prefix) &&
                name.toLowerCase().endsWith('.$extension');
          })
          .toList()
        ..sort(
          (a, b) => _sequenceIndex(a.path).compareTo(_sequenceIndex(b.path)),
        );
      return files.map((file) => file.path).toList();
    } catch (_) {
      return const [];
    }
  }

  int _sequenceIndex(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final match = RegExp(r'_(\d+)').firstMatch(name);
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
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        child: SizedBox(
          height: _trackHeight,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final allotted = constraints.maxWidth;
              _noteLayout(allotted);
              final timelineWidth = _timelineWidth;
              final viewport = allotted.isFinite ? allotted : timelineWidth;
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

  Widget _strip(double timelineWidth) {
    final start = _msToX(widget.startMs);
    final end = _msToX(widget.endMs);
    final selection = math.max(0.0, end - start);
    return SizedBox(
      width: timelineWidth,
      height: _trackHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: _trackColor),
            ),
            Row(children: _slots(timelineWidth)),
            if (start > 0)
              Positioned(
                left: 0,
                width: start,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: _dimColor),
              ),
            if (end < timelineWidth)
              Positioned(
                left: end,
                right: 0,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: _dimColor),
              ),
            Positioned(
              left: start,
              width: selection,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(_radius),
                    ),
                    border: Border.all(
                      color: _selectionColor,
                      width: _borderWidth,
                    ),
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
                        color: _playheadColor,
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
            if (_loadingPage != null && _thumbs.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _progressColor,
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
    final start = index * _intervalSeconds;
    final span = math.min(
      _intervalSeconds,
      math.max(0.0, seconds - start),
    );
    return span * _pixelsPerSecond;
  }

  Widget _thumbImage(int index) {
    final path = _thumbs[index];
    if (path == null) {
      return ColoredBox(color: _placeholderColor);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheHeight: 160,
      errorBuilder: (_, __, ___) =>
          ColoredBox(color: _placeholderColor),
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
                  color: _handleColor,
                  hitWidth: _handleHitWidth,
                  thickness: _handleWidth,
                  height: _handleHeight,
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
                  color: _handleColor,
                  hitWidth: _handleHitWidth,
                  thickness: _handleWidth,
                  height: _handleHeight,
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
    required this.hitWidth,
    required this.thickness,
    required this.height,
    required this.onDragUpdate,
  });

  final bool alignEnd;
  final Color color;
  final double hitWidth;
  final double thickness;
  final double height;
  final GestureDragUpdateCallback onDragUpdate;

  @override
  Widget build(BuildContext context) => Semantics(
        label: alignEnd ? 'Trim end' : 'Trim start',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragUpdate: onDragUpdate,
          child: SizedBox(
            width: hitWidth,
            child: Align(
              alignment:
                  alignEnd ? Alignment.centerRight : Alignment.centerLeft,
              child: SizedBox(
                width: thickness,
                height: height,
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
