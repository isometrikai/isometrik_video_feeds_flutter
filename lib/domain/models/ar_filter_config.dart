/// Resolution presets for DeepAR preview/capture.
enum ArResolution {
  low,
  medium,
  high,
  veryHigh,
}

/// A single AR effect the host can offer in the camera effect strip.
class ArEffectItem {
  const ArEffectItem({
    required this.id,
    required this.name,
    required this.pathOrUrl,
    this.thumbnailUrl,
  });

  /// Stable id used for selection state.
  final String id;

  /// Display name shown under the thumbnail.
  final String name;

  /// Asset path (`assets/...`), absolute file path, or remote URL (`.deepar`).
  final String pathOrUrl;

  /// Optional thumbnail image (asset path or URL).
  final String? thumbnailUrl;
}

/// Host-supplied DeepAR configuration for create-post / Stories camera.
///
/// Defaults to disabled. AR only activates when [enabled] is true and both
/// platform license keys are non-empty; otherwise the SDK uses the standard
/// camera plugin path.
class ArFilterConfig {
  const ArFilterConfig({
    this.enabled = false,
    this.androidLicenseKey = '',
    this.iosLicenseKey = '',
    this.effects = const [],
    this.resolution = ArResolution.medium,
  });

  /// Host opt-in. When false, DeepAR is never initialized.
  final bool enabled;

  final String androidLicenseKey;
  final String iosLicenseKey;

  /// Effect catalog owned by the host (assets and/or URLs).
  final List<ArEffectItem> effects;

  final ArResolution resolution;

  /// True when the host opted in and provided license keys for both platforms.
  bool get isEffectivelyEnabled =>
      enabled &&
      androidLicenseKey.trim().isNotEmpty &&
      iosLicenseKey.trim().isNotEmpty;

  ArFilterConfig copyWith({
    bool? enabled,
    String? androidLicenseKey,
    String? iosLicenseKey,
    List<ArEffectItem>? effects,
    ArResolution? resolution,
  }) =>
      ArFilterConfig(
        enabled: enabled ?? this.enabled,
        androidLicenseKey: androidLicenseKey ?? this.androidLicenseKey,
        iosLicenseKey: iosLicenseKey ?? this.iosLicenseKey,
        effects: effects ?? this.effects,
        resolution: resolution ?? this.resolution,
      );
}
