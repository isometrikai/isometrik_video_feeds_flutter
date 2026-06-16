import 'package:flutter/material.dart';

/// Threads-style follow affordance overlapping the profile avatar bottom-right.
class FeedTextPostAvatarFollowBadge extends StatelessWidget {
  const FeedTextPostAvatarFollowBadge({
    super.key,
    required this.avatar,
    required this.avatarSize,
    this.badge,
  });

  final Widget avatar;
  final double avatarSize;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            if (badge != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: badge!,
              ),
          ],
        ),
      );
}

/// Small circular badge on the avatar for follow / following states.
class FeedTextPostFollowBadgeIcon extends StatelessWidget {
  const FeedTextPostFollowBadgeIcon({
    super.key,
    required this.borderColor,
    required this.backgroundColor,
    required this.iconColor,
    this.icon = Icons.add,
    this.size = 20,
    this.borderWidth = 2.5,
  });

  /// Light feed: white border, black fill, white icon.
  /// Dark feed: black border, white fill, black icon.
  factory FeedTextPostFollowBadgeIcon.themed({
    required bool isDarkFeedBackground,
    IconData icon = Icons.add,
    double size = 20,
  }) {
    if (isDarkFeedBackground) {
      return FeedTextPostFollowBadgeIcon(
        borderColor: Colors.black,
        backgroundColor: Colors.white,
        iconColor: Colors.black,
        icon: icon,
        size: size,
      );
    }
    return FeedTextPostFollowBadgeIcon(
      borderColor: Colors.white,
      backgroundColor: Colors.black,
      iconColor: Colors.white,
      icon: icon,
      size: size,
    );
  }

  final Color borderColor;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.55,
          color: iconColor,
          weight: 700,
        ),
      );
}
