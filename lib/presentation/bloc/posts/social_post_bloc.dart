import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'social_post_event.dart';
part 'social_post_state.dart';

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
  ) : super(PostLoadingState(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<LoadPostData>(_onLoadHomeData);
    on<GetTimeLinePostEvent>(_getTimeLinePost);
    on<GetTrendingPostEvent>(_getTrendingPost);
    on<SavePostEvent>(_savePost);
    on<GetReasonEvent>(_getReason);
    on<ReportPostEvent>(_reportPost);
    on<ReportEvent>(_report);
    on<LikePostEvent>(_likePost);
    on<FollowUserEvent>(_followUser);
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
  final GetTaggedPostsUseCase _getTaggedPostsUseCase;
  final GetUserPostDataUseCase _getUserPostDataUseCase;
  final PostImpressionUseCase postImpressionUseCase;

  IsmSocialActionCubit get _socialActionCubit => IsmInjectionUtils.getBloc();

  var reelsPageTrendingController = PageController();
  TextEditingController? descriptionController;

  final _postsByTab = <PostTabAssistData>[];

  PostTabAssistData _getTabAssistData(PostSectionType tab) => _postsByTab
          .toList()
          .firstWhere((_) => _.postSectionType == tab, orElse: () {
        final tabAssist = PostTabAssistData(postSectionType: tab, postList: []);
        _postsByTab.add(tabAssist);
        return tabAssist;
      });

  int currentPage = 0;
  final followingPageSize = 20;

  var _isDataLoading = false;
  var _detailsCurrentPage = 1;
  var _commentPage = 1;

  final List<ProductDataModel> _detailsProductList = [];

  void _onStartPost(StartPost event, Emitter<SocialPostState> emit) async {}

  Future<String> get userId => _localDataUseCase.getUserId();

  Future<void> _onLoadHomeData(
    LoadPostData event,
    Emitter<SocialPostState> emit,
  ) async {
    // final userId = await _localDataUseCase.getUserId();
    try {
      emit(PostLoadingState(isLoading: true));
      _postsByTab.clear();
      _postsByTab.addAll(event.postSections);
      for (final postTab in event.postSections) {
        if (postTab.postList.isEmpty) {
          if (postTab.postId?.trim().isNotEmpty == true &&
              postTab.postList.isEmpty) {
            final postIdData = await _getPostDetails(postTab.postId ?? '');
            if (postIdData != null) {
              postTab.postList.add(postIdData);
              add(LoadPostsEvent(
                  postsByTab: _postsByTab.asMap().map((key, value) =>
                      MapEntry(value.postSectionType, value.postList))));
            }
          }
          await _callGetTabPost(postTab, false, false, false, null);
        }
        add(LoadPostsEvent(
            postsByTab: _postsByTab.asMap().map((key, value) =>
                MapEntry(value.postSectionType, value.postList))));
        _socialActionCubit.updatePostList(postTab.postList);
      }
    } catch (error) {
      emit(SocialPostError(error.toString()));
    }
  }

  FutureOr<void> _getMorePost(
      GetMorePostEvent event, Emitter<SocialPostState> emit) async {
    await _callGetTabPost(
      _getTabAssistData(event.postSectionType),
      event.isRefresh,
      event.isPagination,
      event.isLoading,
      event.onComplete,
    );
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
    Function(List<TimeLineData>)? onComplete,
  ) async {
    final postSectionType = postTabAssistData.postSectionType;
    final tabAssistData = _getTabAssistData(postSectionType);

    // For refresh, clear cache and start from page 1
    if (isFromRefresh) {
      tabAssistData.postList.clear();
      tabAssistData.currentPage = 1;
      tabAssistData.hasMoreData = true;
      tabAssistData.isLoadingMore = false;
    } else if (!isFromPagination && tabAssistData.postList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    }

    if (!isFromPagination) {
      tabAssistData.currentPage = 1;
      tabAssistData.hasMoreData = true;
    } else {
      // PAGINATION FIX: Better handling of pagination state
      // Don't return immediately - check if we should retry after error
      if (tabAssistData.isLoadingMore) {
        debugPrint(
            '⏸️ Pagination: Already loading more for ${postSectionType.name}, skipping');
        return;
      }
      if (!tabAssistData.hasMoreData) {
        debugPrint('⏸️ Pagination: No more data for ${postSectionType.name}');
        return;
      }
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
    }

    // Route to the correct use case based on PostSectionType
    ApiResult<TimelineResponse?>? apiResult;
    switch (postSectionType) {
      case PostSectionType.trending:
        apiResult = await _getTrendingPostUseCase.executeGetTrendingPost(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
        );
        break;
      case PostSectionType.forYou:
        apiResult = await _getForYouPostUseCase.executeGetForYouPost(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
        );
        break;
      case PostSectionType.following:
        apiResult = await _getTimelinePostUseCase.executeTimeLinePost(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
        );
        break;
      case PostSectionType.savedPost:
        apiResult = await _savePostUseCase.executeGetProfileSavedPostData(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageSize: tabAssistData.pageSize,
        );
        break;
      case PostSectionType.tagPost:
        if (tabAssistData.tagType != null && tabAssistData.tagValue != null) {
          apiResult = await _getTaggedPostsUseCase.executeGetTaggedPosts(
            isLoading: isLoading,
            page: tabAssistData.currentPage,
            pageLimit: tabAssistData.pageSize,
            tagValue: tabAssistData.tagValue!,
            tagType: tabAssistData.tagType!,
          );
        } else {
          // Missing required parameters - mark as no more data
          debugPrint(
              '⚠️ Pagination: tagPost missing tagType or tagValue, marking as no more data');
          tabAssistData.hasMoreData = false;
          tabAssistData.isLoadingMore = false;
          if (onComplete != null) {
            onComplete([]);
          }
          return;
        }
        break;
      case PostSectionType.myTaggedPost:
        apiResult = await _getTaggedPostsUseCase.executeGetTaggedPosts(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageLimit: tabAssistData.pageSize,
          tagValue: await _localDataUseCase.getUserId(),
          tagType: TagType.mention,
        );
        break;
      case PostSectionType.myPost:
        apiResult = await _getUserPostDataUseCase.executeGetUserProfilePostData(
          isLoading: isLoading,
          page: tabAssistData.currentPage,
          pageSize: tabAssistData.pageSize,
          memberId: tabAssistData.userId ?? await _localDataUseCase.getUserId(),
        );
        break;
      case PostSectionType.otherUserPost:
        if (tabAssistData.userId != null) {
          apiResult =
              await _getUserPostDataUseCase.executeGetUserProfilePostData(
            isLoading: isLoading,
            page: tabAssistData.currentPage,
            pageSize: tabAssistData.pageSize,
            memberId: tabAssistData.userId!,
          );
        } else {
          // Missing required userId - mark as no more data
          debugPrint(
              '⚠️ Pagination: otherUserPost missing userId, marking as no more data');
          tabAssistData.hasMoreData = false;
          tabAssistData.isLoadingMore = false;
          if (onComplete != null) {
            onComplete([]);
          }
          return;
        }
        break;
      case PostSectionType.singlePost:
        // Single post doesn't support pagination - mark as no more data
        debugPrint('⚠️ Pagination: singlePost doesn\'t support pagination');
        tabAssistData.hasMoreData = false;
        tabAssistData.isLoadingMore = false;
        if (onComplete != null) {
          onComplete([]);
        }
        return;
    }
    var postDataList = <TimeLineData>[];
    if (postIdPostData != null) {
      postDataList.add(postIdPostData);
    }
    if (tabAssistData.postSectionType == PostSectionType.following) {
      apiResult.data?.data?.forEach((_) => _.isFollowing = true);
    }
    postDataList.addAll(apiResult.data?.data ?? []);

    // PAGINATION FIX: Better error handling and state management
    if (apiResult.isSuccess) {
      if (postDataList.isNotEmpty) {
        _socialActionCubit.updatePostList(postDataList);

        // PAGINATION FIX: Compare API response count, not postDataList count
        // postDataList includes postIdPostData which skews the count
        final apiResponseCount = apiResult.data?.data?.length ?? 0;
        debugPrint(
            '📊 Pagination: API returned $apiResponseCount items (pageSize: ${tabAssistData.pageSize}) for ${postSectionType.name}');

        // PAGINATION FIX: Determine hasMoreData with fallback verification
        if (apiResponseCount < tabAssistData.pageSize) {
          // Fewer items than requested - definitely no more data
          tabAssistData.hasMoreData = false;
          debugPrint(
              '⚠️ Pagination: No more data for ${postSectionType.name} (API returned $apiResponseCount < ${tabAssistData.pageSize})');
        } else if (apiResponseCount == tabAssistData.pageSize) {
          // Exactly pageSize items - verify by checking next page (fallback)
          debugPrint(
              '🔍 Pagination: API returned exactly ${tabAssistData.pageSize} items, verifying next page availability for ${postSectionType.name}');
          // Set optimistic value first, then verify
          tabAssistData.hasMoreData = true;
          // Verify next page asynchronously (non-blocking)
          unawaited(
              _verifyNextPageAvailability(tabAssistData, postSectionType));
        } else {
          // More items than pageSize (shouldn't happen, but handle it)
          tabAssistData.hasMoreData = true;
          debugPrint(
              '✅ Pagination: More data available for ${postSectionType.name} (API returned $apiResponseCount > ${tabAssistData.pageSize})');
        }

        if (isFromPagination) {
          tabAssistData.postList.addAll(postDataList);
        } else {
          tabAssistData.postList
            ..clear()
            ..addAll(postDataList);
        }
        tabAssistData.currentPage++;

        if (onComplete != null) {
          onComplete(postDataList);
        }
      } else {
        // Empty results - no more data
        tabAssistData.hasMoreData = false;
        debugPrint('⚠️ Pagination: No more data for ${postSectionType.name}');
        if (onComplete != null) {
          onComplete(postDataList);
        }
      }
    } else {
      // PAGINATION FIX: Handle network errors properly - don't mark as no more data
      // Allow retry on next pagination attempt
      debugPrint(
          '❌ Pagination: Error loading ${postSectionType.name} - ${apiResult.error}');
      ErrorHandler.showAppError(appError: apiResult.error);

      // PAGINATION FIX: Don't increment page on error, allow retry
      // Network errors will allow retry, server errors mark as no more data
      if (apiResult.error != null) {
        final errorMessage = apiResult.error!.message.toLowerCase();
        if (errorMessage.contains('server') || errorMessage.contains('500')) {
          tabAssistData.hasMoreData = false;
        }
      }

      if (onComplete != null) {
        onComplete(postDataList);
      }
    }

    tabAssistData.isLoadingMore = false;
  }

  /// PAGINATION FALLBACK: Verify if next page has data by actually fetching it
  /// This ensures we don't stop pagination prematurely when API returns exactly pageSize items
  Future<void> _verifyNextPageAvailability(
    PostTabAssistData tabAssistData,
    PostSectionType postSectionType,
  ) async {
    // Don't verify if already determined no more data
    if (!tabAssistData.hasMoreData) return;

    // Store original page - we want to check the NEXT page (currentPage + 1)
    // Note: currentPage was already incremented in _callGetTabPost, so nextPage = currentPage
    final nextPage = tabAssistData.currentPage;

    debugPrint(
        '🔍 Pagination Fallback: Verifying next page ($nextPage) for ${postSectionType.name}');

    try {
      // Make a lightweight API call to check next page
      ApiResult<TimelineResponse?>? apiResult;

      switch (postSectionType) {
        case PostSectionType.trending:
          apiResult = await _getTrendingPostUseCase.executeGetTrendingPost(
            isLoading: false, // Don't show loading indicator for verification
            page: nextPage,
            pageLimit: tabAssistData.pageSize,
          );
          break;
        case PostSectionType.forYou:
          apiResult = await _getForYouPostUseCase.executeGetForYouPost(
            isLoading: false,
            page: nextPage,
            pageLimit: tabAssistData.pageSize,
          );
          break;
        case PostSectionType.following:
          apiResult = await _getTimelinePostUseCase.executeTimeLinePost(
            isLoading: false,
            page: nextPage,
            pageLimit: tabAssistData.pageSize,
          );
          break;
        case PostSectionType.savedPost:
          apiResult = await _savePostUseCase.executeGetProfileSavedPostData(
            isLoading: false,
            page: nextPage,
            pageSize: tabAssistData.pageSize,
          );
          break;
        case PostSectionType.tagPost:
          if (tabAssistData.tagType != null && tabAssistData.tagValue != null) {
            apiResult = await _getTaggedPostsUseCase.executeGetTaggedPosts(
              isLoading: false,
              page: nextPage,
              pageLimit: tabAssistData.pageSize,
              tagValue: tabAssistData.tagValue!,
              tagType: tabAssistData.tagType!,
            );
          } else {
            // Missing required parameters - can't verify
            debugPrint(
                '⚠️ Pagination Fallback: tagPost missing tagType or tagValue, skipping verification');
            return;
          }
          break;
        case PostSectionType.myTaggedPost:
          apiResult = await _getTaggedPostsUseCase.executeGetTaggedPosts(
            isLoading: false,
            page: nextPage,
            pageLimit: tabAssistData.pageSize,
            tagValue: await _localDataUseCase.getUserId(),
            tagType: TagType.mention,
          );
          break;
        case PostSectionType.myPost:
          apiResult =
              await _getUserPostDataUseCase.executeGetUserProfilePostData(
            isLoading: false,
            page: nextPage,
            pageSize: tabAssistData.pageSize,
            memberId:
                tabAssistData.userId ?? await _localDataUseCase.getUserId(),
          );
          break;
        case PostSectionType.otherUserPost:
          if (tabAssistData.userId != null) {
            apiResult =
                await _getUserPostDataUseCase.executeGetUserProfilePostData(
              isLoading: false,
              page: nextPage,
              pageSize: tabAssistData.pageSize,
              memberId: tabAssistData.userId!,
            );
          } else {
            // Missing required userId - can't verify
            debugPrint(
                '⚠️ Pagination Fallback: otherUserPost missing userId, skipping verification');
            return;
          }
          break;
        case PostSectionType.singlePost:
          // Single post doesn't support pagination - no need to verify
          debugPrint(
              '⚠️ Pagination Fallback: singlePost doesn\'t support pagination, skipping verification');
          tabAssistData.hasMoreData = false;
          return;
      }

      if (apiResult.isSuccess) {
        final nextPageCount = apiResult.data?.data?.length ?? 0;
        if (nextPageCount == 0) {
          // Next page is empty - no more data
          tabAssistData.hasMoreData = false;
          debugPrint(
              '⚠️ Pagination Fallback: Next page ($nextPage) is empty for ${postSectionType.name} - no more data');
        } else {
          // Next page has data - more data available
          tabAssistData.hasMoreData = true;
          debugPrint(
              '✅ Pagination Fallback: Next page ($nextPage) has $nextPageCount items for ${postSectionType.name} - more data available');
        }
      } else {
        // Error checking next page - assume there might be more data (don't block pagination)
        debugPrint(
            '⚠️ Pagination Fallback: Error verifying next page for ${postSectionType.name} - ${apiResult.error}. Keeping hasMoreData=true');
        tabAssistData.hasMoreData =
            true; // Optimistic - allow pagination to continue
      }
    } catch (e) {
      // Exception during verification - assume there might be more data
      debugPrint(
          '❌ Pagination Fallback: Exception verifying next page for ${postSectionType.name}: $e. Keeping hasMoreData=true');
      tabAssistData.hasMoreData =
          true; // Optimistic - allow pagination to continue
    }
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
      ErrorHandler.showAppError(appError: apiResult.error);
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
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
    if (_postsByTab
        .any((_) => _.postSectionType == PostSectionType.following)) {
      await _callGetTabPost(_getTabAssistData(PostSectionType.following), true,
          false, false, null);
      add(LoadPostsEvent(
          postsByTab: _postsByTab.asMap().map((key, value) =>
              MapEntry(value.postSectionType, value.postList))));
    }
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
      emit(LoadingPostComment());
    }
    _commentPage = event.isPagination ? _commentPage + 1 : 1;
    final apiResult = await _getPostCommentUseCase.executeGetPostComment(
      postId: event.postId,
      isLoading: event.isLoading == true,
      page: _commentPage,
      pageLimit: 20,
    );
    final postCommentsList = apiResult.data?.data;

    final myUserId = await _localDataUseCase.getUserId();
    if (event.onComplete != null) {
      event.onComplete?.call(postCommentsList ?? []);
    } else {
      emit(LoadPostCommentState(
        postCommentsList: postCommentsList,
        myUserId: myUserId,
      ));
    }
  }

  FutureOr<void> _getPostCommentReplies(
      GetPostCommentReplyEvent event, Emitter<SocialPostState> emit) async {
    if (event.isLoading == true) {
      emit(LoadingPostCommentReplies(
        parentCommentId: event.parentComment.id ?? '',
      ));
    }
    final apiResult = await _getPostCommentUseCase.executeGetPostComment(
      postId: event.postId,
      parentCommitId: event.parentComment.id,
      isLoading: false,
    );
    final postCommentRepliesList = apiResult.data?.data;

    final myUserId = await _localDataUseCase.getUserId();
    emit(LoadPostCommentRepliesState(
      postCommentRepliesList: postCommentRepliesList,
      parentCommentId: event.parentComment.id ?? '',
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
      isLoading: event.isLoading ?? true,
      commentRequest: commentRequest.toJson(),
    );

    if (apiResult.isSuccess) {
      if (event.commentAction == CommentAction.report) {
        Utility.showToastMessage(
            IsrTranslationFile.commentReportedSuccessfully);
      } else if (event.commentAction == CommentAction.delete &&
          event.commentId?.trim().isNotEmpty == true) {
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
      comment: commentRequest.comment,
      postId: commentRequest.postId,
      commentedByUserId: myUserId,
      parentCommentId: commentRequest.parentCommentId,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      commentedOn: DateTime.now(),
      likeCount: 0,
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
          myUserId: myUserId,
        ),
      );
    }

    // Call API to create comment
    final apiResult = await _commentUseCase.executeCommentAction(
      isLoading: event.isLoading ?? true,
      commentRequest: commentRequest.toJson(),
    );

    if (apiResult.isSuccess) {
      _sendAnalyticsEvent(
          EventType.commentCreated.value,
          event.commentId ?? '',
          event.postId ?? '',
          event.userId ?? '',
          event.commentMessage ?? '',
          event.postDataModel,
          event.tabDataModel);
      // Comment stays in the list with no status - will sync on bottom sheet reopen
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
            myUserId: myUserId,
          ),
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
      page: 1,
      pageLimit: 10,
    );
    event.onComplete?.call(apiResult.data?.data ?? []);
    if (apiResult.isError) {
      ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }
  }

  FutureOr<void> _playPauseVideo(
      PlayPauseVideoEvent event, Emitter<SocialPostState> emit) async {
    emit(PlayPauseVideoState(play: event.play));
  }

  FutureOr<void> _removeMention(
      RemoveMentionEvent event, Emitter<SocialPostState> emit) async {
    final apiResult = await _removeMentionUseCase.executeRemoveMention(
      isLoading: false,
      postId: event.postId,
    );
    event.onComplete?.call(apiResult.isSuccess);
    if (apiResult.isError) {
      ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }
  }

  FutureOr<void> _loadPosts(
      LoadPostsEvent event, Emitter<SocialPostState> emit) async {
    event.postsByTab.forEach((tab, posts) => debugPrint(
        'social_post_bloc => _loadPosts: $tab , postcount: ${posts.length}'));
    final myUserId = await _localDataUseCase.getUserId();
    emit(SocialPostLoadedState(
      postsByTab: event.postsByTab,
      userId: myUserId,
    ));
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

    if (result.isError && showError) {
      ErrorHandler.showAppError(
          appError: result.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }

    return result.data;
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

  Future<bool> sendEventsToBackend(
      List<Map<String, dynamic>> eventPayLoadList) async {
    final apiResult = await postImpressionUseCase.executePostImpression(
        isLoading: false, impressionMapList: eventPayLoadList);
    if (apiResult.isSuccess) {
      return true;
    }
    return false;
  }
}
