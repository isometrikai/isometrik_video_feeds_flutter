import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_draft.dart';

/// Colors shared by the Add screen and the overlay painter.
class VideoAddPalette {
  const VideoAddPalette._();

  static const accent = Color(0xFF6D4AFF);
  static const destructive = Color(0xFFD92D20);
  static const disabled = Color(0xFFE4E4EA);
  static const disabledText = Color(0xFF8A8A96);
  static const fill = Color(0xFFF0F0F4);
  static const ink = Color(0xFF1C1C22);
  static const neonGlow = Color(0xFF7FE9FF);
  static const secondary = Color(0xFF5E5E69);
  static const tint = Color(0xFFEFEBFF);
  static const track = Color(0xFFDADAE1);

  static const textPresets = [
    Color(0xFFFFFFFF),
    Color(0xFF1C1C22),
    Color(0xFF6D4AFF),
    Color(0xFFCFC4FF),
    Color(0xFFFFB020),
  ];

  static const drawColors = [
    Color(0xFFD92D20),
    Color(0xFFF5B301),
    Color(0xFF12A150),
    Color(0xFF6D4AFF),
    Color(0xFFFFFFFF),
    Color(0xFF1C1C22),
  ];
}

/// Emoji sections shown in the Add picker.
class VideoAddEmojiCategory {
  const VideoAddEmojiCategory({
    required this.name,
    required this.icon,
    required this.emojis,
  });

  final List<String> emojis;
  final IconData icon;
  final String name;
}

/// Fonts, emoji, and sticker labels for the Add tool.
class VideoAddCatalog {
  const VideoAddCatalog._();

  static const categories = [
    VideoAddEmojiCategory(
      name: 'Smileys',
      icon: Icons.emoji_emotions_outlined,
      emojis: [
        '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😎',
        '🤩', '🥳', '😅', '😉', '🙃', '😇', '🤔', '😴',
        '😢', '😭', '😡', '🥺', '🤯', '😱', '🙌', '👍',
      ],
    ),
    VideoAddEmojiCategory(
      name: 'Animals',
      icon: Icons.pets_outlined,
      emojis: [
        '🐶', '🐱', '🐭', '🐰', '🦊', '🐻', '🐼', '🐨',
        '🐯', '🦁', '🐸', '🐵', '🐔', '🐧', '🦄', '🐝',
        '🦋', '🐢', '🐙', '🐬', '🐳', '🦈', '🐞', '🌸',
      ],
    ),
    VideoAddEmojiCategory(
      name: 'Food',
      icon: Icons.restaurant_outlined,
      emojis: [
        '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒',
        '🍑', '🥑', '🌽', '🍕', '🍔', '🍟', '🌮', '🍣',
        '🍩', '🍪', '🎂', '🍫', '🍿', '☕', '🍺', '🥤',
      ],
    ),
    VideoAddEmojiCategory(
      name: 'Activity',
      icon: Icons.sports_soccer_outlined,
      emojis: [
        '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🎱', '🏓',
        '🥊', '🎯', '🎮', '🎲', '🎸', '🎤', '🎧', '🎬',
        '🎨', '🏆', '🥇', '🎉', '🎊', '🎈', '🎁', '🏄',
      ],
    ),
    VideoAddEmojiCategory(
      name: 'Travel',
      icon: Icons.flight_outlined,
      emojis: [
        '🚗', '🚕', '🚌', '🚀', '✈️', '🚁', '⛵', '🚲',
        '🏍️', '🏠', '🏰', '🗽', '🗼', '🌋', '🏝️', '🏔️',
        '🌅', '🌃', '🌉', '🎡', '🎢', '⛺', '🗺️', '🧭',
      ],
    ),
    VideoAddEmojiCategory(
      name: 'Symbols',
      icon: Icons.favorite_border,
      emojis: [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💯',
        '🔥', '✨', '⭐', '🌟', '💥', '💫', '🎵', '🎶',
        '✅', '❌', '⚡', '💬', '💡', '🔔', '📌', '🏷️',
      ],
    ),
  ];

  static String stickerLabel(String path) {
    final file = path.split('/').last.split('.').first;
    final words = file
        .replaceFirst(RegExp(r'^ic_'), '')
        .replaceAll('_icon', '')
        .replaceAll('_', ' ')
        .trim();
    if (words.isEmpty) return 'Sticker';
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  static TextStyle textStyle({
    required VideoAddFont font,
    required Color color,
    Color? shadow,
    required double unit,
  }) {
    final neon = font == VideoAddFont.neon;
    final glow = shadow ?? color;
    return TextStyle(
      fontFamily: switch (font) {
        VideoAddFont.classic => 'Georgia',
        VideoAddFont.typewriter => 'Courier',
        _ => null,
      },
      fontFamilyFallback: switch (font) {
        VideoAddFont.classic => const ['Times New Roman', 'serif'],
        VideoAddFont.typewriter => const ['monospace'],
        _ => null,
      },
      fontWeight: font == VideoAddFont.modern ? FontWeight.w800 : FontWeight.w700,
      fontSize: unit * 7.5,
      height: 1.15,
      color: color,
      shadows: neon
          ? [
              Shadow(color: glow, blurRadius: unit * 0.8),
              Shadow(color: glow, blurRadius: unit * 2),
              Shadow(color: glow, blurRadius: unit * 3.6),
            ]
          : shadow == null
              ? null
              : [
                  Shadow(
                    color: shadow,
                    blurRadius: unit * 1.2,
                    offset: Offset(unit * 0.5, unit * 0.6),
                  ),
                ],
    );
  }

  static BoxDecoration? textBackground({
    required Color? background,
  }) {
    if (background == null) return null;
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    );
  }

  static int hslToArgb(double hue, double saturation, double lightness) {
    final s = saturation.clamp(0, 100) / 100;
    final l = lightness.clamp(0, 100) / 100;
    final a = s * math.min(l, 1 - l);
    int channel(int n) {
      final k = (n + hue / 30) % 12;
      final value = l - a * math.max(-1, math.min(k - 3, math.min(9 - k, 1)));
      return (value * 255).round().clamp(0, 255);
    }

    return 0xFF000000 | (channel(0) << 16) | (channel(8) << 8) | channel(4);
  }

  /// Hue 0–360, saturation and lightness 0–100.
  static ({double h, double s, double l}) argbToHsl(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255;
    final g = ((argb >> 8) & 0xFF) / 255;
    final b = (argb & 0xFF) / 255;
    final maxChannel = math.max(r, math.max(g, b));
    final minChannel = math.min(r, math.min(g, b));
    final delta = maxChannel - minChannel;
    final lightness = (maxChannel + minChannel) / 2;
    var hue = 0.0;
    var saturation = 0.0;
    if (delta != 0) {
      saturation = delta / (1 - (2 * lightness - 1).abs());
      if (maxChannel == r) {
        hue = ((g - b) / delta) % 6;
      } else if (maxChannel == g) {
        hue = (b - r) / delta + 2;
      } else {
        hue = (r - g) / delta + 4;
      }
      hue *= 60;
      if (hue < 0) hue += 360;
    }
    return (h: hue.roundToDouble(), s: (saturation * 100).roundToDouble(), l: (lightness * 100).roundToDouble());
  }
}
