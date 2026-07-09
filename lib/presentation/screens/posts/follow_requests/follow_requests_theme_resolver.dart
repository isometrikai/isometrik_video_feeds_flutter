import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Resolves follow-requests UI colors from [IsrVideoReelConfig.socialConfig].
class FollowRequestsThemeResolver {
  FollowRequestsThemeResolver._();

  static bool get isDark =>
      (IsrVideoReelConfig.socialConfig.themeConfig?.brightness ??
          Brightness.light) ==
      Brightness.dark;

  static Brightness get statusBarIconBrightness =>
      isDark ? Brightness.light : Brightness.dark;

  static Brightness get statusBarBrightness =>
      isDark ? Brightness.dark : Brightness.light;

  static Color get scaffoldBackground =>
      IsrVideoReelConfig
          .socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
      IsrVideoReelConfig.socialConfig.themeConfig?.scaffoldBackgroundColor ??
      IsrColors.scaffoldColor;

  static Color get surface =>
      IsrVideoReelConfig.socialConfig.colorsConfig?.dialogColor ??
      scaffoldBackground;

  static Color get textPrimary => IsrColors.primaryTextColor;

  static Color get textSecondary => IsrColors.secondaryTextColor;

  static Color get divider => IsrColors.dividerColor;

  static Color get primary => IsrColors.appColor;

  static Color get onPrimary => IsrColors.buttonTextColor;
}
