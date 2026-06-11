import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/reels_overlay_text.dart';

/// Shields SDK UI from host-app [DefaultTextStyle] and [Theme] text styles.
///
/// Host apps often wrap [IsmPostView] in theme `bodyMedium` for a Feed tab.
/// Material 3 theme text can set [TextStyle.foreground], which overrides
/// [TextStyle.color] when styles merge and makes reels overlay labels black.
class IsrSdkTextStyleScope extends StatelessWidget {
  const IsrSdkTextStyleScope({
    super.key,
    required this.child,
    this.useReelsOverlayDefaults = false,
  });

  final Widget child;

  /// `true` on For You / Following reels tabs; `false` on the post Feed tab.
  final bool useReelsOverlayDefaults;

  @override
  Widget build(BuildContext context) {
    final color = useReelsOverlayDefaults
        ? ReelsOverlayText.foreground
        : IsrVideoReelConfig.postConfig.resolvedPostFeedUIConfig.headerTextColor;

    final baseStyle = TextStyle(
      inherit: false,
      color: color,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );

    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: color,
          displayColor: color,
        ),
        primaryTextTheme: theme.primaryTextTheme.apply(
          bodyColor: color,
          displayColor: color,
        ),
      ),
      child: DefaultTextStyle(
        style: baseStyle,
        child: child,
      ),
    );
  }
}
