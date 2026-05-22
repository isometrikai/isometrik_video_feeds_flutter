import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

class StoryThemeResolver {
  StoryThemeResolver._(this.ui);

  final StoryUiConfig ui;

  static StoryThemeResolver of(BuildContext context) {
    final ui =
        IsrVideoReelConfig.storyConfig?.storyUiConfig ?? const StoryUiConfig();
    return StoryThemeResolver._(ui);
  }

  ThemeConfig get _theme =>
      IsrVideoReelConfig.socialConfig.themeConfig ?? const ThemeConfig();

  Color get primary =>
      ui.primaryButtonColor ??
      ui.addStoryAccentColor ??
      _theme.primaryColor ??
      IsrColors.appColor;

  Color get secondary => _theme.secondaryColor ?? IsrColors.secondaryColor;

  Color get scaffoldBackground =>
      ui.bottomSheetBackgroundColor ??
      ui.backgroundColor ??
      _theme.scaffoldBackgroundColor ??
      IsrColors.scaffoldColor;

  Color get textPrimary =>
      ui.bottomSheetTextColor ?? IsrColors.primaryTextColor;

  Color get textSecondary =>
      ui.bottomSheetSecondaryTextColor ?? IsrColors.secondaryTextColor;

  Color get seenRing =>
      ui.fullyViewedRingColor ??
      ui.seenBorderColor ??
      textSecondary.withValues(alpha: 0.55);

  List<Color> get unseenGradient {
    if (ui.unseenRingGradientColors != null &&
        ui.unseenRingGradientColors!.length >= 2) {
      return ui.unseenRingGradientColors!;
    }
    final main = ui.hasUnviewedRingColor ?? ui.unseenBorderColor ?? primary;
    return [main, secondary, Color.lerp(main, secondary, 0.35) ?? main];
  }

  Color get destructive => ui.destructiveColor ?? const Color(0xFFB00020);

  Color get success => ui.successColor ?? const Color(0xFF22C55E);

  Color get onPrimary =>
      ui.onPrimaryButtonColor ??
      (primary.computeLuminance() > 0.5 ? textPrimary : Colors.white);

  TextStyle get titleStyle =>
      ui.titleStyle ??
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  TextStyle get addStoryLabelStyle =>
      ui.addStoryLabelStyle ??
      titleStyle.copyWith(
        color: ui.addStoryAccentColor ?? primary,
        fontWeight: FontWeight.w600,
      );
}
