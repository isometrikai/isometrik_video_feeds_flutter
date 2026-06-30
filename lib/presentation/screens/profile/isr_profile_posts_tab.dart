import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/social_action/social_action_cubit.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_thumbnail.dart';
import 'package:ism_video_reel_player/presentation/screens/profile/profile_posts_placeholder.dart';
import 'package:ism_video_reel_player/presentation/screens/profile/profile_text_posts_feed.dart';
import 'package:ism_video_reel_player/presentation/screens/profile/widgets/paid_post_locked_profile_thumbnail.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';
import 'package:ism_video_reel_player/utils/profile_media_url_util.dart';
import 'package:ism_video_reel_player/utils/profile_post_type_filter.dart';
import 'package:ism_video_reel_player/utils/timeline_post_type_util.dart';

/// Profile posts tab grid (and optional media/text filter pills).
class IsrProfilePostsTab extends StatelessWidget {
  const IsrProfilePostsTab({
    super.key,
    required this.isLoading,
    required this.posts,
    required this.onRefresh,
    required this.postSectionType,
    this.extractMediaUrl,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.tagValue,
    this.tagType,
    this.onMentionRemoved,
    this.loggedInUserId,
    this.isLoadingMore = false,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final List<dynamic> posts;
  final Future<void> Function() onRefresh;
  final PostSectionType postSectionType;
  final String? Function(dynamic post)? extractMediaUrl;
  final String? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? tagValue;
  final TagType? tagType;
  final void Function(String postId, String userId)? onMentionRemoved;
  final String? loggedInUserId;

  bool get _usePostTypeFilter =>
      IsrVideoReelConfig.postConfig.resolvedProfilePostsConfig
          .enablePostTypeTabs;

  @override
  Widget build(BuildContext context) {
    if (_usePostTypeFilter) {
      return _ProfilePostsTypeFilterTab(
        isLoading: isLoading,
        posts: posts.whereType<TimeLineData>().toList(),
        extractMediaUrl: extractMediaUrl,
        onRefresh: onRefresh,
        emptyIcon: emptyIcon,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        postSectionType: postSectionType,
        tagValue: tagValue,
        tagType: tagType,
        onMentionRemoved: onMentionRemoved,
        loggedInUserId: loggedInUserId,
        isLoadingMore: isLoadingMore,
      );
    }

    return _ProfilePostsSocialListener(
      onRefresh: onRefresh,
      onMentionRemoved: onMentionRemoved,
      postSectionType: postSectionType,
      child: _ProfilePostsGrid(
        isLoading: isLoading,
        posts: posts,
        extractMediaUrl: extractMediaUrl,
        emptyIcon: emptyIcon,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        postSectionType: postSectionType,
        tagValue: tagValue,
        tagType: tagType,
        loggedInUserId: loggedInUserId,
      ),
    );
  }
}

class _ProfilePostsTypeFilterTab extends StatefulWidget {
  const _ProfilePostsTypeFilterTab({
    required this.isLoading,
    required this.posts,
    required this.onRefresh,
    required this.postSectionType,
    this.extractMediaUrl,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.tagValue,
    this.tagType,
    this.onMentionRemoved,
    this.loggedInUserId,
    this.isLoadingMore = false,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final List<TimeLineData> posts;
  final String? Function(dynamic post)? extractMediaUrl;
  final Future<void> Function() onRefresh;
  final String? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final PostSectionType postSectionType;
  final String? tagValue;
  final TagType? tagType;
  final void Function(String postId, String userId)? onMentionRemoved;
  final String? loggedInUserId;

  @override
  State<_ProfilePostsTypeFilterTab> createState() =>
      _ProfilePostsTypeFilterTabState();
}

class _ProfilePostsTypeFilterTabState extends State<_ProfilePostsTypeFilterTab> {
  ProfilePostTypeFilter _selectedFilter = ProfilePostTypeFilter.media;

  @override
  Widget build(BuildContext context) {
    final profileConfig =
        IsrVideoReelConfig.postConfig.resolvedProfilePostsConfig;
    final filteredPosts = filterProfilePostsByType(
      widget.posts,
      _selectedFilter,
    );
    final isMediaFilter = _selectedFilter == ProfilePostTypeFilter.media;

    return _ProfilePostsSocialListener(
      onRefresh: widget.onRefresh,
      onMentionRemoved: widget.onMentionRemoved,
      postSectionType: widget.postSectionType,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _ProfilePostTypePill(
                title: IsrTranslationFile.profileMediaPostsTab,
                isSelected: isMediaFilter,
                onTap: () => setState(
                  () => _selectedFilter = ProfilePostTypeFilter.media,
                ),
              ),
              const SizedBox(width: 8),
              _ProfilePostTypePill(
                title: IsrTranslationFile.profileTextPostsTab,
                isSelected: !isMediaFilter,
                onTap: () => setState(
                  () => _selectedFilter = ProfilePostTypeFilter.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isMediaFilter)
            _ProfilePostsGrid(
              isLoading: widget.isLoading,
              posts: filteredPosts,
              extractMediaUrl: widget.extractMediaUrl,
              emptyIcon: profileConfig.resolvedNoMediaPostsIcon,
              emptyTitle: IsrTranslationFile.profileNoMediaPostsTitle,
              emptySubtitle: IsrTranslationFile.profileNoMediaPostsSubtitle,
              postSectionType: widget.postSectionType,
              tagValue: widget.tagValue,
              tagType: widget.tagType,
              loggedInUserId: widget.loggedInUserId,
            )
          else
            _ProfileTextFeedBleedOut(
              horizontalInset: profileConfig.textFeedHorizontalInset,
              child: ProfileTextPostsFeed(
                posts: filteredPosts,
                isLoading: widget.isLoading,
                isLoadingMore: widget.isLoadingMore,
                postSectionType: widget.postSectionType,
                loggedInUserId: widget.loggedInUserId,
              ),
            ),
        ],
      ),
    );
  }
}

/// Expands [child] to full screen width by offsetting host horizontal padding.
class _ProfileTextFeedBleedOut extends StatelessWidget {
  const _ProfileTextFeedBleedOut({
    required this.horizontalInset,
    required this.child,
  });

  final double horizontalInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (horizontalInset <= 0) return child;

    return LayoutBuilder(
      builder: (context, constraints) => Transform.translate(
        offset: Offset(-horizontalInset, 0),
        child: SizedBox(
          width: constraints.maxWidth + horizontalInset * 2,
          child: child,
        ),
      ),
    );
  }
}

class _ProfilePostTypePill extends StatelessWidget {
  const _ProfilePostTypePill({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = IsrVideoReelConfig.socialConfig.themeConfig;
    final primary = theme?.primaryColor ?? IsrColors.appColor;
    final background = theme?.scaffoldBackgroundColor ?? Colors.white;
    final selectedFill = Color.alphaBlend(
      primary.withValues(alpha: 0.12),
      background,
    );
    final textColor = const Color(0xFF242424);
    final borderColor = isSelected ? primary : const Color(0xFFD8DEF3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ProfilePostsSocialListener extends StatelessWidget {
  const _ProfilePostsSocialListener({
    required this.onRefresh,
    required this.postSectionType,
    required this.child,
    this.onMentionRemoved,
  });

  final Future<void> Function() onRefresh;
  final PostSectionType postSectionType;
  final Widget child;
  final void Function(String postId, String userId)? onMentionRemoved;

  bool get _isTaggedPostSection =>
      postSectionType == PostSectionType.myTaggedPost ||
      postSectionType == PostSectionType.tagPost;

  @override
  Widget build(BuildContext context) {
    return context.attachBlocIfNeeded<IsmSocialActionCubit>(
      bloc: context.getOrCreateBloc<IsmSocialActionCubit>(),
      child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
        listenWhen: (previous, current) =>
            current is IsmDeletedPostActionListenerState ||
            current is IsmEditPostActionListenerState ||
            current is IsmCreatePostActionListenerState ||
            (current is IsmMentionRemovedActionListenerState &&
                _isTaggedPostSection),
        listener: (context, state) {
          if (state is IsmDeletedPostActionListenerState ||
              state is IsmEditPostActionListenerState ||
              state is IsmCreatePostActionListenerState) {
            onRefresh();
          } else if (state is IsmMentionRemovedActionListenerState) {
            final removed = onMentionRemoved;
            if (removed != null) {
              removed(state.postId, state.userId);
            } else {
              onRefresh();
            }
          }
        },
        child: child,
      ),
    );
  }
}

class _ProfilePostsGrid extends StatelessWidget {
  const _ProfilePostsGrid({
    required this.isLoading,
    required this.posts,
    required this.postSectionType,
    this.extractMediaUrl,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.tagValue,
    this.tagType,
    this.loggedInUserId,
  });

  final bool isLoading;
  final List<dynamic> posts;
  final String? Function(dynamic post)? extractMediaUrl;
  final String? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final PostSectionType postSectionType;
  final String? tagValue;
  final TagType? tagType;
  final String? loggedInUserId;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(children: [SizedBox(height: 100), AppLoader()]),
      );
    }

    if (posts.isEmpty) {
      return ProfilePostsPlaceholder(
        icon: emptyIcon ?? AssetConstants.icNoProfilePosts,
        title: emptyTitle ?? IsrTranslationFile.noPostAvailable,
        subtitle: emptySubtitle ?? '',
      );
    }

    final profileConfig =
        IsrVideoReelConfig.postConfig.resolvedProfilePostsConfig;
    final cardsBg =
        IsrVideoReelConfig.socialConfig.themeConfig?.scaffoldBackgroundColor ??
            const Color(0xFFF5F5F5);
    final resolveMediaUrl =
        extractMediaUrl ?? ProfileMediaUrlUtil.extractMediaUrl;

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 30),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postDataList = posts.whereType<TimeLineData>().toList();
        final post = posts[index] is TimeLineData
            ? posts[index] as TimeLineData
            : null;
        final mediaUrl = resolveMediaUrl(posts[index]) ?? '';
        final isPaidLocked = shouldShowPaidLockedProfileThumbnailForPost(post);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: cardsBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TapHandler(
            onTap: () {
              final tappedPost = posts[index];
              final startIndex = tappedPost is TimeLineData
                  ? postDataList.indexOf(tappedPost)
                  : index;
              if (startIndex < 0) return;
              final postConfig = IsrVideoReelConfig.postConfig;
              final overlayPadding = profileConfig.reelsPlayerOverlayPadding;
              final playerPostConfig = overlayPadding != null
                  ? postConfig.copyWith(
                      postUIConfig: (postConfig.postUIConfig ??
                              const PostUIConfig())
                          .copyWith(overlayPadding: overlayPadding),
                    )
                  : postConfig;
              IsrAppNavigator.navigateToReelsPlayer(
                context,
                postDataList: postDataList,
                startingPostIndex: startIndex,
                postSectionType: postSectionType,
                tagValue: tagValue,
                tagType: tagType,
                postConfig: playerPostConfig,
                tabConfig: profileConfig.tabConfig,
              );
            },
            child: PaidPostLockedProfileThumbnail(
              isLocked: isPaidLocked,
              child: _ProfilePostThumbnail(
                post: post,
                mediaUrl: mediaUrl,
                isPaidLocked: isPaidLocked,
                views: post?.engagementMetrics?.views?.toInt() ?? 0,
                placeholderColor: cardsBg,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfilePostThumbnail extends StatelessWidget {
  const _ProfilePostThumbnail({
    required this.post,
    required this.mediaUrl,
    required this.isPaidLocked,
    required this.views,
    required this.placeholderColor,
  });

  final TimeLineData? post;
  final String mediaUrl;
  final bool isPaidLocked;
  final int views;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    if (post?.isTextOnlyPost == true) {
      return TextPostThumbnail.fromPost(post!);
    }

    if (mediaUrl.isEmpty) {
      return ColoredBox(
        color: placeholderColor,
        child: const Center(
          child: Icon(Icons.image, color: Color(0xFF979797)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AppImage.network(
            mediaUrl,
            fit: BoxFit.cover,
          ),
        ),
        if (!isPaidLocked)
          Positioned(
            bottom: 4,
            left: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                const SizedBox(width: 3),
                Text(
                  '$views',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
