import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_create_flow.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/add_story_tile.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/story_ring_avatar.dart';

/// Horizontal stories strip with Add / Your Story tile and themed gradient rings.
class StoryStripWidget extends StatefulWidget {
  const StoryStripWidget({super.key});

  @override
  State<StoryStripWidget> createState() => _StoryStripWidgetState();
}

class _StoryStripWidgetState extends State<StoryStripWidget> {
  String _currentUserAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAvatar();
  }

  Future<void> _loadCurrentUserAvatar() async {
    final resolver = IsrVideoReelConfig
        .storyConfig?.storyCallbackConfig.resolveCurrentUserAvatarUrl;
    final url = resolver != null ? await resolver() : null;
    if (!mounted) return;
    setState(() => _currentUserAvatarUrl = url?.trim() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final storyConfig = IsrVideoReelConfig.storyConfig;
    if (storyConfig == null) return const SizedBox.shrink();

    final uiConfig = storyConfig.storyUiConfig;
    final theme = StoryThemeResolver.of(context);
    final currentUserId =
        context.select((StoryCubit cubit) => cubit.currentUserId);

    return BlocBuilder<StoryCubit, StoryState>(
      builder: (context, state) {
        final cubit = context.read<StoryCubit>();
        final density = Theme.of(context).visualDensity;
        final avatarSize =
            uiConfig.avatarSize ?? 64.0 + density.horizontal * 2;
        final itemSpacing =
            uiConfig.itemSpacing ?? 14.0 + density.horizontal.abs();

        final groups = switch (state) {
          StoryFeedLoaded(:final unViewed, :final viewed) =>
            [...unViewed, ...viewed],
          _ => cubit.cachedStoryGroups,
        };

        final feedGroups =
            groups.where((g) => g.stories.isNotEmpty).toList();

        StoryGroup? ownGroup;
        final otherGroups = <StoryGroup>[];
        for (final group in feedGroups) {
          final isOwn = currentUserId.isNotEmpty &&
              group.userId == currentUserId;
          if (isOwn) {
            ownGroup ??= group;
          } else {
            otherGroups.add(group);
          }
        }

        final showAdd = uiConfig.showAddStoryTile;
        if (!showAdd && otherGroups.isEmpty && ownGroup == null) {
          return const SizedBox.shrink();
        }

        // Own story stays in the first circle; others follow after it.
        final viewerGroups = [
          if (ownGroup != null) ownGroup,
          ...otherGroups,
        ];

        return Container(
          width: double.infinity,
          color: uiConfig.backgroundColor ?? theme.scaffoldBackground,
          padding: uiConfig.containerPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: uiConfig.showTitles ? avatarSize + 28 : avatarSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (showAdd ? 1 : 0) +
                  (showAdd ? otherGroups.length : viewerGroups.length),
              separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
              itemBuilder: (_, index) {
                if (showAdd && index == 0) {
                  final avatarUrl = _currentUserAvatarUrl.isNotEmpty
                      ? _currentUserAvatarUrl
                      : (ownGroup != null
                          ? _avatarUrlForGroup(ownGroup)
                          : '');
                  return AddStoryTile(
                    avatarSize: avatarSize,
                    profileImageUrl: avatarUrl,
                    hasActiveStory: ownGroup != null,
                    hasUnviewed: ownGroup != null && !ownGroup.allStoriesViewed,
                    onAddTap: () => StoryCreateFlow.open(context),
                    onViewStory: ownGroup == null
                        ? null
                        : () async {
                            final hostTap =
                                storyConfig.storyCallbackConfig.onStoryTap;
                            if (hostTap != null) {
                              await hostTap(ownGroup!.stories.first);
                              await cubit
                                  .markStoryViewed(ownGroup.stories.first.id);
                              return;
                            }
                            await IsrAppNavigator.presentStoryViewer(
                              context,
                              groups: viewerGroups,
                              initialGroupIndex: 0,
                            );
                          },
                  );
                }

                final groupIndex = showAdd ? index - 1 : index;
                final group = showAdd
                    ? otherGroups[groupIndex]
                    : viewerGroups[groupIndex];
                final viewerIndex = showAdd
                    ? (ownGroup != null ? groupIndex + 1 : groupIndex)
                    : groupIndex;

                return _StoryStripTile(
                  avatarSize: avatarSize,
                  imageUrl: _avatarUrlForGroup(group),
                  label: group.username,
                  hasUnviewed: !group.allStoriesViewed,
                  titleStyle: theme.titleStyle,
                  onTap: () async {
                    if (group.stories.isEmpty) return;
                    final hostTap =
                        storyConfig.storyCallbackConfig.onStoryTap;
                    if (hostTap != null) {
                      await hostTap(group.stories.first);
                      await cubit.markStoryViewed(group.stories.first.id);
                      return;
                    }
                    await IsrAppNavigator.presentStoryViewer(
                      context,
                      groups: viewerGroups,
                      initialGroupIndex: viewerIndex,
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

  String _avatarUrlForGroup(StoryGroup group) {
    final avatar = group.avatarUrl.trim();
    if (avatar.isNotEmpty) return avatar;
    if (group.stories.isNotEmpty) {
      return group.stories.first.thumbDisplayUrl;
    }
    return '';
  }
}

class _StoryStripTile extends StatelessWidget {
  const _StoryStripTile({
    required this.avatarSize,
    required this.imageUrl,
    required this.label,
    required this.hasUnviewed,
    required this.titleStyle,
    required this.onTap,
  });

  final double avatarSize;
  final String imageUrl;
  final String label;
  final bool hasUnviewed;
  final TextStyle titleStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: avatarSize + 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StoryRingAvatar(
                size: avatarSize,
                imageUrl: imageUrl,
                hasUnviewed: hasUnviewed,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ],
          ),
        ),
      );
}
