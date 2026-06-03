import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/res/theme/isr_colors.dart';

/// System UI for light screens: white status/nav bars and dark icons.
class IsrSystemUi {
  IsrSystemUi._();

  static SystemUiOverlayStyle lightBarsOverlay({
    Color? background,
  }) =>
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: background ?? IsrColors.navigationBar,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: background ?? IsrColors.navigationBar,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      );
}
