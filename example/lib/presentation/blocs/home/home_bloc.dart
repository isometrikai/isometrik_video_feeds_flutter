import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._localDataUseCase,
    this._getFollowingPostUseCase,
    this._getTrendingPostUseCase,
    this._followPostUseCase,
    this._savePostUseCase,
    this._likePostUseCase,
    this._reportPostUseCase,
    this._getReportReasonsUseCase,
    this._getCloudDetailsUseCase,
  ) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<GetFollowingPostEvent>(_getFollowingPost);
    on<GetTrendingPostEvent>(_getTrendingPost);
    on<SavePostEvent>(_savePost);
    on<GetReasonEvent>(_getReason);
    on<ReportPostEvent>(_reportPost);
    on<LikePostEvent>(_likePost);
    on<FollowUserEvent>(_followUser);
  }

  final LocalDataUseCase _localDataUseCase;
  final GetFollowingPostUseCase _getFollowingPostUseCase;
  final GetTrendingPostUseCase _getTrendingPostUseCase;
  final FollowPostUseCase _followPostUseCase;
  final SavePostUseCase _savePostUseCase;
  final LikePostUseCase _likePostUseCase;
  final ReportPostUseCase _reportPostUseCase;
  final GetReportReasonsUseCase _getReportReasonsUseCase;
  final GetCloudDetailsUseCase _getCloudDetailsUseCase;

  final List<isr.PostDataModel> _followingPostList = [];
  final List<isr.PostDataModel> _trendingPostList = [];

  int _currentPage = 0;
  final _followingPageSize = 20;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  int _trendingCurrentPage = 0;
  bool _hasTrendingMoreData = true;
  bool _isTrendingLoadingMore = false;
  final _trendingPageSize = 20;

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading(isLoading: true));
      await _initializeReelsSdk();
      await Future.wait([
        _callGetFollowingPost(true, false, false),
        _callGetTrendingPost(true, false, false),
      ]);
      emit(HomeLoaded(
        followingPosts: _followingPostList,
        trendingPosts: _trendingPostList,
      ));
      // add(GetFollowingPostEvent(isLoading: false, isPagination: false, isRefresh: true));
      // add(GetTrendingPostEvent(isLoading: false, isPagination: false, isRefresh: true));
      // final listOfData = await getPostData();
      // emit(HomeLoaded(postData: listOfData));
    } catch (error) {
      emit(HomeError(error.toString()));
    }
  }

  Future<void> _initializeReelsSdk() async {
    final accessToken = await _localDataUseCase.getAccessToken();
    await isr.IsrVideoReelConfig.initializeSdk(
      baseUrl: AppUrl.appBaseUrl,
      postInfo: isr.PostInfoClass(
        accessToken: accessToken,
        userInformation: isr.UserInfoClass(
          userId: '37483783493',
          userName: 'asjad',
          firstName: 'Asjad',
          lastName: 'Ibrahim',
        ),
      ),
    );
  }

  FutureOr<void> _getFollowingPost(GetFollowingPostEvent event, Emitter<HomeState> emit) async {
    await _callGetFollowingPost(event.isRefresh, event.isPagination, false);
  }

  FutureOr<void> _getTrendingPost(GetTrendingPostEvent event, Emitter<HomeState> emit) async {
    await _callGetTrendingPost(event.isRefresh, event.isPagination, false);
  }

  Future<void> _callGetFollowingPost(bool isFromRefresh, bool isFromPagination, bool isLoading) async {
    // For refresh, clear cache and start from page 0
    if (isFromRefresh) {
      _followingPostList.clear();
      _currentPage = 0;
      _hasMoreData = true;
      _isLoadingMore = false;
    } else if (!isFromPagination && _followingPostList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    }

    if (!isFromPagination) {
      _currentPage = isFromRefresh ? 0 : 1;
      _hasMoreData = true;
    } else if (_isLoadingMore || !_hasMoreData) {
      return;
    }

    _isLoadingMore = true;

    final apiResult = await _getFollowingPostUseCase.executeGetFollowingPost(
      isLoading: isLoading,
      page: _currentPage,
      pageLimit: _followingPageSize,
    );

    if (apiResult.isSuccess) {
      final postDataList = apiResult.data?.data as List<PostData>;
      final newPosts =
          postDataList.map((postData) => isr.PostDataModel.fromJson(postData.toJson())).toList(); // Updated line
      if (newPosts.length < _followingPageSize) {
        _hasMoreData = false;
      }

      if (isFromPagination) {
        _followingPostList.addAll(newPosts);
      } else {
        _followingPostList
          ..clear()
          ..addAll(newPosts);
      }

      _currentPage++;
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isLoadingMore = false;
  }

  Future<void> _callGetTrendingPost(bool isFromRefresh, bool isFromPagination, bool isLoading) async {
    // For refresh, clear cache and start from page 0
    if (isFromRefresh) {
      _trendingPostList.clear();
      _trendingCurrentPage = 0;
      _hasTrendingMoreData = true;
      _isTrendingLoadingMore = false;
    } else if (!isFromPagination && _trendingPostList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
    }

    if (!isFromPagination) {
      _trendingCurrentPage = isFromRefresh ? 0 : 1;
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
      final postDataList = apiResult.data?.data as List<PostData>;
      final newPosts = postDataList.map((postData) => isr.PostDataModel.fromJson(postData.toJson())).toList();
      if (newPosts.isEmpty) {
        _hasTrendingMoreData = false;
      } else {
        if (isFromPagination) {
          _trendingPostList.addAll(newPosts);
        } else {
          _trendingPostList
            ..clear()
            ..addAll(newPosts);
        }
        _trendingCurrentPage++;
        // emit(HomeLoaded(followingPosts: _followingPostList, trendingPosts: _trendingPostList));
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isTrendingLoadingMore = false;
  }

  FutureOr<void> _savePost(SavePostEvent event, Emitter<HomeState> emit) async {
    final apiResult = await _savePostUseCase.executeSavePost(
      isLoading: false,
      postId: event.postId,
    );

    if (apiResult.isSuccess) {
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }

  FutureOr<void> _getReason(GetReasonEvent event, Emitter<HomeState> emit) async {
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

  FutureOr<void> _reportPost(ReportPostEvent event, Emitter<HomeState> emit) async {
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

  FutureOr<void> _likePost(LikePostEvent event, Emitter<HomeState> emit) async {
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

  FutureOr<void> _followUser(FollowUserEvent event, Emitter<HomeState> emit) async {
    final apiResult = await _followPostUseCase.executeFollowPost(
      isLoading: false,
      followingId: event.followingId,
    );

    if (apiResult.isSuccess) {
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }

// Future<void> _getCloudDetails() async {
//   final apiResult = await _getCloudDetailsUseCase.executeGetCloudDetails(
//     key: 'folder',
//     value: '${AppConstants.cloudinaryFolder}/${DateTime.now().millisecondsSinceEpoch}',
//     isLoading: false,
//   );
//   if (apiResult.isSuccess) {
//     cloudDetailsData = apiResult.data?.data;
//   }
// }
}
