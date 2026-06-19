import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/post_config.dart';
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
    final height =
        followButtonConfig?.followButtonHeight ?? IsrDimens.twentyEight;
    final decoration = _decoration(context);
    final borderRadius = _resolveBorderRadius(decoration);
    final padding = followButtonConfig?.followButtonPadding ??
        IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.eight);

    return Container(
      height: height,
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              child: Text(label, style: _textStyle(context)),
            ),
          ),
        ),
      ),
    );
  }

  double _resolveBorderRadius(BoxDecoration decoration) {
    final radius = decoration.borderRadius;
    if (radius is BorderRadius) {
      return radius.topLeft.x;
    }
    return IsrDimens.eight;
  }

  BoxDecoration _decoration(BuildContext context) {
    final borderRadius = IsrDimens.eight;

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
        return followButtonConfig?.followButtonDecoration ??
            followButtonConfig?.followingButtonDecoration ??
            BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(borderRadius),
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
        return IsrStyles.primaryText12.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: textShadows,
        );
      case FollowChipVariant.theme:
        return followButtonTextStyle ??
            followingButtonTextStyle ??
            IsrStyles.white12.copyWith(fontWeight: FontWeight.w600);
    }
  }
}
