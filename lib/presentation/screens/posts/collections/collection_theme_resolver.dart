import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Resolves collection UI colors from [IsrVideoReelConfig.socialConfig].
class CollectionThemeResolver {
  CollectionThemeResolver._();

  static bool get isDark =>
      (IsrVideoReelConfig.socialConfig.themeConfig?.brightness ??
          Brightness.light) ==
      Brightness.dark;

  static Color get scaffoldBackground =>
      IsrVideoReelConfig.socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
      IsrVideoReelConfig.socialConfig.themeConfig?.scaffoldBackgroundColor ??
      (isDark ? const Color(0xFF1C1C1E) : IsrColors.scaffoldColor);

  static Color get surfaceCard =>
      IsrVideoReelConfig.socialConfig.colorsConfig?.dialogColor ??
      (isDark ? const Color(0xFF252525) : IsrColors.white);

  /// Input fields sit on [scaffoldBackground]; use a raised surface in dark mode.
  static Color get inputFill {
    if (!isDark) return surfaceCard;
    return IsrVideoReelConfig.socialConfig.colorsConfig?.dialogColor ??
        IsrVideoReelConfig.socialConfig.themeConfig?.appBarColor ??
        surfaceCard;
  }

  /// Prefer configured text colors, but never keep near-black text on dark sheets.
  static Color get textPrimary {
    final configured =
        IsrVideoReelConfig.socialConfig.colorsConfig?.primaryTextColor;
    if (configured != null) {
      if (isDark && configured.computeLuminance() < 0.25) {
        return const Color(0xFFF2F2F2);
      }
      return configured;
    }
    return isDark ? const Color(0xFFF2F2F2) : const Color(0xFF333333);
  }

  static Color get textSecondary {
    final configured =
        IsrVideoReelConfig.socialConfig.colorsConfig?.secondaryTextColor;
    if (configured != null) {
      if (isDark && configured.computeLuminance() < 0.25) {
        return const Color(0xFFB0B0B0);
      }
      return configured;
    }
    return isDark ? const Color(0xFFB0B0B0) : const Color(0xFF505050);
  }

  /// Field labels — lighter in dark mode for legibility on dark surfaces.
  static Color get labelText => isDark
      ? textPrimary.withValues(alpha: 0.75)
      : textSecondary;

  static Color get divider => IsrColors.dividerColor;

  static Color get border =>
      isDark ? textPrimary.withValues(alpha: 0.22) : const Color(0xFFE5E7EB);

  static Color get focusedBorder => IsrColors.appColor;

  static Color get cursor => IsrColors.appColor;

  static Color get mutedSurface => isDark
      ? textSecondary.withValues(alpha: 0.15)
      : const Color(0xFFF8F9FA);

  static Color get mutedBorder =>
      isDark ? border : const Color(0xFFE5E7EB);

  static Color get imagePickerBackground => isDark
      ? textPrimary.withValues(alpha: 0.08)
      : const Color(0xFFF4F4F4);

  static Color get switchInactiveTrack =>
      isDark ? textPrimary.withValues(alpha: 0.18) : const Color(0xFFEBEBEB);

  static Color get destructive => IsrColors.error;
}
