/// Prebuilt look applied to the whole clip.
enum VideoFilterTheme {
  original,
  warm,
  cool,
  fade,
  bw,
  vivid;

  String get label => switch (this) {
        VideoFilterTheme.original => 'Original',
        VideoFilterTheme.warm => 'Warm',
        VideoFilterTheme.cool => 'Cool',
        VideoFilterTheme.fade => 'Fade',
        VideoFilterTheme.bw => 'B&W',
        VideoFilterTheme.vivid => 'Vivid',
      };

  static VideoFilterTheme fromName(Object? value) {
    for (final theme in VideoFilterTheme.values) {
      if (theme.name == value) return theme;
    }
    return VideoFilterTheme.original;
  }
}

/// Which Filter-screen tool is showing.
enum VideoFilterTool { filter, tune, blur }

/// Tune slider selected under the Tune tab.
enum VideoTuneControl {
  brightness,
  contrast,
  saturation,
  temp;

  String get label => switch (this) {
        VideoTuneControl.brightness => 'Brightness',
        VideoTuneControl.contrast => 'Contrast',
        VideoTuneControl.saturation => 'Saturation',
        VideoTuneControl.temp => 'Temp',
      };
}

/// Saved or in-progress filter, tune, and blur values for one clip.
class VideoFilterDraft {
  const VideoFilterDraft({
    this.theme = VideoFilterTheme.original,
    this.level = 100,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.temp = 0,
    this.blur = 0,
  });

  factory VideoFilterDraft.fromJson(Map<String, dynamic> json) =>
      VideoFilterDraft(
        theme: VideoFilterTheme.fromName(json['theme']),
        level: _clampInt(json['level'], 100, 0, 100),
        brightness: _clampInt(json['brightness'], 0, -100, 100),
        contrast: _clampInt(json['contrast'], 0, -100, 100),
        saturation: _clampInt(json['saturation'], 0, -100, 100),
        temp: _clampInt(json['temp'], 0, -100, 100),
        blur: _clampInt(json['blur'], 0, 0, 100),
      );

  static const neutral = VideoFilterDraft();

  final int blur;
  final int brightness;
  final int contrast;
  final int level;
  final int saturation;
  final int temp;
  final VideoFilterTheme theme;

  bool get filterHasEdits =>
      theme != VideoFilterTheme.original && level > 0;

  bool get tuneHasEdits =>
      brightness != 0 || contrast != 0 || saturation != 0 || temp != 0;

  bool get blurHasEdits => blur > 0;

  bool hasEdits(VideoFilterTool tool) => switch (tool) {
        VideoFilterTool.filter => filterHasEdits,
        VideoFilterTool.tune => tuneHasEdits,
        VideoFilterTool.blur => blurHasEdits,
      };

  bool differsFrom(VideoFilterDraft other) => this != other;

  int tuneValue(VideoTuneControl control) => switch (control) {
        VideoTuneControl.brightness => brightness,
        VideoTuneControl.contrast => contrast,
        VideoTuneControl.saturation => saturation,
        VideoTuneControl.temp => temp,
      };

  VideoFilterDraft copyWith({
    int? blur,
    int? brightness,
    int? contrast,
    int? level,
    int? saturation,
    int? temp,
    VideoFilterTheme? theme,
  }) =>
      VideoFilterDraft(
        theme: theme ?? this.theme,
        level: level ?? this.level,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        temp: temp ?? this.temp,
        blur: blur ?? this.blur,
      );

  /// Picks [next]. A non-original theme starts at full level.
  VideoFilterDraft withTheme(VideoFilterTheme next) => copyWith(
        theme: next,
        level: next == VideoFilterTheme.original ? level : 100,
      );

  VideoFilterDraft withTune(VideoTuneControl control, int value) =>
      switch (control) {
        VideoTuneControl.brightness => copyWith(brightness: value),
        VideoTuneControl.contrast => copyWith(contrast: value),
        VideoTuneControl.saturation => copyWith(saturation: value),
        VideoTuneControl.temp => copyWith(temp: value),
      };

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'level': level,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'temp': temp,
        'blur': blur,
      };

  @override
  bool operator ==(Object other) =>
      other is VideoFilterDraft &&
      other.theme == theme &&
      other.level == level &&
      other.brightness == brightness &&
      other.contrast == contrast &&
      other.saturation == saturation &&
      other.temp == temp &&
      other.blur == blur;

  @override
  int get hashCode => Object.hash(
        theme,
        level,
        brightness,
        contrast,
        saturation,
        temp,
        blur,
      );

  static int _clampInt(Object? value, int fallback, int min, int max) {
    final parsed = value is num ? value.round() : fallback;
    return parsed.clamp(min, max);
  }
}

/// Result of tapping Done on the filter screen.
class VideoFilterExport {
  const VideoFilterExport({
    required this.baked,
    required this.inputPath,
    required this.outputPath,
    required this.settings,
  });

  /// True when [outputPath] is a newly encoded file.
  final bool baked;

  /// Clip the look was read from. Reopen the filter on this path.
  final String inputPath;
  final String outputPath;
  final VideoFilterDraft settings;
}

/// Signed slider label, such as `+10` or `-20`.
String videoFilterSignedValue(int value) => value > 0 ? '+$value' : '$value';
