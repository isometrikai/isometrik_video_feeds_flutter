import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/story_ring_avatar.dart';

class AddStoryTile extends StatelessWidget {
  const AddStoryTile({
    super.key,
    required this.avatarSize,
    required this.profileImageUrl,
    required this.onTap,
  });

  final double avatarSize;
  final String profileImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    final ui =
        IsrVideoReelConfig.storyConfig?.storyUiConfig ?? const StoryUiConfig();
    final accent = ui.addStoryAccentColor ?? theme.primary;
    final label = ui.addStoryTitle ?? 'Add Story';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: avatarSize + 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                StoryRingAvatar(
                  size: avatarSize,
                  imageUrl: profileImageUrl,
                  hasUnviewed: false,
                  ringWidth: 2,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.addStoryLabelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
