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
    on<GetSocialProductsEvent>(_getSocialProducts);
    on<GetPostCommentsEvent>(_getPostComments);
    on<CommentActionEvent>(_doActionOnComment);
    on<LoadPostsEvent>(_loadPosts);
    on<GetMorePostEvent>(_getMorePost);
    on<GetPostInsightDetailsEvent>(_getPostInsightDetails);
  }

  final IsmLocalDataUseCase _localDataUseCase;
  final GetTimelinePostUseCase _getTimelinePostUseCase;
  final GetTrendingPostUseCase _getTrendingPostUseCase;
  final GetForYouPostUseCase _getForYouPostUseCase;
  final FollowUnFollowUserUseCase _followPostUseCase;
  final SavePostUseCase _savePostUseCase;
  final LikePostUseCase _likePostUseCase;
  final ReportPostUseCase _reportPostUseCase;
  final GetReportReasonsUseCase _getReportReasonsUseCase;
  final GetPostDetailsUseCase _getPostDetailsUseCase;
  final GetPostCommentUseCase _getPostCommentUseCase;
  final CommentActionUseCase _commentUseCase;
  final GetSocialProductsUseCase _getSocialProductsUseCase;

  UserInfoClass? _userInfoClass;
  var reelsPageTrendingController = PageController();
  TextEditingController? descriptionController;

  final List<TimeLineData> _trendingPostList = [];
  final List<TimeLineData> _timeLinePostList = [];
  final List<TimeLineData> _forYouPostList = [];

  int currentPage = 0;
  final followingPageSize = 20;
  int _trendingCurrentPage = 1;
  bool _hasTrendingMoreData = true;
  bool _isTrendingLoadingMore = false;
  final _trendingPageSize = 20;

  bool _isTimeLineLoadingMore = false;
  bool _hasMoreTimeLineData = true;
  int _timeLineCurrentPage = 1;
  final _timeLinePageSize = 20;

  var _isDataLoading = false;
  var _detailsCurrentPage = 1;

  int _forYouCurrentPage = 1;
  bool _hasForYouMoreData = true;
  bool _isForYouLoadingMore = false;
  final _forYouPageSize = 20;

  final List<ProductDataModel> _detailsProductList = [];

  void _onStartPost(StartPost event, Emitter<SocialPostState> emit) async {
    final userInfoString = await _localDataUseCase.getUserInfo();
    _userInfoClass = userInfoString.isStringEmptyOrNull
        ? null
        : UserInfoClass.fromJson(
            jsonDecode(userInfoString) as Map<String, dynamic>);
    add(LoadPostData());
  }

  Future<void> _onLoadHomeData(
    LoadPostData event,
    Emitter<SocialPostState> emit,
  ) async {
    // final userId = await _localDataUseCase.getUserId();
    try {
      emit(PostLoadingState(isLoading: true));
      await Future.wait([
        _callGetForYouPost(true, false, false, null),
        _callGetTrendingPost(true, false, false, null),
        _callGetTimeLinePost(true, false, false, null),
      ]);
      add(LoadPostsEvent(
          timeLinePostList: _timeLinePostList,
          trendingPosts: _trendingPostList,
          forYouPosts: _forYouPostList));
    } catch (error) {
      emit(SocialPostError(error.toString()));
    }
  }

  FutureOr<void> _getMorePost(
      GetMorePostEvent event, Emitter<SocialPostState> emit) async {
    if (event.postSectionType == PostSectionType.forYou) {
      await _callGetForYouPost(
        event.isRefresh,
        event.isPagination,
        event.isLoading,
        event.onComplete,
      );
    } else if (event.postSectionType == PostSectionType.following) {
      await _callGetTimeLinePost(
        event.isRefresh,
        event.isPagination,
        event.isLoading,
        event.onComplete,
      );
    } else {
      await _callGetTrendingPost(
        event.isRefresh,
        event.isPagination,
        event.isLoading,
        event.onComplete,
      );
    }
  }

  FutureOr<void> _getTimeLinePost(
      GetTimeLinePostEvent event, Emitter<SocialPostState> emit) async {
    await _callGetTimeLinePost(
        event.isRefresh, event.isPagination, event.isLoading, event.onComplete);
  }

  FutureOr<void> _getTrendingPost(
      GetTrendingPostEvent event, Emitter<SocialPostState> emit) async {
    await _callGetTrendingPost(
        event.isRefresh, event.isPagination, event.isLoading, event.onComplete);
  }

  Future<void> _callGetTrendingPost(
    bool isFromRefresh,
    bool isFromPagination,
    bool isLoading,
    Function(List<TimeLineData>)? onComplete,
  ) async {
    // For refresh, clear cache and start from page 0
    if (isFromRefresh) {
      _trendingPostList.clear();
      _trendingCurrentPage = 1;
      _hasTrendingMoreData = true;
      _isTrendingLoadingMore = false;
    } else if (!isFromPagination && _trendingPostList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    }

    if (!isFromPagination) {
      _trendingCurrentPage = 1;
      _hasTrendingMoreData = true;
    } else if (_isTrendingLoadingMore || !_hasTrendingMoreData) {
      return;
    }

    _isTrendingLoadingMore = true;

    final apiResult = await _getTrendingPostUseCase.executeGetTrendingPost(
      isLoading: isLoading,
      page: _trendingCurrentPage,
      pageLimit: _trendingPageSize,
    );

    if (apiResult.isSuccess) {
      final postDataList = apiResult.data?.data as List<TimeLineData>;
      if (postDataList.isListEmptyOrNull) {
        _hasTrendingMoreData = false;
      } else {
        if (isFromPagination) {
          _trendingPostList.addAll(postDataList);
        } else {
          _trendingPostList
            ..clear()
            ..addAll(postDataList);
        }
        if (onComplete != null) {
          onComplete(postDataList);
        }
        _trendingCurrentPage++;
        // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isTrendingLoadingMore = false;
  }

  Future<void> _callGetForYouPost(
    bool isFromRefresh,
    bool isFromPagination,
    bool isLoading,
    Function(List<TimeLineData>)? onComplete,
  ) async {
    // For refresh, clear cache and start from page 0
    if (isFromRefresh) {
      _forYouPostList.clear();
      _forYouCurrentPage = 1;
      _hasForYouMoreData = true;
      _isForYouLoadingMore = false;
    }

    if (!isFromPagination) {
      _forYouCurrentPage = 1;
      _hasForYouMoreData = true;
    } else if (_isForYouLoadingMore || !_hasForYouMoreData) {
      return;
    }

    _isForYouLoadingMore = true;

    final apiResult = await _getForYouPostUseCase.executeGetForYouPost(
      isLoading: isLoading,
      page: _forYouCurrentPage,
      pageLimit: _forYouPageSize,
    );

    if (apiResult.isSuccess) {
      final postDataList = apiResult.data?.data as List<TimeLineData>;
      if (postDataList.isListEmptyOrNull) {
        _hasForYouMoreData = false;
      } else {
        if (isFromPagination) {
          _forYouPostList.addAll(postDataList);
        } else {
          _forYouPostList
            ..clear()
            ..addAll(postDataList);
        }
        if (onComplete != null) {
          onComplete(postDataList);
        }
        _forYouCurrentPage++;
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }
    _isForYouLoadingMore = false;
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
    add(GetTimeLinePostEvent(
      isLoading: false,
      isPagination: false,
      isRefresh: true,
      onComplete: (postList) {
        add(LoadPostsEvent(
          timeLinePostList: _timeLinePostList,
          trendingPosts: _timeLinePostList,
          forYouPosts: _forYouPostList,
        ));
      },
    ));
  }

  Future<void> _callGetTimeLinePost(
    bool isFromRefresh,
    bool isFromPagination,
    bool isLoading,
    Function(List<TimeLineData>)? onComplete,
  ) async {
    // For refresh, clear cache and start from page 0
    if (isFromRefresh) {
      _timeLinePostList.clear();
      _timeLineCurrentPage = 1;
      _hasMoreTimeLineData = true;
      _isTimeLineLoadingMore = false;
    } else if (!isFromPagination && _timeLinePostList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    }

    if (!isFromPagination) {
      _timeLineCurrentPage = 1;
      _hasMoreTimeLineData = true;
    } else if (_isTimeLineLoadingMore || !_hasMoreTimeLineData) {
      return;
    }

    _isTimeLineLoadingMore = true;

    final apiResult = await _getTimelinePostUseCase.executeTimeLinePost(
      isLoading: isLoading,
      page: _timeLineCurrentPage,
      pageLimit: _timeLinePageSize,
    );

    if (apiResult.isSuccess) {
      final postDataList = apiResult.data?.data as List<TimeLineData>;
      try {
        final newPosts = postDataList
            .map((postData) => TimeLineData.fromMap(postData.toMap()))
            .toList(); // Updated line
        if (newPosts.length < _timeLinePageSize) {
          _hasMoreTimeLineData = false;
        }

        if (isFromPagination) {
          _timeLinePostList.addAll(postDataList);
        } else {
          _timeLinePostList
            ..clear()
            ..addAll(postDataList);
        }

        if (onComplete != null) {
          onComplete(newPosts);
        }

        _timeLineCurrentPage++;
      } catch (e, stackTrace) {
        AppLog.error('Error logged: $e', stackTrace);
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isTimeLineLoadingMore = false;
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
    final apiResult = await _getPostCommentUseCase.executeGetPostComment(
      postId: event.postId,
      isLoading: false,
    );
    final postCommentsList = apiResult.data?.data;
    final myUserId = await _localDataUseCase.getUserId();
    emit(LoadPostCommentState(
      postCommentsList: postCommentsList,
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
    );
    final apiResult = await _commentUseCase.executeCommentAction(
      isLoading: true,
      commentRequest: commentRequest.toJson(),
    );
    if (apiResult.isSuccess) {
      if (event.commentAction == CommentAction.comment) {
        add(GetPostCommentsEvent(
          postId: event.postId ?? '',
          isLoading: true,
        ));
      } else {
        if (event.commentAction == CommentAction.report) {
          ErrorHandler.showAppError(
            appError: apiResult.error,
            message: IsrTranslationFile.commentReportedSuccessfully,
            isNeedToShowError: true,
            errorViewType: ErrorViewType.snackBar,
          );
        }
      }
    } else {
      ErrorHandler.showAppError(
        appError: apiResult.error,
        isNeedToShowError: true,
        errorViewType: ErrorViewType.dialog,
      );
    }
    if (event.onComplete != null) {
      event.onComplete?.call(event.commentId ?? '', apiResult.isSuccess);
    }
  }

  FutureOr<void> _loadPosts(
      LoadPostsEvent event, Emitter<SocialPostState> emit) async {
    final myUserId = await _localDataUseCase.getUserId();
    emit(SocialPostLoadedState(
      timeLinePosts: event.timeLinePostList,
      trendingPosts: event.trendingPosts,
      forYouPosts: event.forYouPosts,
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
}
