import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/story_ring_avatar.dart';

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

  String get _resolvedAvatarUrl {
    final avatar = group.avatarUrl.trim();
    if (avatar.isNotEmpty) return avatar;
    if (group.stories.isNotEmpty) {
      final thumb = group.stories.first.thumbDisplayUrl;
      if (thumb.isNotEmpty) return thumb;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: avatarSize + 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoryRingAvatar(
              size: avatarSize,
              imageUrl: _resolvedAvatarUrl,
              hasUnviewed: !group.allStoriesViewed,
            ),
            if (showTitle) ...[
              const SizedBox(height: 6),
              Text(
                group.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle ?? theme.titleStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
