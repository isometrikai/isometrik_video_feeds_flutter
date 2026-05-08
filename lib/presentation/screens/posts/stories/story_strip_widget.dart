import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

/// Horizontal stories strip rendered above tab bar when story config is enabled.
class StoryStripWidget extends StatelessWidget {
  const StoryStripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final storyConfig = IsrVideoReelConfig.storyConfig;
    if (storyConfig == null) return const SizedBox.shrink();

    final uiConfig = storyConfig.storyUiConfig;
    final currentUserId = context.select((StoryCubit cubit) => cubit.currentUserId);
    return BlocBuilder<StoryCubit, StoryState>(
      builder: (context, state) {
        final density = Theme.of(context).visualDensity;
        final avatarSize =
            uiConfig.avatarSize ?? 48.0 + density.horizontal * 2;
        final itemSpacing =
            uiConfig.itemSpacing ?? 8.0 + density.horizontal.abs();
        final groups = switch (state) {
          StoryFeedLoaded() => [...state.unViewed, ...state.viewed],
          _ => <StoryGroup>[],
        };
        if (groups.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          color: uiConfig.backgroundColor ?? Colors.transparent,
          padding: uiConfig.containerPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: uiConfig.showTitles ? avatarSize + 28 : avatarSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
              itemBuilder: (_, index) {
                final group = groups[index];
                final displayName = group.userId == currentUserId && currentUserId.isNotEmpty
                    ? 'Your story'
                    : group.username;
                final displayGroup = StoryGroup(
                  userId: group.userId,
                  username: displayName,
                  avatarUrl: group.avatarUrl,
                  stories: group.stories,
                  isViewed: group.isViewed,
                );
                return StoryAvatarItemWidget(
                  group: displayGroup,
                  avatarSize: avatarSize,
                  showTitle: uiConfig.showTitles,
                  titleStyle: uiConfig.titleStyle,
                  fullyViewedRingColor: uiConfig.fullyViewedRingColor,
                  hasUnviewedRingColor: uiConfig.hasUnviewedRingColor,
                  seenBorderColor: uiConfig.seenBorderColor,
                  unseenBorderColor: uiConfig.unseenBorderColor,
                  onTap: () async {
                    if (group.stories.isEmpty) return;
                    final hostTap = storyConfig.storyCallbackConfig.onStoryTap;
                    if (hostTap != null) {
                      await hostTap(group.stories.first);
                      await context
                          .read<StoryCubit>()
                          .markStoryViewed(group.stories.first.id);
                      return;
                    }
                    await IsrAppNavigator.presentStoryViewer(
                      context,
                      groups: groups,
                      initialGroupIndex: index,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
