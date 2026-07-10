import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/post_config.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/reels_overlay_text.dart';
import 'package:ism_video_reel_player/res/res.dart';

enum FollowChipVariant {
  /// Gray rectangular chip on the feed header (opaque background).
  feed,

  /// Transparent chip over video (Reels / feed video overlay).
  reelsOverlay,

  /// App theme via [FollowButtonConfig].
  theme,
}

class InstagramFollowChip extends StatelessWidget {
  const InstagramFollowChip({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
    required this.variant,
    this.followButtonConfig,
    this.headerTextColor,
    this.feedBackgroundIsDark = false,
    this.followButtonTextStyle,
    this.followingButtonTextStyle,
    this.textShadows,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final FollowChipVariant variant;
  final FollowButtonConfig? followButtonConfig;
  final Color? headerTextColor;
  final bool feedBackgroundIsDark;
  final TextStyle? followButtonTextStyle;
  final TextStyle? followingButtonTextStyle;
  final List<Shadow>? textShadows;

  @override
  Widget build(BuildContext context) {
    final borderRadius = IsrDimens.eight;
    final height =
        followButtonConfig?.followButtonHeight ?? IsrDimens.twentyEight;

    return Container(
      height: height,
      decoration: _decoration(context, borderRadius),
      child: MaterialButton(
        onPressed: onTap,
        elevation: 0,
        highlightElevation: 0,
        minWidth:
            followButtonConfig?.followButtonMinWidth ?? IsrDimens.fiftySix,
        height: height,
        padding: followButtonConfig?.followButtonPadding ??
            IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: Colors.transparent,
        child: _label(context),
      ),
    );
  }

  Widget _label(BuildContext context) {
    final style = _textStyle(context);
    if (variant == FollowChipVariant.reelsOverlay) {
      return ReelsOverlayText(
        label,
        color: style.color ?? ReelsOverlayText.foreground,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontFamily: style.fontFamily,
        letterSpacing: style.letterSpacing,
        height: style.height,
        shadows: textShadows,
      );
    }
    return Text(label, style: style);
  }

  BoxDecoration _decoration(BuildContext context, double borderRadius) {
    switch (variant) {
      case FollowChipVariant.feed:
        if (filled) {
          return BoxDecoration(
            color: feedBackgroundIsDark
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(borderRadius),
          );
        }
        return BoxDecoration(
          color: feedBackgroundIsDark
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: feedBackgroundIsDark
                ? Colors.white.withValues(alpha: 0.28)
                : const Color(0xFFDBDBDB),
          ),
        );
      case FollowChipVariant.reelsOverlay:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: filled ? 0.9 : 0.7),
            width: IsrDimens.one,
          ),
        );
      case FollowChipVariant.theme:
        if (filled) {
          return followButtonConfig?.followButtonDecoration ??
              BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(borderRadius),
              );
        }
        return followButtonConfig?.followingButtonDecoration ??
            BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: IsrColors.white, width: IsrDimens.one),
            );
    }
  }

  TextStyle _textStyle(BuildContext context) {
    switch (variant) {
      case FollowChipVariant.feed:
        return IsrStyles.primaryText12.copyWith(
          fontWeight: FontWeight.w600,
          color: headerTextColor,
        );
      case FollowChipVariant.reelsOverlay:
        // Glyph shadows applied via [ReelsOverlayText] to avoid Impeller ghosting.
        return IsrStyles.primaryText12.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
      case FollowChipVariant.theme:
        if (filled) {
          return followButtonTextStyle ??
              IsrStyles.white12.copyWith(fontWeight: FontWeight.w600);
        }
        return followingButtonTextStyle ??
            IsrStyles.white12.copyWith(fontWeight: FontWeight.w600);
    }
  }
}
