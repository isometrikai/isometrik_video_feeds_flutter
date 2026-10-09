import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_button.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/ism_custom_app_bar_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/ffmpeg_video_limit_util.dart';
import 'package:video_player/video_player.dart';

/// Crops, rotates, and flips a video, then returns the baked file path.
class VideoCropScreen extends StatefulWidget {
  const VideoCropScreen({
    super.key,
    required this.videoPath,
  });

  final String videoPath;

  @override
  State<VideoCropScreen> createState() => _VideoCropScreenState();
}

class _VideoCropScreenState extends State<VideoCropScreen> {
  late final VideoPlayerController _controller;
  var _ready = false;
  var _failed = false;
  var _playing = false;
  var _saving = false;
  var _quarterTurns = 0;
  var _flipHorizontal = false;
  var _flipVertical = false;
  var _ratio = _CropRatio.original;
  var _zoom = 1.0;
  var _minZoom = 1.0;
  var _angle = 0.0;
  var _pan = Offset.zero;
  Size? _freeBasis;
  Rect? _freeNorm;
  Size? _viewport;
  Rect? _limit;
  _CropWindow? _window;
  var _handlePointer = -1;
  var _movingHole = false;
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
      await _controller.setLooping(true);
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
  }

  double get _totalMs => _controller.value.duration.inMilliseconds.toDouble();

  double get _videoAspect {
    final size = _controller.value.size;
    if (size.width > 0 && size.height > 0) return size.width / size.height;
    final ratio = _controller.value.aspectRatio;
    if (ratio > 0) return ratio;
    return 9 / 16;
  }

  Color get _foreground => IsrColors.appBarIconTextColor;

  TextStyle get _titleStyle => TextStyle(
        color: _foreground,
        fontFamily: IsrAppConstants.primaryFontFamily,
      );

  TextStyle get _timeStyle => TextStyle(
        color: IsrColors.primaryTextColor,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  void _togglePlay() {
    if (_playing) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
  }

  void _seekTo(double ms) {
    unawaited(
      _controller.seekTo(Duration(milliseconds: ms.round())),
    );
  }

  void _resetFrame() {
    _zoom = 1;
    _minZoom = 1;
    _angle = 0;
    _pan = Offset.zero;
    _freeNorm = null;
  }

  double _wrapAngle(double angle) {
    var wrapped = angle % (2 * math.pi);
    if (wrapped > math.pi) wrapped -= 2 * math.pi;
    if (wrapped < -math.pi) wrapped += 2 * math.pi;
    return wrapped;
  }

  void _selectRatio(_CropRatio ratio) {
    if (ratio == _ratio) return;
    if (ratio == _CropRatio.free) {
      final viewport = _viewport;
      if (viewport != null && viewport.width > 0 && viewport.height > 0) {
        final basis = _frameSize(viewport, _ratio.aspect ?? _orientedAspect);
        _freeBasis = basis;
        final origin = Offset(
          (viewport.width - basis.width) / 2,
          (viewport.height - basis.height) / 2,
        );
        _freeNorm = _normRect(origin & basis, viewport);
      }
    } else {
      _freeBasis = null;
      _resetFrame();
    }
    _ratio = ratio;
  }

  double get _orientedAspect {
    final aspect = _videoAspect;
    return _quarterTurns.isOdd ? 1 / aspect : aspect;
  }

  String? _cropFilter() {
    if (_ratio == _CropRatio.original) return null;
    final window = _window;
    final source = _controller.value.size;
    if (window == null || source.width < 2 || source.height < 2) return null;
    final video = window.video;
    final hole = window.hole;
    if (video.width < 1 || video.height < 1) return null;
    final orientedW = _quarterTurns.isOdd ? source.height : source.width;
    final orientedH = _quarterTurns.isOdd ? source.width : source.height;
    final spinning = _angle.abs() > 0.001;
    final cosA = math.cos(_angle).abs();
    final sinA = math.sin(_angle).abs();
    final canvasW = spinning ? orientedW * cosA + orientedH * sinA : orientedW;
    final canvasH = spinning ? orientedW * sinA + orientedH * cosA : orientedH;
    final bounds = _rotatedBounds(video);
    if (bounds.width < 1 || bounds.height < 1) return null;
    final fracX = ((hole.left - bounds.left) / bounds.width).clamp(0.0, 1.0);
    final fracY = ((hole.top - bounds.top) / bounds.height).clamp(0.0, 1.0);
    final fracW = (hole.width / bounds.width).clamp(0.0, 1.0);
    final fracH = (hole.height / bounds.height).clamp(0.0, 1.0);
    if (!spinning && fracW > 0.995 && fracH > 0.995) return null;
    var width = (fracW * canvasW).floor();
    var height = (fracH * canvasH).floor();
    var x = (fracX * canvasW).floor();
    var y = (fracY * canvasH).floor();
    width = math.max(2, width - width % 2);
    height = math.max(2, height - height % 2);
    if (x + width > canvasW) x = math.max(0, canvasW.round() - width);
    if (y + height > canvasH) y = math.max(0, canvasH.round() - height);
    x = math.max(0, x - x % 2);
    y = math.max(0, y - y % 2);
    if (!spinning && width >= orientedW - 1 && height >= orientedH - 1) {
      return null;
    }
    return 'crop=$width:$height:$x:$y';
  }

  Future<void> _done() async {
    if (_saving) return;
    setState(() => _saving = true);
    final path = await FfmpegVideoLimitUtil.applyTransform(
      context: context,
      inputPath: widget.videoPath,
      quarterTurnsClockwise: _quarterTurns,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
      crop: _cropFilter(),
      rotateRadians: _angle.abs() > 0.001 ? _angle : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (path == null) return;
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: IsrColors.scaffoldColor,
        appBar: IsmCustomAppBarWidget(
          iconColor: _foreground,
          titleColor: _foreground,
          isCrossIcon: true,
          centerTitle: true,
          showActions: true,
          onTap: () => Navigator.of(context).pop(),
          titleWidget: Text('Crop', style: _titleStyle),
          actions: [
            IconButton(
              tooltip: 'Rotate',
              onPressed: () => setState(() {
                _quarterTurns = (_quarterTurns + 1) % 4;
                _freeBasis = null;
                _resetFrame();
              }),
              icon: Icon(Icons.rotate_right, color: _foreground),
            ),
            IconButton(
              tooltip: 'Flip horizontal',
              onPressed: () =>
                  setState(() => _flipHorizontal = !_flipHorizontal),
              icon: Icon(
                Icons.flip,
                color: _flipHorizontal ? IsrColors.appColor : _foreground,
              ),
            ),
            IconButton(
              tooltip: 'Flip vertical',
              onPressed: () => setState(() => _flipVertical = !_flipVertical),
              icon: Transform.rotate(
                angle: math.pi / 2,
                child: Icon(
                  Icons.flip,
                  color: _flipVertical ? IsrColors.appColor : _foreground,
                ),
              ),
            ),
          ],
        ),
        body: _failed
            ? Center(
                child: Text(
                  'Could not open this video',
                  style: TextStyle(
                    color: IsrColors.primaryTextColor,
                    fontFamily: IsrAppConstants.primaryFontFamily,
                  ),
                ),
              )
            : !_ready
                ? Center(
                    child: CircularProgressIndicator(color: IsrColors.appColor),
                  )
                : Column(
                    children: [
                      Expanded(child: _cropStage()),
                      _controls(),
                    ],
                  ),
      );

  Widget _cropStage() => LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final aspect = _orientedAspect;
          final isFree = _ratio == _CropRatio.free;
          final basis = isFree
              ? (_freeBasis ?? _frameSize(viewport, aspect))
              : _frameSize(viewport, _ratio.aspect ?? aspect);
          if (isFree) _freeBasis = basis;
          final origin = Offset(
            (viewport.width - basis.width) / 2,
            (viewport.height - basis.height) / 2,
          );
          final full = origin & basis;
          if (isFree && _freeNorm == null && viewport.width > 0) {
            _freeNorm = _normRect(full, viewport);
          }
          var hole = isFree ? _denorm(_freeNorm ?? _normRect(full, viewport), viewport) : full;
          final cover = hole.shift(-origin);
          final video = _videoRect(basis, aspect, cover);
          final videoScreen = video.shift(origin);
          final limit = _visibleVideo(videoScreen, viewport);
          if (isFree && !limit.isEmpty) {
            hole = _contain(hole, limit);
            _freeNorm = _normRect(hole, viewport);
          }
          _viewport = viewport;
          _limit = limit;
          _window = _CropWindow(video: videoScreen, hole: hole);
          final canMove = _ratio != _CropRatio.original;
          return SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: canMove ? () => setState(_resetFrame) : null,
              onScaleStart: (details) {
                _lastScale = 1;
                _lastRotation = 0;
                _movingHole = isFree &&
                    _handlePointer < 0 &&
                    details.pointerCount == 1 &&
                    hole.contains(details.localFocalPoint);
              },
              onScaleEnd: (_) => _movingHole = false,
              onScaleUpdate: (details) {
                if (!canMove || _handlePointer >= 0) return;
                if (_movingHole && details.pointerCount == 1) {
                  _moveFreeHole(details.focalPointDelta);
                  return;
                }
                setState(() {
                  if (details.pointerCount >= 2) {
                    _angle = _wrapAngle(_angle + _rotationStep(details));
                  } else {
                    _lastRotation = details.rotation;
                  }
                  final cap = math.max(4.0, _minZoom);
                  _zoom = (_zoom * _scaleStep(details)).clamp(_minZoom, cap);
                  _pan += details.focalPointDelta;
                });
              },
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fromRect(
                      rect: videoScreen,
                      child: _orientedVideo(),
                    ),
                    if (canMove) Positioned.fill(child: _dimAround(hole)),
                    if (isFree) _grid(hole),
                    Positioned.fromRect(
                      rect: hole,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    if (isFree)
                      for (final handle in _CropHandle.values) _handle(handle, hole),
                  ],
                ),
              ),
            ),
          );
        },
      );

  /// [ScaleUpdateDetails.scale] and [ScaleUpdateDetails.rotation] are
  /// cumulative for the gesture, so only the latest step is applied.
  double _lastScale = 1;
  double _lastRotation = 0;

  double _scaleStep(ScaleUpdateDetails details) {
    final next = details.scale <= 0 ? 1.0 : details.scale;
    final step = _lastScale <= 0 ? 1.0 : next / _lastScale;
    _lastScale = next;
    return step;
  }

  double _rotationStep(ScaleUpdateDetails details) {
    final step = details.rotation - _lastRotation;
    _lastRotation = details.rotation;
    return step;
  }

  Widget _orientedVideo() => Transform.rotate(
        angle: _angle,
        child: FittedBox(
          fit: BoxFit.fill,
          child: RotatedBox(
            quarterTurns: _quarterTurns,
            child: Transform.flip(
              flipX: _flipHorizontal,
              flipY: _flipVertical,
              child: SizedBox(
                width: _videoAspect * 1000,
                height: 1000,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
      );

  Size _frameSize(Size viewport, double aspect) {
    if (viewport.width <= 0 || viewport.height <= 0) return Size.zero;
    final fitted = viewport.width / viewport.height > aspect
        ? Size(viewport.height * aspect, viewport.height)
        : Size(viewport.width, viewport.width / aspect);
    return fitted;
  }

  Rect _videoRect(Size frame, double aspect, Rect cover) {
    if (frame.width <= 0 || frame.height <= 0) return Rect.zero;
    final motion = _ratio != _CropRatio.original;
    final minZoom = motion ? _minCoverZoom(frame, aspect, cover) : 1.0;
    _minZoom = minZoom;
    if (motion && _zoom < minZoom) _zoom = minZoom;
    final zoom = motion ? _zoom : 1.0;
    final frameAspect = frame.width / frame.height;
    final double width;
    final double height;
    if (aspect > frameAspect) {
      height = frame.height * zoom;
      width = height * aspect;
    } else {
      width = frame.width * zoom;
      height = width / aspect;
    }
    final centerX = (frame.width - width) / 2;
    final centerY = (frame.height - height) / 2;
    final pan = motion
        ? _clampRotatedPan(
            pan: _pan,
            frame: frame,
            width: width,
            height: height,
            cover: cover,
          )
        : Offset.zero;
    if (motion) _pan = pan;
    return Rect.fromLTWH(centerX + pan.dx, centerY + pan.dy, width, height);
  }

  double _minCoverZoom(Size frame, double aspect, Rect cover) {
    if (_angle.abs() < 0.001 || frame.width <= 0 || cover.width <= 0) {
      return 1;
    }
    final frameAspect = frame.width / frame.height;
    final double baseW;
    if (aspect > frameAspect) {
      baseW = frame.height * aspect;
    } else {
      baseW = frame.width;
    }
    if (baseW <= 0) return 1;
    final cosA = math.cos(_angle).abs();
    final sinA = math.sin(_angle).abs();
    final aabbW = cover.width * cosA + cover.height * sinA;
    final aabbH = cover.width * sinA + cover.height * cosA;
    final needW = math.max(aabbW, aabbH * aspect);
    return math.max(1.0, needW / baseW);
  }

  Offset _clampRotatedPan({
    required Offset pan,
    required Size frame,
    required double width,
    required double height,
    required Rect cover,
  }) {
    final base = Offset(frame.width / 2, frame.height / 2);
    if (width < 1 || height < 1) {
      return Offset(cover.center.dx - base.dx, cover.center.dy - base.dy);
    }
    final cosA = math.cos(_angle);
    final sinA = math.sin(_angle);
    final halfW = width / 2;
    final halfH = height / 2;
    var minX = -double.infinity;
    var maxX = double.infinity;
    var minY = -double.infinity;
    var maxY = double.infinity;
    for (final corner in <Offset>[
      cover.topLeft,
      cover.topRight,
      cover.bottomRight,
      cover.bottomLeft,
    ]) {
      final delta = corner - base;
      final localX = delta.dx * cosA + delta.dy * sinA;
      final localY = -delta.dx * sinA + delta.dy * cosA;
      minX = math.max(minX, localX - halfW);
      maxX = math.min(maxX, localX + halfW);
      minY = math.max(minY, localY - halfH);
      maxY = math.min(maxY, localY + halfH);
    }
    if (maxX < minX || maxY < minY) {
      return Offset(cover.center.dx - base.dx, cover.center.dy - base.dy);
    }
    final turnedX = pan.dx * cosA + pan.dy * sinA;
    final turnedY = -pan.dx * sinA + pan.dy * cosA;
    final clampedX = _clampTo(turnedX, minX, maxX);
    final clampedY = _clampTo(turnedY, minY, maxY);
    return Offset(
      clampedX * cosA - clampedY * sinA,
      clampedX * sinA + clampedY * cosA,
    );
  }

  Rect _rotatedBounds(Rect video) {
    final cosA = math.cos(_angle).abs();
    final sinA = math.sin(_angle).abs();
    return Rect.fromCenter(
      center: video.center,
      width: video.width * cosA + video.height * sinA,
      height: video.width * sinA + video.height * cosA,
    );
  }

  Rect _visibleVideo(Rect video, Size viewport) {
    final bounds = Offset.zero & viewport;
    if (video.overlaps(bounds)) return video.intersect(bounds);
    return Rect.zero;
  }

  Rect _contain(Rect hole, Rect limit) {
    final minW = math.min(64.0, limit.width);
    final minH = math.min(64.0, limit.height);
    final width = hole.width.clamp(minW, limit.width).toDouble();
    final height = hole.height.clamp(minH, limit.height).toDouble();
    final left = _clampTo(hole.left, limit.left, limit.right - width);
    final top = _clampTo(hole.top, limit.top, limit.bottom - height);
    return Rect.fromLTWH(left, top, width, height);
  }

  double _clampTo(double value, double lower, double upper) {
    if (upper < lower) return lower;
    return value.clamp(lower, upper).toDouble();
  }

  Rect _normRect(Rect hole, Size viewport) => Rect.fromLTWH(
        hole.left / viewport.width,
        hole.top / viewport.height,
        hole.width / viewport.width,
        hole.height / viewport.height,
      );

  Rect _denorm(Rect norm, Size viewport) => Rect.fromLTWH(
        norm.left * viewport.width,
        norm.top * viewport.height,
        norm.width * viewport.width,
        norm.height * viewport.height,
      );

  void _moveFreeHole(Offset delta) {
    final viewport = _viewport;
    final limit = _limit;
    final norm = _freeNorm;
    if (viewport == null || limit == null || norm == null || limit.isEmpty) {
      return;
    }
    final current = _contain(_denorm(norm, viewport), limit);
    final dx = _clampTo(
      delta.dx,
      limit.left - current.left,
      limit.right - current.right,
    );
    final dy = _clampTo(
      delta.dy,
      limit.top - current.top,
      limit.bottom - current.bottom,
    );
    setState(() => _freeNorm = _normRect(current.shift(Offset(dx, dy)), viewport));
  }

  void _onHandleMove(_CropHandle handle, Offset delta) {
    final viewport = _viewport;
    final limit = _limit;
    final norm = _freeNorm;
    if (viewport == null || limit == null || norm == null || limit.isEmpty) {
      return;
    }
    final minW = math.min(64.0, limit.width);
    final minH = math.min(64.0, limit.height);
    final start = _denorm(norm, viewport);
    var left = start.left;
    var top = start.top;
    var right = start.right;
    var bottom = start.bottom;
    if (handle.movesLeft) {
      left = _clampTo(left + delta.dx, limit.left, right - minW);
    }
    if (handle.movesRight) {
      right = _clampTo(right + delta.dx, left + minW, limit.right);
    }
    if (handle.movesTop) {
      top = _clampTo(top + delta.dy, limit.top, bottom - minH);
    }
    if (handle.movesBottom) {
      bottom = _clampTo(bottom + delta.dy, top + minH, limit.bottom);
    }
    setState(
      () => _freeNorm = _normRect(Rect.fromLTRB(left, top, right, bottom), viewport),
    );
  }

  Widget _grid(Rect hole) => IgnorePointer(
        child: Stack(
          children: [
            for (var i = 1; i <= 2; i++) ...[
              Positioned(
                left: hole.left + hole.width * i / 3,
                top: hole.top,
                width: 1,
                height: hole.height,
                child: const ColoredBox(color: Color(0x66FFFFFF)),
              ),
              Positioned(
                left: hole.left,
                top: hole.top + hole.height * i / 3,
                width: hole.width,
                height: 1,
                child: const ColoredBox(color: Color(0x66FFFFFF)),
              ),
            ],
          ],
        ),
      );

  Widget _handle(_CropHandle handle, Rect hole) {
    const hit = 32.0;
    final anchor = handle.anchor(hole);
    final bar = handle.isEdge;
    final size = handle == _CropHandle.top || handle == _CropHandle.bottom
        ? const Size(22, 4)
        : bar
            ? const Size(4, 22)
            : const Size(12, 12);
    return Positioned(
      left: anchor.dx - hit / 2,
      top: anchor.dy - hit / 2,
      width: hit,
      height: hit,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _handlePointer = event.pointer,
        onPointerUp: (event) {
          if (_handlePointer == event.pointer) _handlePointer = -1;
        },
        onPointerCancel: (event) {
          if (_handlePointer == event.pointer) _handlePointer = -1;
        },
        onPointerMove: (event) {
          if (event.pointer != _handlePointer) return;
          _onHandleMove(handle, event.delta);
        },
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(bar ? 1 : 2),
            ),
            child: SizedBox(width: size.width, height: size.height),
          ),
        ),
      ),
    );
  }

  Widget _dimAround(Rect hole) => IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: math.max(0, hole.top),
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned(
              left: 0,
              top: hole.bottom,
              right: 0,
              bottom: 0,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned(
              left: 0,
              top: hole.top,
              width: math.max(0, hole.left),
              height: hole.height,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned(
              left: hole.right,
              top: hole.top,
              right: 0,
              height: hole.height,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
          ],
        ),
      );

  Widget _ratioBar() => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _CropRatio.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final ratio = _CropRatio.values[index];
            final selected = ratio == _ratio;
            return ChoiceChip(
              label: Text(ratio.label),
              selected: selected,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected ? Colors.white : IsrColors.primaryTextColor,
                fontFamily: IsrAppConstants.primaryFontFamily,
                fontSize: 13,
              ),
              selectedColor: IsrColors.appColor,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: selected ? IsrColors.appColor : IsrColors.secondaryTextColor,
              ),
              onSelected: (_) => setState(() => _selectRatio(ratio)),
            );
          },
        ),
      );

  Widget _controls() {
    final total = Duration(milliseconds: _totalMs.round());
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ratioBar(),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: _playing ? 'Pause' : 'Play',
                  onPressed: _togglePlay,
                  icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: IsrColors.primaryTextColor,
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _positionMs,
                    builder: (context, positionMs, _) {
                      final position =
                          Duration(milliseconds: positionMs.round());
                      return Text(
                        '${_clock(position)} / ${_clock(total)}',
                        style: _timeStyle,
                      );
                    },
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<double>(
              valueListenable: _positionMs,
              builder: (context, positionMs, _) {
                final max = _totalMs <= 0 ? 1.0 : _totalMs;
                return Slider(
                  value: positionMs.clamp(0.0, max).toDouble(),
                  max: max,
                  activeColor: IsrColors.appColor,
                  onChanged: _seekTo,
                );
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              title: 'Done',
              isLoading: _saving,
              isDisable: _saving,
              onPress: _done,
            ),
          ],
        ),
      ),
    );
  }

  String _clock(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _CropWindow {
  const _CropWindow({
    required this.video,
    required this.hole,
  });

  final Rect video;
  final Rect hole;
}

enum _CropRatio {
  original('Original'),
  free('Free'),
  reel('9:16', 9 / 16),
  square('1:1', 1),
  portrait('4:5', 4 / 5),
  landscape('16:9', 16 / 9);

  const _CropRatio(this.label, [this.aspect]);

  final String label;
  final double? aspect;
}

enum _CropHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left;

  bool get movesLeft =>
      this == topLeft || this == left || this == bottomLeft;

  bool get movesRight =>
      this == topRight || this == right || this == bottomRight;

  bool get movesTop => this == topLeft || this == top || this == topRight;

  bool get movesBottom =>
      this == bottomLeft || this == bottom || this == bottomRight;

  bool get isEdge =>
      this == top || this == right || this == bottom || this == left;

  Offset anchor(Rect hole) {
    switch (this) {
      case topLeft:
        return hole.topLeft;
      case top:
        return hole.topCenter;
      case topRight:
        return hole.topRight;
      case right:
        return hole.centerRight;
      case bottomRight:
        return hole.bottomRight;
      case bottom:
        return hole.bottomCenter;
      case bottomLeft:
        return hole.bottomLeft;
      case left:
        return hole.centerLeft;
    }
  }
}
