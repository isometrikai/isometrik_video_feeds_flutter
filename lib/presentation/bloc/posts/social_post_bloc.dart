import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'social_post_event.dart';
part 'social_post_state.dart';

/// Compares engagement snapshots for host-cache silent post-detail refresh.
bool _silentPostDetailSnapshotsEqual(
  (Map<String, Object?>, Map<String, Object?>) pair,
) {
  final a = pair.$1;
  final b = pair.$2;
  for (final k in a.keys) {
    if (a[k] != b[k]) return false;
  }
  for (final k in b.keys) {
    if (a[k] != b[k]) return false;
  }
  return true;
}

class SocialPostBloc extends Bloc<SocialPostEvent, SocialPostState> {
  SocialPostBloc(
      this._localDataUseCase,
      this._getTimelinePostUseCase,
      this._getTrendingPostUseCase,
      this._getForYouPostUseCase,
      this._followPostUseCase,
      this._savePostUseCase,
      this._likePostUseCase,
      this._reportPostUseCase,
      this._reportUseCase,
      this._getReportReasonsUseCase,
      this._getPostDetailsUseCase,
      this._getPostInsightUseCase,
      this._getPostCommentUseCase,
      this._commentUseCase,
      this._getSocialProductsUseCase,
      this._getMentionedUsersUseCase,
      this._removeMentionUseCase,
      this._getTaggedPostsUseCase,
      this._getUserPostDataUseCase,
      this._deletePostUseCase,
      this.postImpressionUseCase,
      this._onShareSuccessLogUseCase)
      : super(PostLoadingState(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<LoadPostData>(_onLoadHomeData);
    on<LoadHomeTabEvent>(_onLoadHomeTab);
    on<GetTimeLinePostEvent>(_getTimeLinePost);
    on<GetTrendingPostEvent>(_getTrendingPost);
    on<SavePostEvent>(_savePost);
    on<GetReasonEvent>(_getReason);
    on<ReportPostEvent>(_reportPost);
    on<ReportEvent>(_report);
    on<LikePostEvent>(_likePost);
    on<FollowUserEvent>(_followUser);
    on<PurgeAuthorFromFollowFeedsEvent>(_purgeAuthorFromFollowFeeds);
    on<DeletePostEvent>(_deletePost);
    on<GetSocialProductsEvent>(_getSocialProducts);
    on<GetPostCommentsEvent>(_getPostComments);
    on<GetPostCommentReplyEvent>(_getPostCommentReplies);
    on<CommentActionEvent>(_doActionOnComment);
    on<LoadPostsEvent>(_loadPosts);
    on<GetMorePostEvent>(_getMorePost);
    on<GetPostInsightDetailsEvent>(_getPostInsightDetails);
    on<GetMentionedUserEvent>(_getMentionedUser);
    on<RemoveMentionEvent>(_removeMention);
    on<PlayPauseVideoEvent>(_playPauseVideo);
    on<OnShareSuccessEvent>(_onShareSuccess);
  }

  final IsmLocalDataUseCase _localDataUseCase;
  final GetTimelinePostUseCase _getTimelinePostUseCase;
  final GetTrendingPostUseCase _getTrendingPostUseCase;
  final GetForYouPostUseCase _getForYouPostUseCase;
  final FollowUnFollowUserUseCase _followPostUseCase;
  final DeletePostUseCase _deletePostUseCase;
  final SavePostUseCase _savePostUseCase;
  final LikePostUseCase _likePostUseCase;
  final ReportPostUseCase _reportPostUseCase;
  final ReportUseCase _reportUseCase;
  final GetReportReasonsUseCase _getReportReasonsUseCase;
  final GetPostDetailsUseCase _getPostDetailsUseCase;
  final GetPostInsightUseCase _getPostInsightUseCase;
  final GetPostCommentUseCase _getPostCommentUseCase;
  final CommentActionUseCase _commentUseCase;
  final GetSocialProductsUseCase _getSocialProductsUseCase;
  final GetMentionedUsersUseCase _getMentionedUsersUseCase;
  final RemoveMentionUseCase _removeMentionUseCase;
  final OnShareSuccessLogUseCase _onShareSuccessLogUseCase;
  final GetTaggedPostsUseCase _getTaggedPostsUseCase;
  final GetUserPostDataUseCase _getUserPostDataUseCase;
  final PostImpressionUseCase postImpressionUseCase;

  IsmSocialActionCubit get _socialActionCubit => IsmInjectionUtils.getBloc();

  var reelsPageTrendingController = PageController();
  TextEditingController? descriptionController;

  final _postsByTab = <PostTabAssistData>[];
  final Set<PostSectionType> _homeTabLoadInFlight = {};

  PostTabAssistData _getTabAssistData(PostSectionType tab) => _postsByTab
          .toList()
          .firstWhere((_) => _.postSectionType == tab, orElse: () {
        final tabAssist = PostTabAssistData(postSectionType: tab, postList: []);
        _postsByTab.add(tabAssist);
        return tabAssist;
      });

  bool hasMorePagesForTab(PostSectionType tab) =>
      _getTabAssistData(tab).hasMorePages;

  bool hasTabAssistData(PostSectionType tab) =>
      _postsByTab.any((t) => t.postSectionType == tab);

  bool get _sdkFollowCacheOn =>
      IsrVideoReelConfig.feedCacheConfig != null &&
      IsrFeedCacheRepository.instance.isEnabled;

  bool _useMergeForTab(
    PostSectionType type, {
    required bool isFromRefresh,
    required bool mergeWithExisting,
    required bool feedHostCacheOn,
  }) {
    if (!feedHostCacheOn || isrFollowSensitivePostSection(type)) {
      return false;
    }
    return mergeWithExisting || isFromRefresh;
  }

  String? _timelineAuthorId(TimeLineData post) {
    final fromUser = post.user?.id;
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    final userId = post.userId;
    if (userId != null && userId.isNotEmpty) return userId;
    return null;
  }

  Future<void> _seedFollowSensitiveTabFromCache(PostTabAssistData postTab) async {
    if (!_sdkFollowCacheOn || postTab.postList.isNotEmpty) return;
    final section =
        IsrFeedCacheSectionMapping.fromPostSectionType(postTab.postSectionType);
    if (section == null) return;
    await IsrFeedCacheRepository.instance.ensureInitialized();
    if (IsrFeedCacheRepository.instance.isSectionExpired(section)) return;
    for (final map in IsrFeedCacheRepository.instance.getPosts(section)) {
      try {
        final post = TimeLineData.fromMap(map);
        if (!TimelinePostTypeUtil.shouldShowTextPosts(postTab.postSectionType) &&
            TimelinePostTypeUtil.isTextPost(post)) {
          continue;
        }
        postTab.postList.add(post);
      } catch (_) {}
    }
    final meta = IsrFeedCacheRepository.instance.getMeta(section);
    if (meta != null) {
      final cachedPage = meta.currentPage;
      if (cachedPage != null && cachedPage > 0) {
        postTab.currentPage = cachedPage;
      }
      postTab.hasMorePages = meta.hasMore;
    }
  }

  Future<void> _persistFollowSensitiveTabToCache(
    PostSectionType postSectionType,
    List<TimeLineData> posts, {
    required bool isFromPagination,
    required bool hasMore,
    required int currentPage,
  }) async {
    if (!_sdkFollowCacheOn || !isrFollowSensitivePostSection(postSectionType)) {
      return;
    }
    final section = IsrFeedCacheSectionMapping.fromPostSectionType(postSectionType);
    if (section == null) return;
    if (posts.isEmpty) {
      if (isFromPagination) return;
      await IsrFeedCacheRepository.instance.replaceSection(
        section,
        const [],
        hasMore: hasMore,
        currentPage: currentPage,
      );
      return;
    }
    final maps = posts.map((e) => e.toMap()).toList();
    if (isFromPagination) {
      await IsrFeedCacheRepository.instance.appendSection(
        section,
        maps,
        hasMore: hasMore,
        currentPage: currentPage,
      );
    } else {
      await IsrFeedCacheRepository.instance.replaceSection(
        section,
        maps,
        hasMore: hasMore,
        currentPage: currentPage,
      );
    }
  }

  void _purgeAuthorFromFollowSensitiveTabs(String authorUserId) {
    if (authorUserId.isEmpty) return;
    for (final type in [
      PostSectionType.following,
      PostSectionType.feeds,
    ]) {
      final tab =
          _postsByTab.where((t) => t.postSectionType == type).firstOrNull;
      if (tab == null) continue;
      tab.postList.removeWhere((p) => _timelineAuthorId(p) == authorUserId);
    }
  }

  void _syncPageBasedHasMore({
    required PostTabAssistData tabAssistData,
    required List<TimeLineData> pageItems,
    required int fetchedPage,
    num? total,
    num? totalPages,
  }) {
    if (pageItems.isEmpty) {
      tabAssistData.hasMorePages = false;
      return;
    }

    final totalPagesInt = totalPages?.toInt() ?? 0;
    final totalInt = total?.toInt() ?? 0;
    final pageSize = tabAssistData.pageSize;

    // Prefer grand-total when provided — many APIs return total_pages=1 even when
    // total=64; checking total_pages first incorrectly stops after page 1.
    if (totalInt > pageSize) {
      tabAssistData.hasMorePages = tabAssistData.postList.length < totalInt;
      return;
    }
    // Use the page we requested — timeline APIs often echo page=1 on every response.
    if (totalPagesInt > 0) {
      tabAssistData.hasMorePages = fetchedPage < totalPagesInt;
      return;
    }
    tabAssistData.hasMorePages = pageItems.length >= pageSize;
  }

  int currentPage = 0;
  final followingPageSize = 20;

  var _isDataLoading = false;
  var _detailsCurrentPage = 1;
  var _commentPage = 1;
  static const int _mentionedUsersPageLimit = 20;

  final List<ProductDataModel> _detailsProductList = [];

  // Timer for periodic in-review comment updates
  Timer? _inReviewUpdateTimer;

  // Map to track posts with in-review comments: postId -> current comment list
  final Map<String, List<CommentDataItem>> _postsWithInReviewComments = {};

  /// Dedupes background `GET /api/v1/posts/detail` for the same post (host
  /// cache can otherwise re-trigger refresh every rebuild / poll).
  final Set<String> _postDetailRefreshInFlight = {};
  final Map<String, DateTime> _lastPostDetailRefreshAt = {};
  static const Duration _minPostDetailRefreshGap = Duration(minutes: 2);

  void _onStartPost(StartPost event, Emitter<SocialPostState> emit) async {}

  Future<String> get userId => _localDataUseCase.getUserId();
  Future<bool> get isUserLoggedIn => _localDataUseCase.isLoggedIn();

  Future<void> _onLoadHomeData(
    LoadPostData event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      _postsByTab.clear();
      _postsByTab.addAll(event.postSections);
      _homeTabLoadInFlight.clear();

      final tabList = _postsByTab.toList();
      if (event.startTabIndex > 0 && event.startTabIndex < tabList.length) {
        final startTab = tabList.removeAt(event.startTabIndex);
        tabList.insert(0, startTab);
      }

      if (_sdkFollowCacheOn) {
        await IsrFeedCacheRepository.instance.ensureInitialized();
      }

      // One event per tab so Following/Feeds are not blocked behind For You.
      for (final postTab in tabList) {
        add(LoadHomeTabEvent(postSectionType: postTab.postSectionType));
      }
    } catch (error) {
      emit(SocialPostError(error.toString()));
    }
  }

  Future<void> _onLoadHomeTab(
    LoadHomeTabEvent event,
    Emitter<SocialPostState> emit,
  ) async {
    if (_homeTabLoadInFlight.contains(event.postSectionType)) return;
    _homeTabLoadInFlight.add(event.postSectionType);

    final postTab = _getTabAssistData(event.postSectionType);
    try {
      final isUserLoggedIn = await this.isUserLoggedIn;
      final useFeedHostCache = IsrVideoReelConfig.feedCacheConfig != null;

      if (!useFeedHostCache) {
        emit(PostLoadingState(
            isLoading: true, postType: postTab.postSectionType));
        if (postTab.postList.isEmpty) {
          if (postTab.postId?.trim().isNotEmpty == true) {
            final postIdData = await _getPostDetails(postTab.postId ?? '');
            if (postIdData != null) {
              postTab.postList.add(postIdData);
              await _emitLoadedPosts(
                emit,
                postTab.postSectionType,
                postTab.postList,
              );
            }
          }
          if (!postTab.postSectionType.isUserDependent || isUserLoggedIn) {
            await _callGetTabPost(postTab, false, false, false, null);
          }
        }
      } else {
        if (postTab.postList.isEmpty) {
          await _seedFollowSensitiveTabFromCache(postTab);
        }
        final hasSeededList = postTab.postList.isNotEmpty;
        if (hasSeededList) {
          unawaited(FeedMediaOrientation.prefetchForPosts(postTab.postList));
          await _emitLoadedPosts(
            emit,
            postTab.postSectionType,
            postTab.postList,
          );
          _socialActionCubit.updatePostList(postTab.postList);
        } else {
          emit(PostLoadingState(
              isLoading: true, postType: postTab.postSectionType));
        }
        if (postTab.postList.isEmpty &&
            postTab.postId?.trim().isNotEmpty == true) {
          final postIdData = await _getPostDetails(postTab.postId ?? '');
          if (postIdData != null) {
            postTab.postList.add(postIdData);
            await _emitLoadedPosts(
              emit,
              postTab.postSectionType,
              postTab.postList,
            );
          }
        }
        if (!postTab.postSectionType.isUserDependent || isUserLoggedIn) {
          await _callGetTabPost(
            postTab,
            false,
            false,
            false,
            null,
            mergeWithExisting: hasSeededList,
          );
        }
      }

      await _emitLoadedPosts(
        emit,
        postTab.postSectionType,
        postTab.postList,
      );
      _socialActionCubit.updatePostList(postTab.postList);
    } catch (error) {
      await _emitLoadedPosts(
        emit,
        postTab.postSectionType,
        postTab.postList,
      );
      emit(SocialPostError(error.toString()));
    } finally {
      _homeTabLoadInFlight.remove(event.postSectionType);
    }
  }

  FutureOr<void> _getMorePost(
      GetMorePostEvent event, Emitter<SocialPostState> emit) async {
    final tab = _getTabAssistData(event.postSectionType);
    await _callGetTabPost(
      tab,
      event.isRefresh,
      event.isPagination,
      event.isLoading,
      event.onComplete,
    );
    if (event.onComplete == null) {
      await _emitLoadedPosts(emit, event.postSectionType, tab.postList);
      _socialActionCubit.updatePostList(tab.postList);
    }
  }

  FutureOr<void> _getTimeLinePost(
      GetTimeLinePostEvent event, Emitter<SocialPostState> emit) async {
    await _callGetTabPost(_getTabAssistData(PostSectionType.trending),
        event.isRefresh, event.isPagination, event.isLoading, event.onComplete);
  }

  FutureOr<void> _getTrendingPost(
      GetTrendingPostEvent event, Emitter<SocialPostState> emit) async {
    await _callGetTabPost(_getTabAssistData(PostSectionType.trending),
        event.isRefresh, event.isPagination, event.isLoading, event.onComplete);
  }

  Future<void> _callGetTabPost(
    PostTabAssistData postTabAssistData,
    bool isFromRefresh,
    bool isFromPagination,
    bool isLoading,
    Function(List<TimeLineData>)? onComplete, {
    bool mergeWithExisting = false,
  }) async {
    final postSectionType = postTabAssistData.postSectionType;
    final tabAssistData = _getTabAssistData(postSectionType);
    final requestedPage = tabAssistData.currentPage;
    final feedHostCacheOn = IsrVideoReelConfig.feedCacheConfig != null;
    // Following/Feeds always replace on refresh (unfollow-safe). Other tabs may merge.
    final mergeEnabled = _useMergeForTab(
      postSectionType,
      isFromRefresh: isFromRefresh,
      mergeWithExisting: mergeWithExisting,
      feedHostCacheOn: feedHostCacheOn,
    );
    final followSensitive = isrFollowSensitivePostSection(postSectionType);

    // For refresh, clear cache and start from page 1. With host-cache enabled,
    // keep the existing list visible and merge new items at the top instead
    // (pull-to-refresh becomes "fetch fresh, prepend new").
    if (isFromRefresh) {
      if (!feedHostCacheOn || followSensitive) {
        tabAssistData.postList.clear();
      }
      tabAssistData.currentPage = 1;
      tabAssistData.hasMorePages = true;
      tabAssistData.isLoadingMore = false;
      tabAssistData.cursor = null;
    } else if (!isFromPagination && tabAssistData.postList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    }

    if (!isFromPagination) {
      tabAssistData.currentPage = 1;
      tabAssistData.cursor = null;
    } else if (tabAssistData.isLoadingMore) {
      // Pagination while the first page is still loading must not hand back the
      // full list — callers de-dupe against it and treat the page as empty,
      // which sticks hasMore=false until the user switches tabs (layout retry).
      if (onComplete != null) {
        onComplete(isFromPagination
            ? const <TimeLineData>[]
            : List<TimeLineData>.from(tabAssistData.postList));
      }
      return;
    }

    tabAssistData.isLoadingMore = true;

    TimeLineData? postIdPostData;
    debugPrint(
        'social_post_bloc => postIdPostData cond: ${postTabAssistData.postId?.trim().isNotEmpty == true && postTabAssistData.postList.isEmpty}');
    if (postTabAssistData.postId?.trim().isNotEmpty == true &&
        postTabAssistData.postList.isEmpty) {
      postIdPostData = await _getPostDetails(postTabAssistData.postId ?? '',
          onSuccess: postTabAssistData.postList.add);
      debugPrint('social_post_bloc => postIdPostData: ${postIdPostData?.id}');
    } else if (postTabAssistData.postId?.trim().isNotEmpty == true) {
      postIdPostData = postTabAssistData.postList
          .where((e) => e.id == postTabAssistData.postId)
          .firstOrNull;
      // Seeded cache may satisfy postId from disk; still merge fresh engagement
      // from detail API without blocking the timeline request.
      if (feedHostCacheOn && postIdPostData != null) {
        unawaited(_refreshPostFromDetailForHostCache(
            postTabAssistData.postId!.trim()));
      }
    }

    // Route to the correct use case based on PostSectionType
    List<TimeLineData>? apiPostResult;
    AppError? apiError;
    TimelineResponse? timelineResponse;
    switch (postSectionType) {
      case PostSectionType.trending:
        apiPostResult = await _getTrendingPostUseCase
            .executeGetTrendingPost(
          isLoading: isLoading,
          cursor: tabAssistData.cursor,
          limit: tabAssistData.pageSize,
        )
            .then((result) {
          apiError = result.error;
          if (result.data?.data?.nextCursor?.isNotEmpty == true) {
            tabAssistData.cursor = result.data?.data?.nextCursor;
          }
          return result.data?.data?.posts;
        });
        break;
      case PostSectionType.forYou:
        apiPostResult = await _getForYouPostUseCase
            .executeGetForYouPost(
          isLoading: isLoading,
          cursor: tabAssistData.cursor,
          limit: tabAssistData.pageSize,
        )
            .then((result) {
          apiError = result.error;
          tabAssistData.cursor = result.data?.data?.nextCursor;
          return result.data?.data?.posts;
        });
        break;
      case PostSectionType.following:
        final timelineResult = await _getTimelinePostUseCase.executeTimeLinePost(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
          postTypes: TimelinePostTypeUtil.followingPostTypes,
        );
        apiError = timelineResult.error;
        timelineResponse = timelineResult.data;
        apiPostResult = timelineResponse?.data;
        break;
      case PostSectionType.feeds:
        final timelineResult = await _getTimelinePostUseCase.executeTimeLinePost(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
          postTypes: TimelinePostTypeUtil.feedPostTypes,
        );
        apiError = timelineResult.error;
        timelineResponse = timelineResult.data;
        apiPostResult = timelineResponse?.data;
        break;
      case PostSectionType.savedPost:
        apiPostResult = await _savePostUseCase
            .executeGetProfileSavedPostData(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageSize: tabAssistData.pageSize,
        )
            .then((result) {
          apiError = result.error;
          return result.data?.data;
        });
        break;
      case PostSectionType.tagPost:
        if (tabAssistData.tagType != null && tabAssistData.tagValue != null) {
          apiPostResult = await _getTaggedPostsUseCase
              .executeGetTaggedPosts(
            isLoading: isLoading,
            page: tabAssistData.currentPage,
            pageLimit: tabAssistData.pageSize,
            tagValue: tabAssistData.tagValue!,
            tagType: tabAssistData.tagType!,
          )
              .then((result) {
            apiError = result.error;
            return result.data?.data;
          });
        }
        break;
      case PostSectionType.myTaggedPost:
        apiPostResult = await _getTaggedPostsUseCase
            .executeGetTaggedPosts(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
          tagValue: await _localDataUseCase.getUserId(),
          tagType: TagType.mention,
        )
            .then((result) {
          apiError = result.error;
          return result.data?.data;
        });
        break;
      case PostSectionType.myPost:
        apiPostResult = await _getUserPostDataUseCase
            .executeGetUserProfilePostData(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageSize: tabAssistData.pageSize,
          memberId: tabAssistData.userId ?? await _localDataUseCase.getUserId(),
        )
            .then((result) {
          apiError = result.error;
          return result.data?.data;
        });
        break;
      case PostSectionType.otherUserPost:
        if (tabAssistData.userId != null) {
          apiPostResult = await _getUserPostDataUseCase
              .executeGetUserProfilePostData(
            isLoading: isLoading,
            page: tabAssistData.currentPage,
            pageSize: tabAssistData.pageSize,
            memberId: tabAssistData.userId!,
          )
              .then((result) {
            apiError = result.error;
            return result.data?.data;
          });
        }
        break;
      default:
        break;
    }
    var postDataList = <TimeLineData>[];
    if (postIdPostData != null) {
      postDataList.add(postIdPostData);
    }
    if (tabAssistData.postSectionType == PostSectionType.following ||
        tabAssistData.postSectionType == PostSectionType.feeds) {
      apiPostResult?.forEach((_) => _.isFollowing = true);
    }
    postDataList.addAll(apiPostResult ?? []);
    if (!TimelinePostTypeUtil.shouldShowTextPosts(tabAssistData.postSectionType)) {
      postDataList = TimelinePostTypeUtil.withoutTextPosts(postDataList);
    }
    final apiSucceeded = apiError == null;

    if (followSensitive && !isFromPagination && apiSucceeded) {
      tabAssistData.postList
        ..clear()
        ..addAll(postDataList);
      if (postDataList.isNotEmpty) {
        _socialActionCubit.updatePostList(postDataList);
        tabAssistData.currentPage++;
        _syncPageBasedHasMore(
          tabAssistData: tabAssistData,
          pageItems: postDataList,
          fetchedPage: requestedPage,
          total: timelineResponse?.total,
          totalPages: timelineResponse?.totalPages,
        );
        unawaited(FeedMediaOrientation.prefetchForPosts(postDataList));
      } else {
        tabAssistData.hasMorePages = false;
        tabAssistData.currentPage = 1;
      }
      unawaited(
        _persistFollowSensitiveTabToCache(
          postSectionType,
          tabAssistData.postList,
          isFromPagination: false,
          hasMore: tabAssistData.hasMorePages,
          currentPage: tabAssistData.currentPage,
        ),
      );
    } else if (postDataList.isNotEmpty) {
      _socialActionCubit.updatePostList(postDataList);

      if (isFromPagination) {
        if (feedHostCacheOn) {
          // De-dupe by post id so cached/seeded rows don't reappear when the
          // server overlaps the next page with items we already display.
          final existingIds = tabAssistData.postList
              .map((p) => p.id)
              .where((id) => id != null && id.isNotEmpty)
              .toSet();
          final paginationOnly = postDataList
              .where((p) =>
                  p.id == null || p.id!.isEmpty || !existingIds.contains(p.id))
              .toList();
          tabAssistData.postList.addAll(paginationOnly);
        } else {
          tabAssistData.postList.addAll(postDataList);
        }
      } else if (mergeEnabled && tabAssistData.postList.isNotEmpty) {
        // Prepend only the API items we haven't already cached. This keeps
        // the existing seeded list visible and inserts "new posts" at the
        // top, instead of wiping cache with the first API page.
        final existingIds = tabAssistData.postList
            .map((p) => p.id)
            .where((id) => id != null && id.isNotEmpty)
            .toSet();
        final newOnly = postDataList
            .where((p) =>
                p.id != null && p.id!.isNotEmpty && !existingIds.contains(p.id))
            .toList();
        if (newOnly.isNotEmpty) {
          tabAssistData.postList.insertAll(0, newOnly);
        }
      } else {
        tabAssistData.postList
          ..clear()
          ..addAll(postDataList);
      }
      tabAssistData.currentPage++;
      if (postSectionType == PostSectionType.following ||
          postSectionType == PostSectionType.feeds) {
        _syncPageBasedHasMore(
          tabAssistData: tabAssistData,
          pageItems: postDataList,
          fetchedPage: requestedPage,
          total: timelineResponse?.total,
          totalPages: timelineResponse?.totalPages,
        );
      }
      unawaited(FeedMediaOrientation.prefetchForPosts(postDataList));

      if (followSensitive) {
        unawaited(
          _persistFollowSensitiveTabToCache(
            postSectionType,
            isFromPagination ? postDataList : tabAssistData.postList,
            isFromPagination: isFromPagination,
            hasMore: tabAssistData.hasMorePages,
            currentPage: tabAssistData.currentPage,
          ),
        );
      }
    } else {
      tabAssistData.hasMorePages = false;
      if (!mergeEnabled) {
        tabAssistData.cursor = null;
        if (apiError != null) {
          ErrorHandler.showAppError(
              appError: apiError, errorViewType: ErrorViewType.snackBar);
        }
      }
    }

    if (onComplete != null) {
      // When merging (host-cache enabled refresh or seeded mount), hand the
      // caller the FULL merged list so refresh UIs that do
      // `reelsDataList..clear()..addAll(result)` don't wipe cached items when
      // the API page is empty or fully overlaps the cache.
      final handFullList = mergeEnabled ||
          (followSensitive && !isFromPagination);
      onComplete(handFullList
          ? List<TimeLineData>.from(tabAssistData.postList)
          : postDataList);
    }

    tabAssistData.isLoadingMore = false;
  }

  FutureOr<void> _savePost(
      SavePostEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _savePostUseCase.executeSavePost(
      isLoading: false,
      postId: event.postId,
      socialPostAction:
          event.isSaved ? SocialPostAction.unSave : SocialPostAction.save,
    );

    if (apiResult.isSuccess) {
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }

  FutureOr<void> _getReason(
      GetReasonEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _getReportReasonsUseCase.executeGetReportReasons(
        isLoading: false, reasonFor: event.reasonsFor);

    if (apiResult.isSuccess) {
      event.onComplete.call(apiResult.data);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call([]);
    }
  }

  FutureOr<void> _reportPost(
      ReportPostEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _reportPostUseCase.executeReportPost(
      isLoading: false,
      postId: event.postId,
      message: event.message,
      reason: event.reason,
    );

    if (apiResult.isSuccess) {
      event.onComplete.call(true, event.reason);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false, event.reason);
    }
  }

  FutureOr<void> _report(
      ReportEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _reportUseCase.executeReport(
        isLoading: false,
        reportRequest: ReportRequest(
          contentId: event.contentId,
          additionalDetails: event.reportReason.description,
          reasonId: event.reportReason.id,
          type: event.reportReason.type,
          reason: event.reportReason.name,
        ));

    if (apiResult.isSuccess) {
      event.onComplete.call(true);
      if (event.showToastOnSuccess) {
        Utility.showToastMessage(IsrTranslationFile.reportedSuccessfully(
                event.reportReason.type ?? '')
            .trim());
      }
    } else {
      ErrorHandler.showAppError(
          appError: apiResult.error, isNeedToShowError: true);
      event.onComplete.call(false);
    }
  }

  FutureOr<void> _likePost(
      LikePostEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _likePostUseCase.executeLikePost(
      isLoading: false,
      postId: event.postId,
      likeAction: event.likeAction,
    );

    if (apiResult.isSuccess) {
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }

  FutureOr<void> _deletePost(
      DeletePostEvent event, Emitter<SocialPostState> emit) async {
    final userId = await _localDataUseCase.getUserId();
    if (userId.isEmptyOrNull) {
      event.onComplete(false);
      return;
    }
    final apiResult = await _deletePostUseCase.executeDeletePost(
      isLoading: false,
      postId: event.postId,
    );
    event.onComplete(apiResult.isSuccess);
    if (apiResult.isSuccess) {
      _socialActionCubit.onPostDeleted(postId: event.postId);
    }
  }

  FutureOr<void> _followUser(
      FollowUserEvent event, Emitter<SocialPostState> emit) async {
    // final myUserId = await _localDataUseCase.getUserId();
    final apiResult = await _followPostUseCase.executeFollowUser(
      isLoading: false,
      followingId: event.followingId,
      followAction: event.followAction,
    );

    if (apiResult.isSuccess) {
      event.onComplete.call(true);
      if (event.followAction == FollowAction.unfollow) {
        _purgeAuthorFromFollowSensitiveTabs(event.followingId);
        unawaited(
          IsrFeedCacheRepository.instance
              .removePostsByAuthor(event.followingId),
        );
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
    if (apiResult.isSuccess) {
      await _refreshFollowSensitiveTabsAfterFollowChange();
    }
  }

  Future<void> _refreshFollowSensitiveTabsAfterFollowChange() async {
    for (final type in [
      PostSectionType.following,
      PostSectionType.feeds,
    ]) {
      if (!_postsByTab.any((t) => t.postSectionType == type)) continue;
      final tab = _getTabAssistData(type);
      await _callGetTabPost(tab, true, false, false, null);
      add(LoadPostsEvent(postType: type, postList: tab.postList));
      _socialActionCubit.updatePostList(tab.postList);
    }
  }

  FutureOr<void> _purgeAuthorFromFollowFeeds(
    PurgeAuthorFromFollowFeedsEvent event,
    Emitter<SocialPostState> emit,
  ) async {
    if (event.userId.isEmpty) return;
    _purgeAuthorFromFollowSensitiveTabs(event.userId);
    for (final type in [
      PostSectionType.following,
      PostSectionType.feeds,
    ]) {
      if (!_postsByTab.any((t) => t.postSectionType == type)) continue;
      final tab = _getTabAssistData(type);
      add(LoadPostsEvent(postType: type, postList: tab.postList));
      _socialActionCubit.updatePostList(tab.postList);
    }
    await _refreshFollowSensitiveTabsAfterFollowChange();
  }

  FutureOr<void> _getSocialProducts(
      GetSocialProductsEvent event, Emitter<SocialPostState> emit) async {
    var totalProductCount = 0;
    if (_isDataLoading) return;
    _isDataLoading = true;
    if (event.isFromPagination == false) {
      _detailsCurrentPage = 1;
      _detailsProductList.clear();
      emit(SocialProductsLoading());
    } else {
      _detailsCurrentPage++;
    }
    final apiResult = await _getSocialProductsUseCase.executeGetSocialProducts(
      isLoading: false,
      postId: event.postId,
      productIds: event.productIds,
      page: _detailsCurrentPage,
      limit: 20,
    );
    if (apiResult.isSuccess) {
      totalProductCount = apiResult.data?.count?.toInt() ?? 0;
      _detailsProductList
          .addAll(apiResult.data?.data as Iterable<ProductDataModel>);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }
    emit(SocialProductsLoaded(
        productList: _detailsProductList,
        totalProductCount: totalProductCount));
    _isDataLoading = false;
  }

  FutureOr<void> _getPostComments(
      GetPostCommentsEvent event, Emitter<SocialPostState> emit) async {
    if (event.isLoading == true) {
      emit(LoadingPostComment(postId: event.postId));
    }
    _commentPage = event.isPagination ? _commentPage + 1 : 1;
    // Do not pass [event.isLoading] to the network layer: Utility.showLoader /
    // closeProgressDialog use the root navigator and will pop the comments
    // bottom sheet when the fetch completes (same pattern as comment replies).
    final apiResult = await _getPostCommentUseCase.executeGetPostComment(
      postId: event.postId,
      isLoading: false,
      page: _commentPage,
      pageLimit: 20,
    );
    if (apiResult.isError) {
      _maybeNotifyPostDeleted(
        postId: event.postId,
        statusCode: apiResult.error?.statusCode ?? apiResult.statusCode,
        errorMessage: apiResult.error?.message,
      );
    }
    final postCommentsList = apiResult.data?.data;

    if (event.createdComment != null &&
        event.createdComment?.comment?.isNotEmpty == true &&
        event.createdComment?.parentCommentId?.isNotEmpty != true) {
      final created = event.createdComment!;
      final alreadyExists = postCommentsList?.firstOrNull?.comment ==
          event.createdComment?.comment;

      if (!alreadyExists) {
        // Insert at the beginning only if it doesn't already exist
        postCommentsList?.insert(0, created);
      }
    }

    // Merge API response with existing in-review comments
    final existingComments = _postsWithInReviewComments[event.postId];
    var finalCommentList = postCommentsList;

    if (existingComments != null && postCommentsList != null) {
      // Merge API response into existing comments (updates in-review comments)
      _mergeCommentsWithInReview(existingComments, postCommentsList);
      // Use the merged existing comments list
      finalCommentList = existingComments;
      // Update stored list
      _postsWithInReviewComments[event.postId] = existingComments;
    } else if (postCommentsList != null) {
      // If no existing comments, check if there are in-review comments in API response
      // and store them for future updates
      if (_hasInReviewComments(postCommentsList)) {
        _postsWithInReviewComments[event.postId] = List.from(postCommentsList);
      }
    }

    final myUserId = await _localDataUseCase.getUserId();
    final totalComments = apiResult.data?.totalComments?.toInt() ?? 0;
    if (event.onComplete != null) {
      event.onComplete?.call(
        finalCommentList ?? [],
        total: totalComments,
      );
    } else {
      emit(LoadPostCommentState(
        postCommentsList: finalCommentList,
        postId: event.postId,
        myUserId: myUserId,
      ));
    }

    final feedHostCacheOn = IsrVideoReelConfig.feedCacheConfig != null;
    final shouldBackgroundRefreshPost = feedHostCacheOn &&
        apiResult.isSuccess &&
        !event.isPagination &&
        (event.isLoading == true ||
            event.createdComment != null ||
            event.refreshPostDetailAfterComments);
    if (shouldBackgroundRefreshPost) {
      unawaited(_refreshPostFromDetailForHostCache(event.postId));
    }
  }

  FutureOr<void> _getPostCommentReplies(
      GetPostCommentReplyEvent event, Emitter<SocialPostState> emit) async {
    if (event.isLoading == true) {
      emit(LoadingPostCommentReplies(
        parentCommentId: event.parentComment.id ?? '',
        postId: event.postId,
      ));
    }
    final apiResult = await _getPostCommentUseCase.executeGetPostComment(
      postId: event.postId,
      parentCommitId: event.parentComment.id,
      isLoading: false,
    );
    final postCommentRepliesList = apiResult.data?.data;

    // Merge API response with existing in-review reply comments
    final existingComments = _postsWithInReviewComments[event.postId];
    var finalRepliesList = postCommentRepliesList;

    if (existingComments != null && postCommentRepliesList != null) {
      // Find the parent comment in existing comments
      final parentComment =
          _findCommentById(existingComments, event.parentComment.id ?? '');
      if (parentComment != null && parentComment.childComments != null) {
        // Merge API response with existing in-review reply comments
        _mergeCommentsWithInReview(
            parentComment.childComments!, postCommentRepliesList);
        // Use the merged existing child comments list
        finalRepliesList = parentComment.childComments;
        // Update stored list
        _postsWithInReviewComments[event.postId] = existingComments;
      }
    }

    final myUserId = await _localDataUseCase.getUserId();
    emit(LoadPostCommentRepliesState(
      postCommentRepliesList: finalRepliesList,
      parentCommentId: event.parentComment.id ?? '',
      postId: event.postId,
      myUserId: myUserId,
    ));
  }

  Future<void> _doActionOnComment(
      CommentActionEvent event, Emitter<SocialPostState> emit) async {
    // Route comment creation to separate method
    if (event.commentAction == CommentAction.comment) {
      await _createComment(event, emit);
      return;
    }

    // Handle other comment actions (report, delete, etc.)
    final commentRequest = CommentRequest(
            commentId: event.commentId,
            commentAction: event.commentAction,
            postId: event.postId,
            userType: null,
            comment: event.replyText,
            postedBy: event.postedBy,
            parentCommentId: event.parentCommentId,
            reason: event.reportReason,
            message: event.commentMessage,
            commentIds: event.commentIds,
            tags: event.commentTags)
        .also((_) => debugPrint('comment: comment req tag: ${_.toJson()}'));

    final apiResult = await _commentUseCase.executeCommentAction(
      isLoading: event.isLoading == true,
      commentRequest: commentRequest.toJson(),
    );

    if (apiResult.isSuccess) {
      if (event.commentAction == CommentAction.report) {
        Utility.showToastMessage(
            IsrTranslationFile.commentReportedSuccessfully);
      } else if (event.commentAction == CommentAction.delete &&
          event.commentId?.trim().isNotEmpty == true) {
        if (_isTopLevelCommentAction(event)) {
          emit(CommentCountModified(postId: event.postId, modifiedValue: -1));
          _socialActionCubit.bumpCommentCount(
            event.postId,
            -1,
            postData: event.postDataModel,
          );
        }
        final myUserId = await _localDataUseCase.getUserId();
        final commentList = event.postCommentList?.toList() ?? [];
        if (event.parentCommentId?.trim().isNotEmpty == true) {
          debugPrint(
              'Social_bloc: commetIds => {${commentList.map((e) => e.id).toList()}}');
          final parentComment = commentList
              .where((comment) => comment.id == event.parentCommentId)
              .firstOrNull;
          parentComment?.childComments
              ?.removeWhere((comment) => comment.id == event.commentId);
          parentComment?.childCommentCount =
              (parentComment.childCommentCount ?? 1) - 1;
          if (parentComment?.childComments?.isEmpty == true) {
            parentComment?.showReply = false;
          }
        } else {
          commentList.removeWhere((comment) => comment.id == event.commentId);
        }
        emit(
          LoadPostCommentState(
            postCommentsList: commentList,
            postId: event.postId,
            myUserId: myUserId,
          ),
        );
      }
    } else {
      ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: apiResult.statusCode == 500,
          errorViewType: ErrorViewType.dialog);
    }
    if (event.onComplete != null) {
      event.onComplete?.call(event.commentId ?? '', apiResult.isSuccess);
    }
  }

  Future<void> _createComment(
      CommentActionEvent event, Emitter<SocialPostState> emit) async {
    final commentRequest = CommentRequest(
            commentId: event.commentId,
            commentAction: event.commentAction,
            postId: event.postId,
            userType: 1,
            comment: event.replyText,
            postedBy: event.postedBy,
            parentCommentId: event.parentCommentId,
            reason: event.reportReason,
            message: event.commentMessage,
            commentIds: event.commentIds,
            tags: event.commentTags)
        .also((_) => debugPrint('comment: comment req tag: ${_.toJson()}'));

    final myUserId = await _localDataUseCase.getUserId();
    final commentList = event.postCommentList?.toList();

    // Create optimistic comment
    final comment = CommentDataItem(
      commentedBy: await _localDataUseCase.getUserName(),
      fullName:
          '${await _localDataUseCase.getFirstName()} ${await _localDataUseCase.getLastName()}',
      comment: commentRequest.comment,
      postId: commentRequest.postId,
      commentedByUserId: myUserId,
      parentCommentId: commentRequest.parentCommentId,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      commentedOn: DateTime.now(),
      likeCount: 0,
      status: IsrTranslationFile.posting,
      tags: CommentTags.fromJson(commentRequest.tags ?? {}),
    );

    // Add comment to list optimistically
    if (commentList != null) {
      if (comment.parentCommentId != null &&
          comment.parentCommentId!.isNotEmpty) {
        // Find parent comment
        final parentComment = commentList.firstWhere(
          (element) => element.id == comment.parentCommentId,
          orElse: () => throw Exception('Parent comment not found'),
        );

        // Ensure childComments list exists
        parentComment.childComments ??= [];

        // Insert reply at the beginning
        parentComment.childComments!.insert(0, comment);
        parentComment.childCommentCount ??= 0;
        parentComment.childCommentCount = parentComment.childCommentCount! + 1;
        parentComment.showReply = true;
      } else {
        // Top-level comment → insert at the beginning
        commentList.insert(0, comment);
      }

      emit(
        LoadPostCommentState(
          postCommentsList: commentList,
          postId: event.postId,
          myUserId: myUserId,
        ),
      );

      if (_isTopLevelCommentAction(event)) {
        _socialActionCubit.bumpCommentCount(
          event.postId,
          1,
          postData: event.postDataModel,
        );
      }
    }

    // Call API to create comment
    final apiResult = await _commentUseCase.executeCommentAction(
      isLoading: event.isLoading == true,
      commentRequest: commentRequest.toJson(),
    );

    if (apiResult.isSuccess) {
      if (_isTopLevelCommentAction(event)) {
        emit(CommentCountModified(postId: event.postId, modifiedValue: 1));
      }
      _sendAnalyticsEvent(
          EventType.commentCreated.value,
          event.commentId ?? '',
          event.postId,
          event.userId ?? '',
          event.commentMessage ?? '',
          event.postDataModel,
          event.tabDataModel);

      // Update status to in_review
      comment.status = IsrTranslationFile.inReview;
      // Update commentedOn to track when it entered in_review (for 10-second timeout check)
      comment.commentedOn = DateTime.now();

      if (commentList != null) {
        // Store current comment list for this post to track in-review comments
        _postsWithInReviewComments[event.postId] = commentList;

        emit(
          LoadPostCommentState(
            postCommentsList: commentList,
            postId: event.postId,
            myUserId: myUserId,
          ),
        );
      }

      // Start periodic update if not already running
      _startInReviewUpdateTimer(event.postId);

      // Initial delay before first update
      Future.delayed(const Duration(seconds: 2), () {
        add(
          GetPostCommentsEvent(
              postId: event.postId, isLoading: false, createdComment: comment),
        );
      });
    } else {
      // Remove comment on failure
      if (commentList != null) {
        if (comment.parentCommentId != null &&
            comment.parentCommentId!.isNotEmpty) {
          final parentComment = commentList.firstWhere(
            (element) => element.id == comment.parentCommentId,
            orElse: () => throw Exception('Parent comment not found'),
          );
          parentComment.childComments?.removeWhere((c) => c == comment);
          parentComment.childCommentCount =
              (parentComment.childCommentCount ?? 1) - 1;
        } else {
          commentList.removeWhere((c) => c == comment);
        }

        emit(
          LoadPostCommentState(
            postCommentsList: commentList,
            postId: event.postId,
            myUserId: myUserId,
          ),
        );
      }

      if (_isTopLevelCommentAction(event)) {
        _socialActionCubit.bumpCommentCount(
          event.postId,
          -1,
          postData: event.postDataModel,
        );
      }

      ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: apiResult.statusCode == 500,
          errorViewType: ErrorViewType.dialog);
    }

    if (event.onComplete != null) {
      event.onComplete?.call(event.commentId ?? '', apiResult.isSuccess);
    }
  }

  FutureOr<void> _getMentionedUser(
      GetMentionedUserEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _getMentionedUsersUseCase.executeGetMentionedUser(
      isLoading: false,
      postId: event.postId,
      page: event.page,
      pageLimit: _mentionedUsersPageLimit,
    );

    final users = apiResult.data?.data ?? [];
    final totalPages = apiResult.data?.totalPages?.toInt() ?? 0;
    final currentPage = apiResult.data?.page?.toInt() ?? event.page;
    final hasMore = totalPages > 0
        ? currentPage < totalPages
        : users.length >= _mentionedUsersPageLimit;

    event.onComplete?.call(users, hasMore);

    if (apiResult.isError) {
      ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }
  }

  FutureOr<void> _playPauseVideo(
      PlayPauseVideoEvent event, Emitter<SocialPostState> emit) async {
    emit(
      PlayPauseVideoState(
        play: event.play,
        pausePlayback: event.pausePlayback,
        scopedPostSection: event.scopedPostSection,
      ),
    );
  }

  FutureOr<void> _onShareSuccess(
      OnShareSuccessEvent event, Emitter<SocialPostState> emit) async {
    if (await isUserLoggedIn) {
      debugPrint(
          'SocialPostBloc: _onShareSuccess:- invoked, request:- ${event.shareSuccessData.toJson()}');
      final res = await _onShareSuccessLogUseCase.executeOnShareSuccessLog(
          isLoading: false, request: event.shareSuccessData);
      debugPrint(
          'SocialPostBloc: _onShareSuccess:- API result, request:- ${res.data?.data}');
    }
  }

  FutureOr<void> _removeMention(
      RemoveMentionEvent event, Emitter<SocialPostState> emit) async {
    final userId = await _localDataUseCase.getUserId();
    if (userId.isEmptyOrNull) {
      event.onComplete?.call(false);
      return;
    }
    final apiResult = await _removeMentionUseCase.executeRemoveMention(
      isLoading: false,
      postId: event.postId,
    );
    event.onComplete?.call(apiResult.isSuccess);
    if (apiResult.isSuccess) {
      _socialActionCubit.onMentionRemoved(
        postId: event.postId,
        userId: userId,
      );
    } else if (apiResult.isError) {
      ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }
  }

  /// Emits [SocialPostLoadedState] immediately. Use inside [LoadPostData] instead
  /// of [add] + [LoadPostsEvent] so each tab can clear its shimmer without
  /// waiting for every other tab's network call to finish.
  Future<void> _emitLoadedPosts(
    Emitter<SocialPostState> emit,
    PostSectionType postType,
    List<TimeLineData> postList,
  ) async {
    final myUserId = await _localDataUseCase.getUserId();
    if (isClosed) return;
    emit(SocialPostLoadedState(
      postType: postType,
      postList: postList,
      userId: myUserId,
    ));
  }

  FutureOr<void> _loadPosts(
      LoadPostsEvent event, Emitter<SocialPostState> emit) async {
    await _emitLoadedPosts(emit, event.postType, event.postList);
  }

  FutureOr<void> _getPostInsightDetails(
    GetPostInsightDetailsEvent event,
    Emitter<SocialPostState> emit,
  ) async {
    emit(PostInsightDetailsLoading(
      postId: event.postId ?? '',
      postData: event.data,
    ));
    final postDataResult = (!event.callPostDetailsApi)
        ? null
        : await _getPostDetailsUseCase.executeGetPostDetails(
            isLoading: false,
            postId: event.postId ?? '',
          );
    final insightApiResult = await _getPostInsightUseCase.executeGetPostInsight(
      isLoading: false,
      postId: event.postId ?? '',
    );
    emit(PostInsightDetails(
      postId: event.postId ?? '',
      postData: postDataResult?.data ?? event.data,
      insightData: insightApiResult.data,
    ));
    if (insightApiResult.isError) {
      ErrorHandler.showAppError(
          appError: insightApiResult.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }
  }

  Future<TimeLineData?> _getPostDetails(
    String postId, {
    Function(TimeLineData data)? onSuccess,
    bool showError = true,
  }) async {
    final result = await _getPostDetailsUseCase.executeGetPostDetails(
      isLoading: false,
      postId: postId,
    );

    if (result.isSuccess && onSuccess != null) {
      result.data?.let(onSuccess);
    }

    if (result.data != null && result.data is TimeLineData) {
      final timeLineData = result.data as TimeLineData;
      _socialActionCubit.updatePostList([timeLineData]);
    }

    if (result.isError) {
      _maybeNotifyPostDeleted(
        postId: postId,
        statusCode: result.error?.statusCode ?? result.statusCode,
        errorMessage: result.error?.message,
      );
      if (showError) {
        ErrorHandler.showAppError(
            appError: result.error,
            isNeedToShowError: true,
            errorViewType: ErrorViewType.toast);
      }
    }

    return result.data;
  }

  bool _isTopLevelCommentAction(CommentActionEvent event) =>
      event.parentCommentId.isStringEmptyOrNull == true;

  /// Replaces [fresh] wherever it appears in tab post lists (bloc-owned copy).
  void _replacePostInTabLists(TimeLineData fresh) {
    final id = fresh.id;
    if (id == null || id.isEmpty) return;
    for (final tab in _postsByTab) {
      final i = tab.postList.indexWhere((p) => p.id == id);
      if (i != -1) {
        tab.postList[i] = fresh;
      }
    }
  }

  TimeLineData? _findTimelinePostForCompare(String postId) {
    for (final tab in _postsByTab) {
      for (final p in tab.postList) {
        if (p.id == postId) return p;
      }
    }
    return _socialActionCubit.getPostById(postId);
  }

  Map<String, Object?> _snapshotForSilentPostDetailCompare(TimeLineData d) {
    final em = d.engagementMetrics;
    final lt = em?.likeTypes;
    final s = d.settings;
    return {
      'comments': em?.comments,
      'views': em?.views,
      'shares': em?.shares,
      'saves': em?.saves,
      'watch_time': em?.watchTime,
      'like': lt?.like,
      'love': lt?.love,
      'haha': lt?.haha,
      'wow': lt?.wow,
      'sad': lt?.sad,
      'angry': lt?.angry,
      'isLiked': d.isLiked,
      'isSaved': d.isSaved,
      'isFollowing': d.isFollowing,
      'caption': d.caption,
      'status': d.status,
      'is_locked': d.isLocked,
      'lock_reason': d.lockReason,
      'settings_is_paid': s?.isPaid,
      'settings_price_amount': s?.priceAmount?.toString(),
      'settings_price_currency': s?.priceCurrency,
    };
  }

  /// Fire-and-forget: `GET /api/v1/posts/detail` then merge + notify so host
  /// cache / feed UI can pick up fresh engagement (e.g. comment counts).
  /// Throttled per [postId] so overlapping triggers do not call in a loop.
  /// Uses `isLoading: false` on the detail request (no global loader), compares
  /// snapshots off the current event work (microtask), and skips UI merge when
  /// nothing changed.
  Future<void> _refreshPostFromDetailForHostCache(String postId) async {
    if (IsrVideoReelConfig.feedCacheConfig == null) return;
    if (postId.isEmpty) return;
    if (_postDetailRefreshInFlight.contains(postId)) return;

    final now = DateTime.now();
    final last = _lastPostDetailRefreshAt[postId];
    if (last != null && now.difference(last) < _minPostDetailRefreshGap) {
      return;
    }

    _postDetailRefreshInFlight.add(postId);
    _lastPostDetailRefreshAt[postId] = now;
    try {
      final before = _findTimelinePostForCompare(postId);
      final snapBefore =
          before != null ? _snapshotForSilentPostDetailCompare(before) : null;

      final result = await _getPostDetailsUseCase.executeGetPostDetails(
        isLoading: false,
        postId: postId,
      );

      if (result.isError) {
        _maybeNotifyPostDeleted(
          postId: postId,
          statusCode: result.error?.statusCode ?? result.statusCode,
          errorMessage: result.error?.message,
        );
        return;
      }

      final fresh = result.data;
      if (fresh == null) return;

      final snapFresh = _snapshotForSilentPostDetailCompare(fresh);
      final unchanged = snapBefore != null &&
          await Future<bool>.microtask(
            () => _silentPostDetailSnapshotsEqual((snapBefore, snapFresh)),
          );
      if (unchanged) return;

      _socialActionCubit.updatePostList([fresh]);
      _replacePostInTabLists(fresh);
      _socialActionCubit.onPostEdited(postId: postId, postData: fresh);
    } catch (_) {
    } finally {
      _postDetailRefreshInFlight.remove(postId);
    }
  }

  /// When host-cache integration is enabled, surface a deletion signal via
  /// [IsmSocialActionCubit.onPostDeleted] for 404/410 responses (or matching
  /// error text). Hosts wired to [IsmDeletedPostActionListenerState] then
  /// evict the post from their cache and from any visible feed.
  void _maybeNotifyPostDeleted({
    required String postId,
    int? statusCode,
    String? errorMessage,
  }) {
    if (IsrVideoReelConfig.feedCacheConfig == null) return;
    if (postId.isEmpty) return;
    final code = statusCode;
    final looksDeleted = code == 404 || code == 410;
    final msg = (errorMessage ?? '').toLowerCase();
    final messageHints = looksDeleted ||
        msg.contains('not found') ||
        msg.contains('post deleted') ||
        msg.contains('410');
    if (!messageHints) return;
    _socialActionCubit.onPostDeleted(postId: postId);
  }

  void _sendAnalyticsEvent(
    String eventName,
    String commentId,
    String postId,
    String userId,
    String commentText,
    TimeLineData? postDataModel,
    TabDataModel? tabDataModel,
  ) async {
    try {
      // Prepare analytics event in the required format: "Post Viewed"
      final postViewedEvent = {
        'post_id': postId,
        'post_type': postDataModel?.type,
        'post_author_id': userId,
        'feed_type': tabDataModel?.postSectionType.title,
        'interests': postDataModel?.interests ?? [],
        'hashtags': postDataModel?.tags?.hashtags?.map((e) => '#$e').toList(),
        'comment_id': commentId,
        'comment_text': commentText,
      };

      EventQueueProvider.instance
          .logEvent(eventName, postViewedEvent.removeEmptyValues());
    } catch (e) {
      debugPrint('❌ Error sending analytics event: $e');
      return null;
    }
  }

  /// Checks if there are any in-review comments in the list (including child comments)
  bool _hasInReviewComments(List<CommentDataItem> comments) {
    for (final comment in comments) {
      if (comment.status == IsrTranslationFile.inReview) {
        return true;
      }
      // Check child comments recursively
      if (comment.childComments != null && comment.childComments!.isNotEmpty) {
        if (_hasInReviewComments(comment.childComments!)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Finds a comment by ID recursively in the comment tree
  CommentDataItem? _findCommentById(
      List<CommentDataItem> comments, String commentId) {
    for (final comment in comments) {
      if (comment.id == commentId) {
        return comment;
      }
      if (comment.childComments != null && comment.childComments!.isNotEmpty) {
        final found = _findCommentById(comment.childComments!, commentId);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  /// Removes in-review comments that have been in that state for more than 20 seconds
  /// Returns true if any comments were removed
  bool _removeOldInReviewComments(
      List<CommentDataItem> comments, String postId) {
    var removedAny = false;
    final now = DateTime.now();
    final commentsToRemove = <CommentDataItem>[];
    final childCommentsToRemove =
        <MapEntry<CommentDataItem, CommentDataItem>>{};

    void checkComments(List<CommentDataItem> commentList) {
      for (final comment in commentList) {
        if (comment.status == IsrTranslationFile.inReview &&
            comment.commentedOn != null) {
          final duration = now.difference(comment.commentedOn!);
          if (duration.inSeconds > 20) {
            // Mark for removal
            if (comment.parentCommentId != null &&
                comment.parentCommentId!.isNotEmpty) {
              // This is a child comment, find parent recursively and mark for removal
              final parentComment =
                  _findCommentById(comments, comment.parentCommentId!);
              if (parentComment != null) {
                childCommentsToRemove.add(MapEntry(parentComment, comment));
              }
            } else {
              // Top-level comment
              commentsToRemove.add(comment);
            }
            removedAny = true;
          }
        }

        // Check child comments recursively
        if (comment.childComments != null &&
            comment.childComments!.isNotEmpty) {
          checkComments(comment.childComments!);
        }
      }
    }

    checkComments(comments);

    // Remove top-level comments
    for (final comment in commentsToRemove) {
      comments.remove(comment);
    }

    // Remove child comments
    for (final entry in childCommentsToRemove) {
      final parent = entry.key;
      final child = entry.value;
      parent.childComments?.remove(child);
      parent.childCommentCount = (parent.childCommentCount ?? 1) - 1;
      if (parent.childComments?.isEmpty == true) {
        parent.showReply = false;
      }
    }

    return removedAny;
  }

  /// Merges API response comments with existing in-review comments
  /// Updates only in-review comments while preserving other comments
  void _mergeCommentsWithInReview(List<CommentDataItem> existingComments,
      List<CommentDataItem> apiComments) {
    // Create a map of API comments by comment text and parentCommentId for matching
    // This includes both top-level and child comments
    final apiCommentMap = <String, CommentDataItem>{};

    void addToMap(CommentDataItem comment) {
      final key = '${comment.comment}_${comment.parentCommentId ?? ''}';
      apiCommentMap[key] = comment;
      // Also add child comments to the map
      if (comment.childComments != null) {
        for (final child in comment.childComments!) {
          addToMap(child);
        }
      }
    }

    for (final apiComment in apiComments) {
      addToMap(apiComment);
    }

    // Update in-review comments in existing list (both top-level and child)
    void updateComments(List<CommentDataItem> comments) {
      for (final existingComment in comments) {
        if (existingComment.status == IsrTranslationFile.inReview) {
          final key =
              '${existingComment.comment}_${existingComment.parentCommentId ?? ''}';
          final matchingApiComment = apiCommentMap[key];
          if (matchingApiComment != null &&
              matchingApiComment.id?.isNotEmpty == true) {
            // Update the existing comment with API data
            existingComment.id = matchingApiComment.id;
            existingComment.status = matchingApiComment.status;
            existingComment.commentedOn = matchingApiComment.commentedOn;
            existingComment.likeCount = matchingApiComment.likeCount;
            existingComment.isLiked = matchingApiComment.isLiked;
            existingComment.commentLikeList =
                matchingApiComment.commentLikeList;
            existingComment.profilePic = matchingApiComment.profilePic;
            existingComment.fullName = matchingApiComment.fullName;
            // Preserve other fields that might have been set locally
          }
        }

        // Recursively update child comments
        if (existingComment.childComments != null &&
            existingComment.childComments!.isNotEmpty) {
          updateComments(existingComment.childComments!);
        }
      }
    }

    updateComments(existingComments);
  }

  /// Starts the periodic update timer for in-review comments
  void _startInReviewUpdateTimer(String postId) {
    // Cancel existing timer if any
    _inReviewUpdateTimer?.cancel();

    // Start new periodic timer (every 3 seconds)
    _inReviewUpdateTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      final commentList = _postsWithInReviewComments[postId];
      if (commentList == null || commentList.isEmpty) {
        _stopInReviewUpdateTimer();
        _postsWithInReviewComments.remove(postId);
        return;
      }

      // Remove in-review comments that have been in that state for more than 20 seconds
      final removedAny = _removeOldInReviewComments(commentList, postId);

      // Check if there are any in-review comments remaining
      if (!_hasInReviewComments(commentList)) {
        _stopInReviewUpdateTimer();
        _postsWithInReviewComments.remove(postId);
        // Update state if comments were removed
        if (removedAny) {
          add(GetPostCommentsEvent(
            postId: postId,
            isLoading: false,
          ));
        }
        return;
      }

      // Update stored comment list if comments were removed
      if (removedAny) {
        _postsWithInReviewComments[postId] = commentList;
      }

      // Fetch updated comments from API (GetPostCommentsEvent will handle merging)
      add(GetPostCommentsEvent(
        postId: postId,
        isLoading: false,
      ));

      // Also fetch replies for parent comments that have in-review reply comments
      final parentCommentsWithInReviewReplies = <CommentDataItem>[];
      void findParentsWithInReviewReplies(List<CommentDataItem> comments) {
        for (final comment in comments) {
          if (comment.childComments != null &&
              comment.childComments!.isNotEmpty) {
            final hasInReviewReply = comment.childComments!.any(
              (child) => child.status == IsrTranslationFile.inReview,
            );
            if (hasInReviewReply &&
                comment.id != null &&
                comment.id!.isNotEmpty) {
              parentCommentsWithInReviewReplies.add(comment);
            }
            // Recursively check nested comments
            findParentsWithInReviewReplies(comment.childComments!);
          }
        }
      }

      findParentsWithInReviewReplies(commentList);

      // Fetch replies for each parent comment with in-review replies
      for (final parentComment in parentCommentsWithInReviewReplies) {
        add(GetPostCommentReplyEvent(
          postId: postId,
          parentComment: parentComment,
          isLoading: false,
        ));
      }
    });
  }

  /// Stops the periodic update timer
  void _stopInReviewUpdateTimer() {
    _inReviewUpdateTimer?.cancel();
    _inReviewUpdateTimer = null;
  }

  @override
  Future<void> close() {
    _stopInReviewUpdateTimer();
    _postsWithInReviewComments.clear();
    return super.close();
  }

  Future<ApiResult<ResponseClass?>> sendEventsToBackend(
          List<Map<String, dynamic>> eventPayLoadList) async =>
      await postImpressionUseCase.executePostImpression(
          isLoading: false, impressionMapList: eventPayLoadList);
}
