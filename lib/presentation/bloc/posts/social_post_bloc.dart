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
    this._getReportReasonsUseCase,
    this._getPostDetailsUseCase,
    this._getPostCommentUseCase,
    this._commentUseCase,
    this._getSocialProductsUseCase,
    this._getMentionedUsersUseCase,
    this._removeMentionUseCase,
    this._getTaggedPostsUseCase,
    this._getUserPostDataUseCase,
    this._deletePostUseCase,
  ) : super(PostLoadingState(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<LoadPostData>(_onLoadHomeData);
    on<GetTimeLinePostEvent>(_getTimeLinePost);
    on<GetTrendingPostEvent>(_getTrendingPost);
    on<SavePostEvent>(_savePost);
    on<GetReasonEvent>(_getReason);
    on<ReportPostEvent>(_reportPost);
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
  final GetReportReasonsUseCase _getReportReasonsUseCase;
  final GetPostDetailsUseCase _getPostDetailsUseCase;
  final GetPostCommentUseCase _getPostCommentUseCase;
  final CommentActionUseCase _commentUseCase;
  final GetSocialProductsUseCase _getSocialProductsUseCase;
  final GetMentionedUsersUseCase _getMentionedUsersUseCase;
  final RemoveMentionUseCase _removeMentionUseCase;
  final GetTaggedPostsUseCase _getTaggedPostsUseCase;
  final GetUserPostDataUseCase _getUserPostDataUseCase;

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

  // Timer for periodic in-review comment updates
  Timer? _inReviewUpdateTimer;
  // Map to track posts with in-review comments: postId -> current comment list
  final Map<String, List<CommentDataItem>> _postsWithInReviewComments = {};

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
    } else if (tabAssistData.isLoadingMore || !tabAssistData.hasMoreData) {
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
      postIdPostData = postTabAssistData.postList.where((e) => e.id == postTabAssistData.postId).firstOrNull;
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
        }
        break;
      default:
        break;
    }
    var postDataList = <TimeLineData>[];
    if (postIdPostData != null) {
      postDataList.add(postIdPostData);
    }
    if (tabAssistData.postSectionType == PostSectionType.following) {
      apiResult?.data?.data?.forEach((_) => _.isFollowing = true);
    }
    postDataList.addAll(apiResult?.data?.data ?? []);
    if (postDataList.isNotEmpty) {
      _socialActionCubit.updatePostList(postDataList);
      if (postDataList.length < tabAssistData.pageSize) {
        tabAssistData.hasMoreData = false;
      }

      if (isFromPagination) {
        tabAssistData.postList.addAll(postDataList);
      } else {
        tabAssistData.postList
          ..clear()
          ..addAll(postDataList);
      }
      tabAssistData.currentPage++;
    } else {
      tabAssistData.hasMoreData = false;
      ErrorHandler.showAppError(appError: apiResult?.error);
    }
    if (onComplete != null) {
      onComplete(postDataList);
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
      isLoading: false,
    );

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
    if (event.onComplete != null) {
      event.onComplete?.call(finalCommentList ?? []);
    } else {
      emit(LoadPostCommentState(
        postCommentsList: finalCommentList,
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
        ErrorHandler.showAppError(
          appError: apiResult.error,
          message: IsrTranslationFile.commentReportedSuccessfully,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.snackBar,
        );
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

      // Update status to in_review
      comment.status = IsrTranslationFile.inReview;
      // Update commentedOn to track when it entered in_review (for 10-second timeout check)
      comment.commentedOn = DateTime.now();

      if (commentList != null) {
        // Store current comment list for this post to track in-review comments
        _postsWithInReviewComments[event.postId ?? ''] = commentList;

        emit(
          LoadPostCommentState(
            postCommentsList: commentList,
            myUserId: myUserId,
          ),
        );
      }

      // Start periodic update if not already running
      _startInReviewUpdateTimer(event.postId ?? '');

      // Initial delay before first update
      Future.delayed(const Duration(seconds: 2), () {
        add(
          GetPostCommentsEvent(
              postId: event.postId ?? '',
              isLoading: false,
              createdComment: comment),
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
    final apiResult = await _getPostDetailsUseCase.executeGetPostDetails(
      isLoading: false,
      postId: event.postId ?? '',
    );
    emit(PostInsightDetails(
      postId: event.postId ?? '',
      postData: apiResult.data ?? event.data,
    ));
    if (apiResult.isError) {
      ErrorHandler.showAppError(
          appError: apiResult.error,
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

      unawaited(EventQueueProvider.instance
          .addEvent(eventName, postViewedEvent.removeEmptyValues()));
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

  /// Removes in-review comments that have been in that state for more than 10 seconds
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
          if (duration.inSeconds > 10) {
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

      // Remove in-review comments that have been in that state for more than 10 seconds
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
}
