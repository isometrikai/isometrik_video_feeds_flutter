import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/domain/models/social_config.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/theme/isr_colors.dart';

/// Resolves status bar and navigation bar styling from [ThemeConfig].
class IsrSystemUi {
  IsrSystemUi._();

  /// Builds [SystemUiOverlayStyle] from [themeConfig] or [IsrVideoReelConfig].
  static SystemUiOverlayStyle overlay({
    ThemeConfig? themeConfig,
    Color? background,
  }) {
    final config =
        themeConfig ?? IsrVideoReelConfig.socialConfig.themeConfig;
    final resolvedBrightness = config?.brightness ?? Brightness.light;
    final defaultIconBrightness = resolvedBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    final statusBarBg = config?.statusBarColor ??
        config?.appBarColor ??
        background ??
        IsrColors.appBarColor;
    final navBarBg =
        config?.navigationBarColor ?? config?.statusBarColor ?? statusBarBg;
    final statusBarIcons =
        config?.statusBarIconBrightness ?? defaultIconBrightness;
    final statusBarBrightnessValue = config?.statusBarBrightness ??
        (statusBarIcons == Brightness.dark
            ? Brightness.light
            : Brightness.dark);
    final navBarIcons =
        config?.navigationBarIconBrightness ?? statusBarIcons;

    final baseStyle = resolvedBrightness == Brightness.dark
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return baseStyle.copyWith(
      statusBarColor: statusBarBg,
      statusBarIconBrightness: statusBarIcons,
      statusBarBrightness: statusBarBrightnessValue,
      systemNavigationBarColor: navBarBg,
      systemNavigationBarIconBrightness: navBarIcons,
      systemNavigationBarContrastEnforced: false,
    );
  }

  /// White/light bars with dark icons using theme config when available.
  static SystemUiOverlayStyle lightBarsOverlay({
    Color? background,
    ThemeConfig? themeConfig,
  }) =>
      overlay(
        themeConfig: themeConfig ?? IsrVideoReelConfig.socialConfig.themeConfig?.copyWith(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        background: background,
      );
}
