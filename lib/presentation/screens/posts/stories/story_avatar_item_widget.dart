import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

/// Small reusable avatar tile for one story group entry in strip.
class StoryAvatarItemWidget extends StatelessWidget {
  const StoryAvatarItemWidget({
    super.key,
    required this.group,
    required this.avatarSize,
    required this.showTitle,
    this.onTap,
    this.titleStyle,
    this.fullyViewedRingColor,
    this.hasUnviewedRingColor,
    this.seenBorderColor,
    this.unseenBorderColor,
  });

  final StoryGroup group;
  final double avatarSize;
  final bool showTitle;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;

  final Color? fullyViewedRingColor;

  final Color? hasUnviewedRingColor;

  final Color? seenBorderColor;

  final Color? unseenBorderColor;

  Color _ringColor(ColorScheme scheme) {
    final viewed = fullyViewedRingColor ?? seenBorderColor ?? scheme.outline;
    final unviewed =
        hasUnviewedRingColor ?? unseenBorderColor ?? scheme.primary;
    return group.allStoriesViewed ? viewed : unviewed;
  }

  String get _resolvedAvatarUrl {
    final avatar = group.avatarUrl.trim();
    if (avatar.isNotEmpty) return avatar;
    if (group.stories.isNotEmpty) {
      final mediaUrl = group.stories.first.mediaUrl.trim();
      if (mediaUrl.isNotEmpty) return mediaUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: avatarSize + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _ringColor(Theme.of(context).colorScheme),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _resolvedAvatarUrl.isEmpty
                      ? Container(color: Colors.white24)
                      : AppImage.network(
                          _resolvedAvatarUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              if (showTitle) ...[
                const SizedBox(height: 6),
                Text(group.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle ??
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
              ],
            ],
          ),
        ),
      );
}
