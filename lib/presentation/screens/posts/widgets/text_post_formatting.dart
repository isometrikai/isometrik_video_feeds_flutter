import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

/// Parsed `text_formatting` payload for `type: text` posts.
class TextPostFormatting {
  const TextPostFormatting({
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 18,
    this.fontStyle = 'normal',
    this.textAlign = 'center',
    this.backgroundType = 'gradient',
    this.backgroundValue = 'blue_purple',
    this.textColor = '#FFFFFF',
  });

  factory TextPostFormatting.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const TextPostFormatting(text: '');
    }

    final map = Map<String, dynamic>.from(raw);
    Map<String, dynamic>? background;
    final backgroundRaw = map['background'];
    if (backgroundRaw is Map) {
      background = Map<String, dynamic>.from(backgroundRaw);
    }

    return TextPostFormatting(
      text: map['text'] as String? ?? '',
      fontFamily: map['font_family'] as String? ?? 'Roboto',
      fontSize: (map['font_size'] as num?)?.toDouble() ?? 18,
      fontStyle: map['font_style'] as String? ?? 'normal',
      textAlign: map['text_align'] as String? ?? 'center',
      backgroundType: background?['type'] as String? ?? '',
      backgroundValue: background?['value'] as String? ?? '',
      textColor: background?['text_color'] as String? ?? '#FFFFFF',
    );
  }

  factory TextPostFormatting.fromTimeline(TimeLineData post) =>
      TextPostFormatting.fromDynamic(post.textFormatting);

  final String text;
  final String fontFamily;
  final double fontSize;
  final String fontStyle;
  final String textAlign;
  final String backgroundType;
  final String backgroundValue;
  final String textColor;

  bool get hasContent => text.trim().isNotEmpty;

  /// `true` when API `background` includes a non-empty `type` (gradient/color).
  bool get hasBackground => backgroundType.trim().isNotEmpty;

  Alignment get alignment {
    switch (textAlign.toLowerCase()) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  TextAlign get textAlignValue {
    switch (textAlign.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  TextStyle buildTextStyle({Color? textColorOverride}) {
    final normalizedStyle = fontStyle.toLowerCase();
    final weight =
        normalizedStyle == 'bold' ? FontWeight.bold : FontWeight.normal;
    final style =
        normalizedStyle == 'italic' ? FontStyle.italic : FontStyle.normal;
    final resolvedColor = textColorOverride ??
        (hasBackground ? _parseHexColor(textColor) : null);

    return GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      fontWeight: weight,
      fontStyle: style,
      color: resolvedColor,
      height: 1.35,
    );
  }

  TextStyle buildPlainTextStyle(Color textColor) =>
      buildTextStyle(textColorOverride: textColor);

  /// Smaller type for grid thumbnails (explore / profile); full-screen uses [buildTextStyle].
  TextStyle buildThumbnailTextStyle({
    double fontSizeDivisor = 2.3,
    double minFontSize = 8,
    double maxFontSize = 12,
    Color? textColorOverride,
  }) {
    final scaled =
        (fontSize / fontSizeDivisor).clamp(minFontSize, maxFontSize).toDouble();
    return buildTextStyle(textColorOverride: textColorOverride)
        .copyWith(fontSize: scaled, height: 1.15);
  }

  Gradient? get backgroundGradient {
    if (!hasBackground || backgroundType.toLowerCase() != 'gradient') {
      return null;
    }
    final colors = TextPostGradientPalette.colorsFor(backgroundValue);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  Color get fallbackBackgroundColor {
    if (!hasBackground) return const Color(0xFF000000);
    // Solid / plain backgrounds are expressed as a hex color value.
    final hex = _tryParseHexColor(backgroundValue);
    if (hex != null) return hex;
    return TextPostGradientPalette.colorsFor(backgroundValue).first;
  }

  static Color _parseHexColor(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return Colors.white;
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return Colors.white;
    return Color(parsed);
  }

  /// Returns a [Color] when [raw] looks like a hex value (`#RRGGBB` /
  /// `#AARRGGBB`), otherwise `null` so callers can fall back to gradient keys.
  static Color? _tryParseHexColor(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length != 6 && value.length != 8) return null;
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }
}

/// API gradient keys mapped to display colors.
class TextPostGradientPalette {
  TextPostGradientPalette._();

  static const _default = [Color(0xFF4776E6), Color(0xFF8E54E9)];

  static const Map<String, List<Color>> _gradients = {
    'sky_blue': [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    'charcoal_grey': [Color(0xFF434343), Color(0xFF000000)],
    'deep_purple': [Color(0xFF7F00FF), Color(0xFFE100FF)],
    'purple_pink': [Color(0xFFCC2B5E), Color(0xFF753A88)],
    'red_orange': [Color(0xFFFF512F), Color(0xFFDD2476)],
    'blue_purple': [Color(0xFF4776E6), Color(0xFF8E54E9)],
    'sunset_orange': [Color(0xFFFF8008), Color(0xFFFFC837)],
    'violet_night': [Color(0xFF41295A), Color(0xFF2F0743)],
    'dark_blue': [Color(0xFF0F2027), Color(0xFF2C5364)],
    'emerald_green': [Color(0xFF11998E), Color(0xFF38EF7D)],
    'ocean_blue': [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    'pink_peach': [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    'rose_red': [Color(0xFFF85032), Color(0xFFE73827)],
    'royal_purple': [Color(0xFF141E30), Color(0xFF243B55)],
    'midnight_black': [Color(0xFF232526), Color(0xFF414345)],
    'teal_blue': [Color(0xFF136A8A), Color(0xFF267871)],
    'lavender': [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    'forest_green': [Color(0xFF134E5E), Color(0xFF71B280)],
  };

  static List<Color> colorsFor(String key) {
    final normalized = key.trim().toLowerCase();
    return _gradients[normalized] ?? _default;
  }

  /// Ordered gradient keys, used by the composer to render selectable swatches.
  static List<String> get gradientKeys => _gradients.keys.toList(growable: false);
}

extension TimeLineDataTextFormattingX on TimeLineData {
  TextPostFormatting get textPostFormatting =>
      TextPostFormatting.fromTimeline(this);
}
