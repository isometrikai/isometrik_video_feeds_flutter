import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_scroll_scope.dart';
import 'package:ism_video_reel_player/presentation/screens/profile/profile_posts_placeholder.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';
import 'package:ism_video_reel_player/utils/profile_post_more_options.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Text posts list for profile tabs — matches home [PostFeedListWidget] styling
/// but uses [shrinkWrap] for nested profile scroll views.
class ProfileTextPostsFeed extends StatefulWidget {
  const ProfileTextPostsFeed({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.postSectionType,
    this.isLoadingMore = false,
    this.loggedInUserId,
    this.profileOwnerUserId,
    this.profileOwnerClientUserId,
  });

  final List<TimeLineData> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final PostSectionType postSectionType;
  final String? loggedInUserId;
  final String? profileOwnerUserId;
  final String? profileOwnerClientUserId;

  @override
  State<ProfileTextPostsFeed> createState() => _ProfileTextPostsFeedState();
}

class _ProfileTextPostsFeedState extends State<ProfileTextPostsFeed> {
  final Map<int, double> _visibilityFractions = {};
  final ValueNotifier<int?> _activePlayIndexNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _activePlayIndexNotifier.dispose();
    super.dispose();
  }

  void _onItemVisibilityFractionChanged(int index, double visibleFraction) {
    _visibilityFractions[index] = visibleFraction;
    const minPlay = 0.32;
    const stickyPlay = 0.22;
    const switchLead = 0.06;

    final current = _activePlayIndexNotifier.value;
    if (current == index) {
      if (visibleFraction < stickyPlay) {
        _activePlayIndexNotifier.value = null;
      }
      return;
    }

    if (visibleFraction < minPlay) return;

    if (current == null) {
      _activePlayIndexNotifier.value = index;
      return;
    }

    final currentFraction = _visibilityFractions[current] ?? 0;
    if (visibleFraction >= currentFraction + switchLead) {
      _activePlayIndexNotifier.value = index;
    }
  }

  bool _shouldSuppressProfileNavigation(TimeLineData post) {
    // Main profile posts tab only lists the profile owner's posts.
    if (widget.postSectionType == PostSectionType.myPost ||
        widget.postSectionType == PostSectionType.otherUserPost) {
      return true;
    }

    final ownerIds = <String>{
      if (widget.profileOwnerUserId?.trim().isNotEmpty == true)
        widget.profileOwnerUserId!.trim(),
      if (widget.profileOwnerClientUserId?.trim().isNotEmpty == true)
        widget.profileOwnerClientUserId!.trim(),
    };
    if (ownerIds.isEmpty) return false;

    final authorIds = <String>{
      if (post.user?.id?.trim().isNotEmpty == true) post.user!.id!.trim(),
      if (post.userId?.trim().isNotEmpty == true) post.userId!.trim(),
      if (post.user?.targetId?.trim().isNotEmpty == true)
        post.user!.targetId!.trim(),
    };

    return authorIds.any(ownerIds.contains);
  }

  @override
  Widget build(BuildContext context) {
    final profileConfig =
        IsrVideoReelConfig.postConfig.resolvedProfilePostsConfig;
    final feedUi =
        IsrVideoReelConfig.postConfig.resolvedPostFeedUIConfig;

    if (widget.isLoading) {
      return const Center(
        child: Column(
          children: [SizedBox(height: 100), AppLoader()],
        ),
      );
    }

    if (widget.posts.isEmpty) {
      return ProfilePostsPlaceholder(
        icon: profileConfig.resolvedNoTextPostsIllustration,
        title: IsrTranslationFile.profileNoTextPostsTitle,
        subtitle: IsrTranslationFile.profileNoTextPostsSubtitle,
      );
    }

    final reelsConfig = _buildProfileFeedReelsConfig(
      context: context,
      postSectionType: widget.postSectionType,
      textPostHorizontalPadding: profileConfig.textPostHorizontalPadding,
    );
    final usePostDividers = feedUi.showPostDividers;
    final itemGap =
        usePostDividers ? 0.0 : feedUi.postSpacing.clamp(0.0, double.infinity);
    final itemCount = widget.posts.length + (widget.isLoadingMore ? 1 : 0);

    return context.attachBlocIfNeeded<SocialPostBloc>(
      child: ColoredBox(
        color: feedUi.backgroundColor,
        child: PostFeedScrollScope(
          isScrolling: false,
          child: ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 30),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (context, index) {
            if (index >= widget.posts.length - 1) {
              return const SizedBox.shrink();
            }
            if (usePostDividers) {
              final dividerGapBefore =
                  feedUi.postDividerSpacing.clamp(0.0, double.infinity);
              final dividerGapAfter =
                  feedUi.postDividerSpacingAfter.clamp(0.0, double.infinity);
              return Padding(
                padding: EdgeInsets.only(
                  top: dividerGapBefore,
                  bottom: dividerGapAfter,
                ),
                child: Divider(
                  height: IsrDimens.one,
                  thickness: IsrDimens.one,
                  color: feedUi.dividerColor,
                ),
              );
            }
            return itemGap > 0
                ? SizedBox(height: itemGap)
                : const SizedBox.shrink();
          },
          itemBuilder: (context, index) {
            if (index >= widget.posts.length) {
              return _buildPaginationLoader(feedUi);
            }

            final post = widget.posts[index];
            final reelsData = getReelData(
              post,
              loggedInUserId: widget.loggedInUserId,
            );

            return ValueListenableBuilder<int?>(
              valueListenable: _activePlayIndexNotifier,
              builder: (context, activePlayIndex, _) {
                final isFirstItemByDefault =
                    activePlayIndex == null && index == 0;
                final suppressProfileNavigation =
                    _shouldSuppressProfileNavigation(post);
                return _ProfileTextPostFeedItem(
                  key: ValueKey(post.id),
                  index: index,
                  reelsData: reelsData,
                  reelsConfig: reelsConfig,
                  postSectionType: widget.postSectionType,
                  loggedInUserId: widget.loggedInUserId,
                  suppressProfileNavigation: suppressProfileNavigation,
                  isPostVisible:
                      isFirstItemByDefault || activePlayIndex == index,
                  onVisibilityFractionChanged: _onItemVisibilityFractionChanged,
                  onTapComment: () => _openComments(
                    context,
                    post: post,
                    postSectionType: widget.postSectionType,
                    initialCount: reelsData.commentCount ?? 0,
                  ),
                  onTapShare: () {
                    return IsrVideoReelConfig.postConfig.postCallBackConfig
                            ?.onShareClicked
                            ?.call(post) ??
                        Future<void>.value();
                  },
                  onTapUserProfile: suppressProfileNavigation
                      ? null
                      : () {
                          IsrVideoReelConfig.postConfig.postCallBackConfig
                              ?.onProfileClick
                              ?.call(
                                post,
                                post.user?.id ?? '',
                                post.isFollowing,
                              );
                          return Future<void>.value();
                        },
                  onPressFollowButton: (reelsData, currentFollow) {
                    final postData = reelsData.postData;
                    if (postData is! TimeLineData) {
                      return Future<bool>.value(currentFollow);
                    }
                    return IsrVideoReelConfig.postConfig.postCallBackConfig
                            ?.onFollowClick
                            ?.call(postData, currentFollow) ??
                        Future<bool>.value(currentFollow);
                  },
                  onPressMoreButton: () {
                    unawaited(
                      ProfilePostMoreOptions.show(
                        context: context,
                        post: post,
                        postSectionType: widget.postSectionType,
                        loggedInUserId: widget.loggedInUserId,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildPaginationLoader(PostFeedUIConfig feedUi) {
    final loaderColor = feedUi.secondaryTextColor.withValues(alpha: 0.55);
    final useCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: useCupertino
            ? CupertinoActivityIndicator(radius: 10, color: loaderColor)
            : SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: loaderColor,
                ),
              ),
      ),
    );
  }

  static ReelsConfig _buildProfileFeedReelsConfig({
    required BuildContext context,
    required PostSectionType postSectionType,
    required double textPostHorizontalPadding,
  }) {
    final postConfig = IsrVideoReelConfig.postConfig;
    final profilePostConfig = postConfig.copyWith(
      postFeedUIConfig: postConfig.resolvedPostFeedUIConfig.copyWith(
        textPostHorizontalPadding: textPostHorizontalPadding,
      ),
    );
    final tabData = TabDataModel(
      title: '',
      postSectionType: postSectionType,
      reelsDataList: const [],
    );

    return ReelsConfig(
      postConfig: profilePostConfig,
      isTabVisible: () => true,
      onTapShare: (reelsData) async {
        final postData = reelsData.postData;
        if (postData is TimeLineData) {
          await postConfig.postCallBackConfig?.onShareClicked?.call(postData);
        }
      },
      onTapMentionTag: (reelsData, mentionList) async {
        if (mentionList.isEmpty) return mentionList;
        final postData = reelsData.postData;
        if (postData is! TimeLineData) return mentionList;

        final userId = mentionList.first.userId?.trim() ?? '';
        if (userId.isEmpty) return mentionList;

        postConfig.postCallBackConfig?.onProfileClick?.call(
          postData,
          userId,
          null,
        );
        return mentionList;
      },
      onTapUserProfile: (reelsData) async {
        final postData = reelsData.postData;
        if (postData is TimeLineData) {
          postConfig.postCallBackConfig?.onProfileClick?.call(
            postData,
            reelsData.userId ?? '',
            postData.isFollowing,
          );
        }
      },
      onTapComment: (reelsData, totalCommentsCount) => _openComments(
        context,
        post: reelsData.postData is TimeLineData
            ? reelsData.postData as TimeLineData
            : null,
        postSectionType: postSectionType,
        initialCount: totalCommentsCount,
        tabData: tabData,
      ),
    );
  }

  static Future<int> _openComments(
    BuildContext context, {
    required TimeLineData? post,
    required PostSectionType postSectionType,
    required int initialCount,
    TabDataModel? tabData,
  }) async {
    final postId = post?.id;
    if (postId == null || postId.isEmpty) return initialCount;

    final canAct =
        await IsrVideoReelConfig.socialConfig.socialCallBackConfig
            ?.onLoginInvoked
            ?.call() ??
        true;
    if (!canAct) return initialCount;

    final resolvedTabData =
        tabData ??
        TabDataModel(
          title: '',
          postSectionType: postSectionType,
          reelsDataList: post != null ? [post] : const [],
        );

    final result = await showModalBottomSheet<int>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(sheetContext),
              child: const ColoredBox(color: Color(0x99000000)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(
                  value: IsmInjectionUtils.getBloc<SocialPostBloc>(),
                ),
                BlocProvider.value(
                  value: context.getOrCreateBloc<CommentActionCubit>(),
                ),
                BlocProvider.value(
                  value: context.getOrCreateBloc<SearchUserBloc>(),
                ),
              ],
              child: CommentsBottomSheet(
                postId: postId,
                postData: post,
                tabData: resolvedTabData,
                onTapProfile: (userId) {
                  IsrVideoReelConfig.postConfig.postCallBackConfig
                      ?.onProfileClick
                      ?.call(post, userId, null);
                },
              ),
            ),
          ),
        ],
      ),
    );

    final updatedCount = initialCount + (result ?? 0);
    return updatedCount < 0 ? 0 : updatedCount;
  }
}

class _ProfileTextPostFeedItem extends StatefulWidget {
  const _ProfileTextPostFeedItem({
    super.key,
    required this.index,
    required this.reelsData,
    required this.reelsConfig,
    required this.isPostVisible,
    required this.onVisibilityFractionChanged,
    this.postSectionType,
    this.loggedInUserId,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
    this.onPressFollowButton,
    this.onPressMoreButton,
    this.suppressProfileNavigation = false,
  });

  final int index;
  final ReelsData reelsData;
  final ReelsConfig reelsConfig;
  final PostSectionType? postSectionType;
  final String? loggedInUserId;
  final bool isPostVisible;
  final bool suppressProfileNavigation;
  final void Function(int index, double visibleFraction)
      onVisibilityFractionChanged;
  final Future<int> Function()? onTapComment;
  final Future<void> Function()? onTapShare;
  final Future<void> Function()? onTapUserProfile;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)?
      onPressFollowButton;
  final VoidCallback? onPressMoreButton;

  @override
  State<_ProfileTextPostFeedItem> createState() =>
      _ProfileTextPostFeedItemState();
}

class _ProfileTextPostFeedItemState extends State<_ProfileTextPostFeedItem> {
  late Key _visibilityKey;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _visibilityKey = Key('profile_text_feed_${widget.reelsData.postId}');
  }

  @override
  void didUpdateWidget(covariant _ProfileTextPostFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reelsData.postId != widget.reelsData.postId) {
      VisibilityDetectorController.instance.forget(_visibilityKey);
      _visibilityKey = Key('profile_text_feed_${widget.reelsData.postId}');
      widget.onVisibilityFractionChanged(widget.index, 0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    VisibilityDetectorController.instance.forget(_visibilityKey);
    widget.onVisibilityFractionChanged(widget.index, 0);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_disposed || !mounted) return;
    widget.onVisibilityFractionChanged(widget.index, info.visibleFraction);
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRect(
          child: VisibilityDetector(
            key: _visibilityKey,
            onVisibilityChanged: _onVisibilityChanged,
            child: IsmPostFeedCardView(
              key: ValueKey(widget.reelsData.postId),
              reelsData: widget.reelsData,
              reelsConfig: widget.reelsConfig,
              postSectionType:
                  widget.postSectionType ?? PostSectionType.forYou,
              isPostVisible: widget.isPostVisible,
              suppressProfileNavigation: widget.suppressProfileNavigation,
              loggedInUserId: widget.loggedInUserId,
              logIndex: '${widget.index}',
              onPressFollowButton: widget.onPressFollowButton,
              onPressMoreButton: widget.onPressMoreButton,
              onTapUserProfile: widget.onTapUserProfile,
              onTapShare: widget.onTapShare,
              onTapComment: widget.onTapComment,
            ),
          ),
        ),
      );
}
