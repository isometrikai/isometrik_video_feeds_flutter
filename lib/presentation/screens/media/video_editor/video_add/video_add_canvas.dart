import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_catalog.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_draft.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';

/// Paints a saved Add document. Pointers pass through to the video.
class VideoAddOverlay extends StatelessWidget {
  const VideoAddOverlay({
    super.key,
    required this.document,
    this.preview,
  });

  final VideoAddDocument document;
  final VideoAddStroke? preview;

  @override
  Widget build(BuildContext context) => _AddCanvas(
        document: document,
        preview: preview,
      );
}

enum _Handle { scale, rotate, delete }

enum _Mode { move, scale, rotate, pinch }

class _Gesture {
  _Gesture({
    required this.id,
    required this.mode,
    required this.origin,
    required this.start,
    required this.scale,
    required this.rotation,
  });

  final int id;
  _Mode mode;
  bool moved = false;
  final VideoAddPoint origin;
  final Offset start;
  double scale;
  double rotation;
  double distance = 1;
  double angle = 0;
}

/// Interactive overlay layer: move, scale, rotate, draw, and delete.
class VideoAddStage extends StatefulWidget {
  const VideoAddStage({
    super.key,
    required this.document,
    required this.onDocument,
    this.selectedId,
    this.ghost,
    this.drawing = false,
    this.drawTool = VideoAddDrawTool.freehand,
    this.drawColor = const Color(0xFFD92D20),
    this.strokeSlider = 35,
    this.onSelect,
    this.onEditText,
    this.onDelete,
    this.onDeselect,
    this.onGestureStart,
    this.onGestureEnd,
    this.onStroke,
  });

  final Color drawColor;
  final VideoAddDrawTool drawTool;
  final bool drawing;
  final VideoAddDocument document;
  final VideoAddItem? ghost;
  final VoidCallback? onDeselect;
  final ValueChanged<int>? onDelete;
  final ValueChanged<VideoAddDocument> onDocument;
  final ValueChanged<int>? onEditText;
  final VoidCallback? onGestureEnd;
  final VoidCallback? onGestureStart;
  final ValueChanged<int>? onSelect;
  final ValueChanged<VideoAddStroke>? onStroke;
  final int? selectedId;
  final double strokeSlider;

  @override
  State<VideoAddStage> createState() => _VideoAddStageState();
}

class _VideoAddStageState extends State<VideoAddStage> {
  final Map<int, GlobalKey> _keys = {};
  final Map<int, Offset> _pointers = {};

  _Gesture? _gesture;
  _Handle? _pressedHandle;
  int? _pressedItem;
  VideoAddStroke? _preview;
  VideoAddPoint? _drawStart;
  VideoAddPoint? _drawEnd;
  List<VideoAddPoint> _drawPoints = const [];

  GlobalKey _keyFor(int id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    for (final pointer in _pointers.keys.toList()) {
      GestureBinding.instance.pointerRouter.removeRoute(pointer, _route);
    }
    super.dispose();
  }

  void _track(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, _route);
  }

  void _route(PointerEvent event) {
    if (event is PointerMoveEvent) {
      _pointers[event.pointer] = event.position;
      _onMove(event);
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);
      GestureBinding.instance.pointerRouter.removeRoute(event.pointer, _route);
      if (_pointers.isEmpty) _onUp();
    }
  }

  void _onDown(PointerDownEvent event) {
    _track(event);
    if (widget.drawing) {
      _pressedItem = null;
      _pressedHandle = null;
      _startDraw(event);
      return;
    }
    final itemId = _pressedItem;
    final handle = _pressedHandle;
    _pressedItem = null;
    _pressedHandle = null;
    if (itemId != null && handle == _Handle.delete) {
      widget.onDelete?.call(itemId);
      return;
    }
    if (itemId == null) {
      widget.onDeselect?.call();
      return;
    }
    final item = widget.document.item(itemId);
    final box = context.findRenderObject() as RenderBox?;
    if (item == null || box == null || !box.hasSize) return;
    widget.onSelect?.call(itemId);
    widget.onGestureStart?.call();
    final center = Offset(item.x * box.size.width, item.y * box.size.height);
    final local = box.globalToLocal(event.position);
    _gesture = _Gesture(
      id: itemId,
      mode: switch (handle) {
        _Handle.scale => _Mode.scale,
        _Handle.rotate => _Mode.rotate,
        _Handle.delete => _Mode.move,
        null => _Mode.move,
      },
      origin: VideoAddPoint(item.x, item.y),
      start: event.position,
      scale: item.scale,
      rotation: item.rotation,
    );
    _gesture!.distance = math.max(1, (local - center).distance);
  }

  void _onMove(PointerMoveEvent event) {
    if (widget.drawing) {
      _moveDraw(event);
      return;
    }
    final gesture = _gesture;
    if (gesture == null) return;
    if (_pointers.length >= 2 && gesture.mode != _Mode.pinch) {
      _beginPinch(gesture);
    }
    final item = widget.document.item(gesture.id);
    final box = context.findRenderObject() as RenderBox?;
    if (item == null || box == null || !box.hasSize) return;
    final size = box.size;
    if (gesture.mode == _Mode.move) {
      final delta = event.position - gesture.start;
      if (!gesture.moved && delta.distance < 5) return;
      gesture.moved = true;
      final next = item.copyWith(
        x: VideoAddDocument.clampPosition(
          gesture.origin.x + delta.dx / size.width,
        ),
        y: VideoAddDocument.clampPosition(
          gesture.origin.y + delta.dy / size.height,
        ),
      );
      widget.onDocument(widget.document.updateItem(next));
      return;
    }
    gesture.moved = true;
    if (gesture.mode == _Mode.scale) {
      final local = box.globalToLocal(event.position);
      final center = Offset(item.x * size.width, item.y * size.height);
      widget.onDocument(
        widget.document.updateItem(
          item.copyWith(
            scale: VideoAddDocument.clampScale(
              gesture.scale * (local - center).distance / gesture.distance,
            ),
          ),
        ),
      );
      return;
    }
    if (gesture.mode == _Mode.rotate) {
      final local = box.globalToLocal(event.position);
      final center = Offset(item.x * size.width, item.y * size.height);
      final angle = math.atan2(local.dy - center.dy, local.dx - center.dx);
      widget.onDocument(
        widget.document.updateItem(
          item.copyWith(rotation: angle * 180 / math.pi + 90),
        ),
      );
      return;
    }
    if (_pointers.length < 2) return;
    final points = _pointers.values.toList();
    final delta = points[1] - points[0];
    final distance = math.max(1, delta.distance);
    final angle = math.atan2(delta.dy, delta.dx);
    widget.onDocument(
      widget.document.updateItem(
        item.copyWith(
          scale: VideoAddDocument.clampScale(
            gesture.scale * distance / gesture.distance,
          ),
          rotation: gesture.rotation + (angle - gesture.angle) * 180 / math.pi,
        ),
      ),
    );
  }

  void _beginPinch(_Gesture gesture) {
    final item = widget.document.item(gesture.id);
    if (item == null || _pointers.length < 2) return;
    final points = _pointers.values.toList();
    final delta = points[1] - points[0];
    gesture
      ..mode = _Mode.pinch
      ..moved = true
      ..scale = item.scale
      ..rotation = item.rotation
      ..distance = math.max(1.0, delta.distance)
      ..angle = math.atan2(delta.dy, delta.dx);
  }

  void _onUp() {
    if (widget.drawing) {
      _endDraw();
      return;
    }
    final gesture = _gesture;
    _gesture = null;
    if (gesture == null) return;
    final item = widget.document.item(gesture.id);
    if (item != null && !gesture.moved && item.type == VideoAddItemType.text) {
      widget.onEditText?.call(item.id);
    }
    widget.onGestureEnd?.call();
    setState(() {});
  }

  void _startDraw(PointerDownEvent event) {
    final point = _point(event.position);
    if (point == null) return;
    _drawStart = point;
    _drawEnd = point;
    _drawPoints = [point];
    if (widget.drawTool == VideoAddDrawTool.eraser) {
      widget.onGestureStart?.call();
      _erase(point);
      return;
    }
    setState(() {
      _preview = _stroke(_drawPoints);
    });
  }

  void _moveDraw(PointerMoveEvent event) {
    final point = _point(event.position);
    final start = _drawStart;
    if (point == null || start == null) return;
    if (widget.drawTool == VideoAddDrawTool.eraser) {
      _erase(point);
      return;
    }
    final aspect = _aspect();
    final width = VideoAddGeometry.widthFraction(widget.strokeSlider);
    _drawEnd = point;
    final points = switch (widget.drawTool) {
      VideoAddDrawTool.freehand => [..._drawPoints, point],
      VideoAddDrawTool.line => [start, point],
      VideoAddDrawTool.arrow => VideoAddGeometry.arrow(
          start: start,
          end: point,
          width: width,
          aspect: aspect,
        ),
      VideoAddDrawTool.rectangle => VideoAddGeometry.rectangle(start, point),
      VideoAddDrawTool.circle => VideoAddGeometry.circle(
          center: start,
          edge: point,
          aspect: aspect,
        ),
      VideoAddDrawTool.eraser => _drawPoints,
    };
    _drawPoints = points;
    setState(() => _preview = _stroke(points));
  }

  void _erase(VideoAddPoint point) {
    widget.onDocument(
      widget.document.withStrokes(
        VideoAddGeometry.erase(
          strokes: widget.document.strokes,
          point: point,
          aspect: _aspect(),
        ),
      ),
    );
  }

  void _endDraw() {
    final preview = _preview;
    final start = _drawStart;
    final end = _drawEnd;
    _preview = null;
    _drawStart = null;
    _drawEnd = null;
    final tool = widget.drawTool;
    if (tool == VideoAddDrawTool.eraser) {
      widget.onGestureEnd?.call();
      setState(() {});
      return;
    }
    if (preview != null && start != null && end != null && _movedEnough(start, end, tool)) {
      final points = tool == VideoAddDrawTool.freehand && preview.points.length == 1
          ? [
              preview.points.first,
              VideoAddPoint(preview.points.first.x + 0.001, preview.points.first.y),
            ]
          : preview.points;
      widget.onStroke?.call(
        VideoAddStroke(points: points, color: preview.color, width: preview.width),
      );
    }
    setState(() {});
  }

  bool _movedEnough(VideoAddPoint start, VideoAddPoint end, VideoAddDrawTool tool) {
    if (tool == VideoAddDrawTool.freehand) return true;
    final aspect = _aspect();
    final dx = end.x - start.x;
    final dy = (end.y - start.y) * aspect;
    return math.sqrt(dx * dx + dy * dy) > 0.008;
  }

  VideoAddStroke _stroke(List<VideoAddPoint> points) => VideoAddStroke(
        points: points,
        color: widget.drawColor.toARGB32(),
        width: VideoAddGeometry.widthFraction(widget.strokeSlider),
      );

  VideoAddPoint? _point(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width == 0 || box.size.height == 0) {
      return null;
    }
    final local = box.globalToLocal(global);
    return VideoAddPoint(
      (local.dx / box.size.width).clamp(0.0, 1.0).toDouble(),
      (local.dy / box.size.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  double _aspect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width == 0) return 16 / 9;
    return box.size.height / box.size.width;
  }

  @override
  Widget build(BuildContext context) => Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onDown,
      child: _AddCanvas(
        document: widget.document,
        preview: _preview,
        selectedId: widget.selectedId,
        ghost: widget.ghost,
        drawing: widget.drawing,
        itemKey: _keyFor,
        onPressItem: (id) => _pressedItem = id,
        onPressHandle: (handle) => _pressedHandle = handle,
      ),
    );
}

class _AddCanvas extends StatelessWidget {
  const _AddCanvas({
    required this.document,
    this.preview,
    this.selectedId,
    this.ghost,
    this.drawing = false,
    this.itemKey,
    this.onPressItem,
    this.onPressHandle,
  });

  final VideoAddDocument document;
  final bool drawing;
  final VideoAddItem? ghost;
  final GlobalKey Function(int id)? itemKey;
  final ValueChanged<_Handle>? onPressHandle;
  final ValueChanged<int>? onPressItem;
  final VideoAddStroke? preview;
  final int? selectedId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) {
            return const SizedBox.shrink();
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StrokePainter(
                    strokes: document.strokes,
                    extra: preview,
                  ),
                ),
              ),
              for (final item in document.items)
                _positioned(
                  item: item,
                  size: size,
                  selected: item.id == selectedId,
                  tappable: !drawing,
                ),
              if (ghost != null)
                _positioned(item: ghost!, size: size, ghost: true),
              if (drawing)
                const Positioned.fill(
                  child: AbsorbPointer(child: SizedBox.expand()),
                ),
            ],
          );
        },
      );

  Widget _positioned({
    required VideoAddItem item,
    required Size size,
    bool selected = false,
    bool ghost = false,
    bool tappable = false,
  }) {
    final unit = size.width / 100;
    final child = _ItemBody(
      item: item,
      unit: unit,
      selected: selected && !ghost,
      onPressItem: tappable ? onPressItem : null,
      onPressHandle: tappable ? onPressHandle : null,
    );
    return Positioned(
      left: item.x * size.width,
      top: item.y * size.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: KeyedSubtree(
          key: itemKey?.call(item.id),
          child: Opacity(
            opacity: ghost ? 0.92 : 1,
            child: IgnorePointer(
              ignoring: ghost || drawing,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemBody extends StatelessWidget {
  const _ItemBody({
    required this.item,
    required this.unit,
    required this.selected,
    this.onPressItem,
    this.onPressHandle,
  });

  final VideoAddItem item;
  final ValueChanged<_Handle>? onPressHandle;
  final ValueChanged<int>? onPressItem;
  final bool selected;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final scale = item.scale == 0 ? 1.0 : item.scale;
    // Handles are drawn outside the content. The stack must include that
    // margin in its layout size, or those pixels are painted but not hittable.
    final chrome = selected ? 48 / scale : 0.0;
    return Transform.rotate(
      angle: item.rotation * math.pi / 180,
      child: Transform.scale(
        scale: item.scale,
        child: Listener(
          onPointerDown: onPressItem == null ? null : (_) => onPressItem!(item.id),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(chrome),
                child: _content(),
              ),
              if (selected) ...[
                Positioned(
                  left: chrome - 6 / scale,
                  top: chrome - 6 / scale,
                  right: chrome - 6 / scale,
                  bottom: chrome - 6 / scale,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: VideoAddPalette.accent,
                          width: 1.5 / scale,
                        ),
                        borderRadius: BorderRadius.circular(4 / scale),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: chrome - 30 / scale,
                  child: Center(
                    child: IgnorePointer(
                      child: Container(
                        width: 1.5 / scale,
                        height: 24 / scale,
                        color: VideoAddPalette.accent,
                      ),
                    ),
                  ),
                ),
                _deleteButton(scale, chrome),
                _handle(scale, chrome, right: -20 / scale, top: -20 / scale),
                _handle(scale, chrome, left: -20 / scale, bottom: -20 / scale),
                _handle(scale, chrome, right: -20 / scale, bottom: -20 / scale),
                _handle(scale, chrome, top: -44 / scale, handle: _Handle.rotate),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (item.type) {
      case VideoAddItemType.sticker:
        final side = unit * 30;
        return SizedBox(
          width: side,
          height: side,
          child: _sticker(item.assetPath, side),
        );
      case VideoAddItemType.emoji:
        return Text(
          item.emoji,
          style: TextStyle(fontSize: unit * 22, height: 1),
        );
      case VideoAddItemType.text:
        final color = Color(item.color);
        final background = item.background == null ? null : Color(item.background!);
        final shadow = item.shadow == null ? null : Color(item.shadow!);
        return DecoratedBox(
          decoration: VideoAddCatalog.textBackground(background: background) ??
              const BoxDecoration(),
          child: Padding(
            padding: background == null
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(horizontal: unit * 3.2, vertical: unit * 1.2),
            child: Text(
              item.text.isEmpty ? ' ' : item.text,
              style: VideoAddCatalog.textStyle(
                font: item.font,
                color: color,
                shadow: shadow,
                unit: unit,
              ),
            ),
          ),
        );
    }
  }

  Widget _deleteButton(double scale, double chrome) => Positioned(
        left: chrome - 28 / scale,
        top: chrome - 28 / scale,
        child: Semantics(
          button: true,
          label: 'Delete',
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => onPressHandle?.call(_Handle.delete),
            child: SizedBox(
              width: 44 / scale,
              height: 44 / scale,
              child: Center(
                child: Container(
                  width: 24 / scale,
                  height: 24 / scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VideoAddPalette.destructive,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5 / scale),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 13.2 / scale),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _handle(
    double scale,
    double chrome, {
    double? left,
    double? top,
    double? right,
    double? bottom,
    _Handle handle = _Handle.scale,
  }) {
    final knob = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPressHandle?.call(handle),
      child: Container(
        width: 28 / scale,
        height: 28 / scale,
        alignment: Alignment.center,
        child: Container(
          width: 12 / scale,
          height: 12 / scale,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: VideoAddPalette.accent,
              width: 1.5 / scale,
            ),
          ),
        ),
      ),
    );
    if (handle == _Handle.rotate) {
      return Positioned(
        top: (top ?? 0) + chrome,
        left: 0,
        right: 0,
        child: Center(child: knob),
      );
    }
    return Positioned(
      left: left == null ? null : left + chrome,
      top: top == null ? null : top + chrome,
      right: right == null ? null : right + chrome,
      bottom: bottom == null ? null : bottom + chrome,
      child: knob,
    );
  }

  Widget _sticker(String path, double side) {
    if (path.toLowerCase().endsWith('.png')) {
      return AppImage.asset(path, width: side, height: side, fit: BoxFit.contain);
    }
    return AppImage.svg(path, width: side, height: side, fit: BoxFit.contain);
  }
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({required this.strokes, this.extra});

  final VideoAddStroke? extra;
  final List<VideoAddStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _draw(canvas, size, stroke);
    }
    final preview = extra;
    if (preview != null) _draw(canvas, size, preview);
  }

  void _draw(Canvas canvas, Size size, VideoAddStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = math.max(1, stroke.width * size.width)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(stroke.points.first.x * size.width, stroke.points.first.y * size.height);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}
