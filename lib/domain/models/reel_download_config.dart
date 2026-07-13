/// Host-provided watermark settings applied when saving reels to the gallery.
class ReelDownloadWatermarkConfig {
  const ReelDownloadWatermarkConfig({
    this.imagePathOrUrl,
    this.opacity = 0.85,
    this.scale = 0.22,
    this.padding = 24,
    this.position = ReelDownloadWatermarkPosition.bottomRight,
  });

  /// PNG/JPG asset path, local file path, or HTTPS URL supplied by the host app.
  ///
  /// When null or empty, downloads are saved without a watermark.
  final String? imagePathOrUrl;

  /// Watermark opacity from `0` (transparent) to `1` (opaque).
  final double opacity;

  /// Watermark width as a fraction of the media width (`0.22` = 22%).
  final double scale;

  /// Padding from the chosen [position] edge, in logical pixels.
  final double padding;

  final ReelDownloadWatermarkPosition position;

  bool get isConfigured =>
      imagePathOrUrl != null && imagePathOrUrl!.trim().isNotEmpty;

  ReelDownloadWatermarkConfig copyWith({
    String? imagePathOrUrl,
    double? opacity,
    double? scale,
    double? padding,
    ReelDownloadWatermarkPosition? position,
  }) =>
      ReelDownloadWatermarkConfig(
        imagePathOrUrl: imagePathOrUrl ?? this.imagePathOrUrl,
        opacity: opacity ?? this.opacity,
        scale: scale ?? this.scale,
        padding: padding ?? this.padding,
        position: position ?? this.position,
      );
}

enum ReelDownloadWatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
