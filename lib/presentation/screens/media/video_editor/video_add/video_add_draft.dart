import 'dart:math' as math;

/// Tool tab on the Add screen.
enum VideoAddTool { text, sticker, emoji, draw }

/// Kind of overlay placed on the clip.
enum VideoAddItemType { text, sticker, emoji }

/// Typeface for a text overlay.
enum VideoAddFont {
  classic,
  modern,
  typewriter,
  neon;

  String get label => switch (this) {
        VideoAddFont.classic => 'Classic',
        VideoAddFont.modern => 'Modern',
        VideoAddFont.typewriter => 'Typewriter',
        VideoAddFont.neon => 'Neon',
      };

  static VideoAddFont fromName(Object? value) {
    for (final font in VideoAddFont.values) {
      if (font.name == value) return font;
    }
    return VideoAddFont.classic;
  }
}

/// Draw tool selected on the Draw tab.
enum VideoAddDrawTool {
  freehand,
  arrow,
  line,
  rectangle,
  circle,
  eraser;

  String get label => switch (this) {
        VideoAddDrawTool.freehand => 'Freehand',
        VideoAddDrawTool.arrow => 'Arrow',
        VideoAddDrawTool.line => 'Line',
        VideoAddDrawTool.rectangle => 'Rectangle',
        VideoAddDrawTool.circle => 'Circle',
        VideoAddDrawTool.eraser => 'Eraser',
      };
}

/// A point in the preview, both axes 0–1.
class VideoAddPoint {
  const VideoAddPoint(this.x, this.y);

  factory VideoAddPoint.fromJson(Map<String, dynamic> json) => VideoAddPoint(
        _double(json['x']),
        _double(json['y']),
      );

  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      other is VideoAddPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// One text, sticker, or emoji overlay.
class VideoAddItem {
  const VideoAddItem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.scale = 1,
    this.rotation = 0,
    this.text = '',
    this.font = VideoAddFont.classic,
    this.color = 0xFFFFFFFF,
    this.background,
    this.shadow,
    this.assetPath = '',
    this.emoji = '',
  });

  factory VideoAddItem.fromJson(Map<String, dynamic> json) => VideoAddItem(
        id: json['id'] is num ? (json['id'] as num).round() : 0,
        type: _itemType(json['type']),
        x: VideoAddDocument.clampPosition(_double(json['x'], 0.5)),
        y: VideoAddDocument.clampPosition(_double(json['y'], 0.5)),
        scale: VideoAddDocument.clampScale(_double(json['scale'], 1)),
        rotation: _double(json['rotation']),
        text: json['text'] as String? ?? '',
        font: VideoAddFont.fromName(json['font']),
        color: json['color'] is num
            ? (json['color'] as num).round()
            : 0xFFFFFFFF,
        background: _optionalColor(json['background']),
        shadow: _optionalColor(json['shadow']),
        assetPath: json['assetPath'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
      );

  final String assetPath;

  /// Pill color, or null when the text has no background.
  final int? background;
  final int color;
  final String emoji;
  final VideoAddFont font;
  final int id;
  final double rotation;
  final double scale;

  /// Drop shadow, or the neon glow. Null means no shadow.
  final int? shadow;
  final String text;
  final VideoAddItemType type;
  final double x;
  final double y;

  VideoAddItem copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    String? text,
    VideoAddFont? font,
    int? color,
    Object? background = _keep,
    Object? shadow = _keep,
    String? assetPath,
    String? emoji,
  }) =>
      VideoAddItem(
        id: id,
        type: type,
        x: x ?? this.x,
        y: y ?? this.y,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        text: text ?? this.text,
        font: font ?? this.font,
        color: color ?? this.color,
        background: identical(background, _keep) ? this.background : background as int?,
        shadow: identical(shadow, _keep) ? this.shadow : shadow as int?,
        assetPath: assetPath ?? this.assetPath,
        emoji: emoji ?? this.emoji,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'text': text,
        'font': font.name,
        'color': color,
        'background': background,
        'shadow': shadow,
        'assetPath': assetPath,
        'emoji': emoji,
      };

  @override
  bool operator ==(Object other) =>
      other is VideoAddItem &&
      other.id == id &&
      other.type == type &&
      other.x == x &&
      other.y == y &&
      other.scale == scale &&
      other.rotation == rotation &&
      other.text == text &&
      other.font == font &&
      other.color == color &&
      other.background == background &&
      other.shadow == shadow &&
      other.assetPath == assetPath &&
      other.emoji == emoji;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        x,
        y,
        scale,
        rotation,
        text,
        font,
        color,
        background,
        shadow,
        assetPath,
        emoji,
      );
}

/// A stroke in preview coordinates. [width] is a fraction of the preview width.
class VideoAddStroke {
  const VideoAddStroke({
    required this.points,
    required this.color,
    required this.width,
  });

  factory VideoAddStroke.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    final points = <VideoAddPoint>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          points.add(VideoAddPoint.fromJson(entry));
        } else if (entry is Map) {
          points.add(VideoAddPoint.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }
    return VideoAddStroke(
      points: points,
      color: json['color'] is num ? (json['color'] as num).round() : 0xFFD92D20,
      width: _double(json['width'], VideoAddGeometry.widthFraction(35)),
    );
  }

  final int color;
  final List<VideoAddPoint> points;
  final double width;

  Map<String, dynamic> toJson() => {
        'points': points.map((point) => point.toJson()).toList(),
        'color': color,
        'width': width,
      };

  @override
  bool operator ==(Object other) =>
      other is VideoAddStroke &&
      other.color == color &&
      other.width == width &&
      _listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(color, width, Object.hashAll(points));
}

/// Overlays and strokes for one clip. Positions are 0–1 in the preview.
class VideoAddDocument {
  const VideoAddDocument({
    this.items = const [],
    this.strokes = const [],
  });

  factory VideoAddDocument.fromJson(Map<String, dynamic> json) =>
      VideoAddDocument(
        items: _objects(json['items'])
            .map(VideoAddItem.fromJson)
            .toList(growable: false),
        strokes: _objects(json['strokes'])
            .map(VideoAddStroke.fromJson)
            .toList(growable: false),
      );

  static const empty = VideoAddDocument();

  final List<VideoAddItem> items;
  final List<VideoAddStroke> strokes;

  bool get hasContent => items.isNotEmpty || strokes.isNotEmpty;

  int get nextId {
    var maxId = 0;
    for (final item in items) {
      if (item.id > maxId) maxId = item.id;
    }
    return maxId + 1;
  }

  bool hasTool(VideoAddTool tool) => switch (tool) {
        VideoAddTool.text =>
          items.any((item) => item.type == VideoAddItemType.text),
        VideoAddTool.sticker =>
          items.any((item) => item.type == VideoAddItemType.sticker),
        VideoAddTool.emoji =>
          items.any((item) => item.type == VideoAddItemType.emoji),
        VideoAddTool.draw => strokes.isNotEmpty,
      };

  VideoAddItem? item(int id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  VideoAddDocument addItem(VideoAddItem item) => VideoAddDocument(
        items: [...items, item],
        strokes: strokes,
      );

  VideoAddDocument removeItem(int id) => VideoAddDocument(
        items: [
          for (final item in items)
            if (item.id != id) item,
        ],
        strokes: strokes,
      );

  VideoAddDocument updateItem(VideoAddItem next) => VideoAddDocument(
        items: [
          for (final item in items)
            if (item.id == next.id) next else item,
        ],
        strokes: strokes,
      );

  VideoAddDocument addStroke(VideoAddStroke stroke) => VideoAddDocument(
        items: items,
        strokes: [...strokes, stroke],
      );

  VideoAddDocument withStrokes(List<VideoAddStroke> strokes) =>
      VideoAddDocument(items: items, strokes: strokes);

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      };

  static double clampScale(double value) => value.clamp(0.3, 4.0).toDouble();

  static double clampPosition(double value) =>
      value.clamp(0.02, 0.98).toDouble();

  /// Center, then a small offset when the center is already used.
  static VideoAddPoint spot(int existingCount) {
    const dx = [0.0, 0.07, -0.07, 0.12, -0.12];
    const dy = [0.0, 0.06, -0.06, 0.10, -0.10];
    final index = existingCount % dx.length;
    return VideoAddPoint(
      clampPosition(0.5 + dx[index]),
      clampPosition(0.5 + dy[index]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VideoAddDocument &&
      _listEquals(other.items, items) &&
      _listEquals(other.strokes, strokes);

  @override
  int get hashCode => Object.hash(Object.hashAll(items), Object.hashAll(strokes));
}

/// Saved Add result: the canvas plus the emoji recent row.
class VideoAddDraft {
  const VideoAddDraft({
    this.document = VideoAddDocument.empty,
    this.recentEmojis = defaultRecent,
  });

  factory VideoAddDraft.fromJson(Map<String, dynamic> json) {
    final raw = json['recentEmojis'];
    final recent = <String>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is String && entry.isNotEmpty) recent.add(entry);
      }
    }
    return VideoAddDraft(
      document: json['document'] is Map<String, dynamic>
          ? VideoAddDocument.fromJson(
              json['document'] as Map<String, dynamic>,
            )
          : json['document'] is Map
              ? VideoAddDocument.fromJson(
                  Map<String, dynamic>.from(json['document'] as Map),
                )
              : VideoAddDocument.empty,
      recentEmojis: recent.isEmpty
          ? defaultRecent
          : recent.take(8).toList(growable: false),
    );
  }

  static const empty = VideoAddDraft();

  static const defaultRecent = [
    '😂',
    '❤️',
    '🔥',
    '😍',
    '👍',
    '🎉',
    '😎',
    '✨',
  ];

  final VideoAddDocument document;
  final List<String> recentEmojis;

  bool get hasContent => document.hasContent;

  VideoAddDraft copyWith({
    VideoAddDocument? document,
    List<String>? recentEmojis,
  }) =>
      VideoAddDraft(
        document: document ?? this.document,
        recentEmojis: recentEmojis ?? this.recentEmojis,
      );

  Map<String, dynamic> toJson() => {
        'document': document.toJson(),
        'recentEmojis': recentEmojis,
      };

  static List<String> rememberEmoji(List<String> recent, String emoji) {
    final next = <String>[
      emoji,
      for (final entry in recent)
        if (entry != emoji) entry,
    ];
    return next.length > 8 ? next.sublist(0, 8) : next;
  }
}

/// Undo history for the Add canvas. One entry per completed gesture.
class VideoAddEditor {
  VideoAddEditor({VideoAddDocument? initial})
      : document = initial ?? VideoAddDocument.empty;

  static const historyLimit = 60;

  VideoAddDocument document;

  final List<VideoAddDocument> _future = [];
  final List<VideoAddDocument> _past = [];

  bool get canRedo => _future.isNotEmpty;

  bool get canUndo => _past.isNotEmpty;

  bool get hasContent => document.hasContent;

  /// Cancel asks before closing while anything is on the canvas.
  bool get shouldConfirmDiscard => hasContent;

  void apply(VideoAddDocument next) => document = next;

  void commit(VideoAddDocument before) {
    if (before == document) return;
    _past.add(before);
    if (_past.length > historyLimit) _past.removeAt(0);
    _future.clear();
  }

  void undo() {
    if (_past.isEmpty) return;
    _future.add(document);
    document = _past.removeLast();
  }

  void redo() {
    if (_future.isEmpty) return;
    _past.add(document);
    document = _future.removeLast();
  }

  VideoAddItem place({
    required VideoAddItemType type,
    String text = '',
    VideoAddFont font = VideoAddFont.classic,
    int color = 0xFFFFFFFF,
    int? background,
    int? shadow,
    String assetPath = '',
    String emoji = '',
    double scale = 1,
  }) {
    final before = document;
    final spot = VideoAddDocument.spot(document.items.length);
    final item = VideoAddItem(
      id: document.nextId,
      type: type,
      x: spot.x,
      y: spot.y,
      scale: scale,
      text: text,
      font: font,
      color: color,
      background: background,
      shadow: shadow,
      assetPath: assetPath,
      emoji: emoji,
    );
    apply(document.addItem(item));
    commit(before);
    return item;
  }

  void delete(int id) {
    final before = document;
    apply(document.removeItem(id));
    commit(before);
  }

  void move(
    int id, {
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    final item = document.item(id);
    if (item == null) return;
    final before = document;
    apply(
      document.updateItem(
        item.copyWith(
          x: x == null ? null : VideoAddDocument.clampPosition(x),
          y: y == null ? null : VideoAddDocument.clampPosition(y),
          scale: scale == null ? null : VideoAddDocument.clampScale(scale),
          rotation: rotation,
        ),
      ),
    );
    commit(before);
  }

  void addStroke(VideoAddStroke stroke) {
    final before = document;
    apply(document.addStroke(stroke));
    commit(before);
  }
}

/// Stroke shapes and eraser hits, in preview coordinates.
class VideoAddGeometry {
  const VideoAddGeometry._();

  static double widthFraction(double slider) =>
      (6 + slider.clamp(0, 100) * 0.38) / 1000;

  static List<VideoAddPoint> rectangle(VideoAddPoint start, VideoAddPoint end) =>
      [
        start,
        VideoAddPoint(end.x, start.y),
        end,
        VideoAddPoint(start.x, end.y),
        start,
      ];

  static List<VideoAddPoint> circle({
    required VideoAddPoint center,
    required VideoAddPoint edge,
    required double aspect,
  }) {
    final dx = edge.x - center.x;
    final dy = (edge.y - center.y) * aspect;
    final radius = math.sqrt(dx * dx + dy * dy);
    return [
      for (var index = 0; index <= 48; index++)
        VideoAddPoint(
          center.x + radius * math.cos(index / 48 * math.pi * 2),
          center.y + radius * math.sin(index / 48 * math.pi * 2) / aspect,
        ),
    ];
  }

  static List<VideoAddPoint> arrow({
    required VideoAddPoint start,
    required VideoAddPoint end,
    required double width,
    required double aspect,
  }) {
    final ay = start.y * aspect;
    final by = end.y * aspect;
    final angle = math.atan2(by - ay, end.x - start.x);
    final length = math.max(0.026, width * 2.6);
    VideoAddPoint wing(double delta) => VideoAddPoint(
          end.x - length * math.cos(angle + delta),
          (by - length * math.sin(angle + delta)) / aspect,
        );
    return [start, end, wing(-0.45), end, wing(0.45)];
  }

  static List<VideoAddStroke> erase({
    required List<VideoAddStroke> strokes,
    required VideoAddPoint point,
    required double aspect,
  }) =>
      [
        for (final stroke in strokes)
          if (!_hits(stroke, point, aspect)) stroke,
      ];

  static bool _hits(VideoAddStroke stroke, VideoAddPoint point, double aspect) {
    if (stroke.points.isEmpty) return false;
    final radius = 0.034 + stroke.width / 2;
    final px = point.x;
    final py = point.y * aspect;
    if (stroke.points.length == 1) {
      final only = stroke.points.first;
      return _hypot(px - only.x, py - only.y * aspect) < radius;
    }
    for (var index = 0; index < stroke.points.length - 1; index++) {
      if (_segmentDistance(px, py, stroke.points[index], stroke.points[index + 1], aspect) <
          radius) {
        return true;
      }
    }
    return false;
  }

  static double _segmentDistance(
    double px,
    double py,
    VideoAddPoint a,
    VideoAddPoint b,
    double aspect,
  ) {
    final ax = a.x;
    final ay = a.y * aspect;
    final bx = b.x;
    final by = b.y * aspect;
    final dx = bx - ax;
    final dy = by - ay;
    final length = dx * dx + dy * dy;
    var t = length == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / length;
    t = t.clamp(0.0, 1.0).toDouble();
    return _hypot(px - ax - t * dx, py - ay - t * dy);
  }

  static double _hypot(double x, double y) => math.sqrt(x * x + y * y);
}

VideoAddItemType _itemType(Object? value) => switch (value) {
      'sticker' => VideoAddItemType.sticker,
      'emoji' => VideoAddItemType.emoji,
      _ => VideoAddItemType.text,
    };

double _double(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;

int? _optionalColor(Object? value) => value is num ? value.round() : null;

const _keep = Object();

List<Map<String, dynamic>> _objects(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is Map<String, dynamic>)
        entry
      else if (entry is Map)
        Map<String, dynamic>.from(entry),
  ];
}

/// Overlay document baked into [outputPath].
///
/// [inputPath] is the video the overlay was composited onto, so Add can be
/// opened again without drawing the same overlay twice.
class VideoAddExport {
  const VideoAddExport({
    required this.draft,
    required this.inputPath,
    required this.outputPath,
  });

  final VideoAddDraft draft;
  final String inputPath;
  final String outputPath;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
