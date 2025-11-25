import 'dart:async';
import 'dart:convert';

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

  UserInfoClass? _userInfoClass;
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

  void _onStartPost(StartPost event, Emitter<SocialPostState> emit) async {
    final userInfoString = await _localDataUseCase.getUserInfo();
    _userInfoClass = userInfoString.isStringEmptyOrNull
        ? null
        : UserInfoClass.fromJson(
            jsonDecode(userInfoString) as Map<String, dynamic>);
    // add(LoadPostData(
    //   postSections: event.postSections
    // ));
  }

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
        'social_post_bloc => postIdPostData cond: ${(postTabAssistData.postId?.trim().isNotEmpty == true && postTabAssistData.postList.isEmpty)}');
    if (postTabAssistData.postId?.trim().isNotEmpty == true &&
        postTabAssistData.postList.isEmpty) {
      postIdPostData = await _getPostDetails(postTabAssistData.postId ?? '',
          onSuccess: postTabAssistData.postList.add);
      debugPrint('social_post_bloc => postIdPostData: ${postIdPostData?.id}');
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
    postDataList.addAll(apiResult?.data?.data ?? []);
    if (postDataList.isNotEmpty) {
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
      event.onComplete.call(true);
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
      userId: event.userId,
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
    if (_postsByTab.any((_) => _.postSectionType == PostSectionType.trending)) {
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
      emit(LoadingPostCommentReplies());
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
      myUserId: myUserId,
    ));
  }

  Future<void> _doActionOnComment(
      CommentActionEvent event, Emitter<SocialPostState> emit) async {
    final commentRequest = CommentRequest(
            commentId: event.commentId,
            commentAction: event.commentAction,
            postId: event.postId,
            userType: event.commentAction == CommentAction.comment ? 1 : null,
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
    CommentDataItem? comment;
    if (event.commentAction == CommentAction.comment) {
      comment = CommentDataItem(
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

      if (commentList != null) {
        if (comment.parentCommentId != null &&
            comment.parentCommentId!.isNotEmpty) {
          // Find parent comment
          final parentComment = commentList.firstWhere(
            (element) => element.id == comment?.parentCommentId,
            orElse: () => throw Exception('Parent comment not found'),
          );

          // Ensure childComments list exists
          parentComment.childComments ??= [];

          // Insert reply at the beginning
          parentComment.childComments!.insert(0, comment);
          parentComment.childCommentCount ??= 0;
          parentComment.childCommentCount =
              parentComment.childCommentCount! + 1;
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
      // ✅ Delay before calling API
      Future.delayed(const Duration(seconds: 2), () {
        add(
          GetPostCommentsEvent(
              postId: event.postId ?? '',
              isLoading: false,
              createdComment: comment),
        );
      });
    }
    final apiResult = await _commentUseCase.executeCommentAction(
      isLoading: event.isLoading ?? true,
      commentRequest: commentRequest.toJson(),
    );
    if (apiResult.isSuccess) {
      if (event.commentAction == CommentAction.comment) {
        comment?.status = IsrTranslationFile.inReview;
        if (commentList != null) {
          emit(
            LoadPostCommentState(
              postCommentsList: commentList,
              myUserId: myUserId,
            ),
          );
        }
        // ✅ Delay before calling API
        Future.delayed(const Duration(seconds: 2), () {
          add(
            GetPostCommentsEvent(
                postId: event.postId ?? '',
                isLoading: false,
                createdComment: comment),
          );
        });
      } else if (event.commentAction == CommentAction.report) {
        ErrorHandler.showAppError(
          appError: apiResult.error,
          message: IsrTranslationFile.commentReportedSuccessfully,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.snackBar,
        );
      } else if (event.commentAction == CommentAction.delete &&
          event.commentId?.trim().isNotEmpty == true) {
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

  Future<TimeLineData?> _getPostDetails(String postId,
      {Function(TimeLineData data)? onSuccess, bool showError = true}) async {
    final result = await _getPostDetailsUseCase.executeGetPostDetails(
      isLoading: false,
      postId: postId ?? '',
    );

    if (result.isSuccess && onSuccess != null) {
      result.data?.let(onSuccess);
    }

    if (result.isError && showError) {
      ErrorHandler.showAppError(
          appError: result.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }

    return result.data;
  }
}
