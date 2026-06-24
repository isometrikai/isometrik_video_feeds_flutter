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
      IsrColors.scaffoldColor;

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

  static Color get textPrimary => IsrColors.primaryTextColor;

  static Color get textSecondary => IsrColors.secondaryTextColor;

  /// Field labels — lighter in dark mode for legibility on dark surfaces.
  static Color get labelText => isDark
      ? textPrimary.withValues(alpha: 0.75)
      : textSecondary;

  static Color get divider => IsrColors.dividerColor;

  static Color get border =>
      isDark ? textPrimary.withValues(alpha: 0.22) : const Color(0xFFE5E7EB);

  static Color get mutedSurface => isDark
      ? textSecondary.withValues(alpha: 0.15)
      : const Color(0xFFF8F9FA);

  static Color get mutedBorder =>
      isDark ? border : const Color(0xFFE5E7EB);

  static Color get imagePickerBackground => isDark
      ? textPrimary.withValues(alpha: 0.08)
      : const Color(0xFFF4F4F4);

  static Color get destructive => IsrColors.error;
}
