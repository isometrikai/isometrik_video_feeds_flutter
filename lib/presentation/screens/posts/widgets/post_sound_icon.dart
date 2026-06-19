import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/res/constants/asset_constants.dart';

/// Visual style for post sound icons in feed vs reels overlay.
enum PostSoundIconStyle {
  /// Instagram-style frosted white note on video overlay (glassy reels).
  glassOverlay,

  /// Feed card meta row — inherits feed icon color.
  feed,

  /// Plain white note on dark reels overlay (default/plain reels theme).
  onDark,
}

/// Music note icon for post sound attribution in feed and reels.
class PostSoundIcon extends StatelessWidget {
  const PostSoundIcon({
    super.key,
    this.size = 14,
    this.style = PostSoundIconStyle.glassOverlay,
    this.color,
  });

  final double size;
  final PostSoundIconStyle style;
  final Color? color;

  Color _defaultColor() => switch (style) {
        PostSoundIconStyle.glassOverlay =>
          Colors.white.withValues(alpha: 0.88),
        PostSoundIconStyle.feed => const Color(0xFF262626),
        PostSoundIconStyle.onDark => Colors.white.withValues(alpha: 0.92),
      };

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? _defaultColor();
    return SvgPicture.asset(
      AssetConstants.icReelsSoundIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
