import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc(
    this._localDataUseCase,
    this._getFollowingPostUseCase,
    this._getTrendingPostUseCase,
    this._createPostUseCase,
    this._followPostUseCase,
    this._savePostUseCase,
    this._likePostUseCase,
  ) : super(PostInitial(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<GetFollowingPostEvent>(_getFollowingPost);
    on<GetTrendingPostEvent>(_getTrendingPost);
    on<CreatePostEvent>(_createPost);
    on<CameraEvent>(_goToCamera);
    on<FollowUserEvent>(_followUser);
    on<SavePostEvent>(_savePost);
    on<LikePostEvent>(_likePost);
  }

  final LocalDataUseCase _localDataUseCase;
  final GetFollowingPostUseCase _getFollowingPostUseCase;
  final GetTrendingPostUseCase _getTrendingPostUseCase;
  final CreatePostUseCase _createPostUseCase;
  final FollowPostUseCase _followPostUseCase;
  final SavePostUseCase _savePostUseCase;
  final LikePostUseCase _likePostUseCase;
  final List<PostData> _followingPostList = [];
  final List<PostData> _trendingPostList = [];
  var reelsPageFollowingController = PageController();
  UserInfoClass? _userInfoClass;
  var reelsPageTrendingController = PageController();
  int _currentPage = 0;
  final _pageSize = 20;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  int _trendingCurrentPage = 0;
  bool _hasTrendingMoreData = true;
  bool _isTrendingLoadingMore = false;
  final _trendingPageSize = 20;

  void _onStartPost(StartPost event, Emitter<PostState> emit) async {
    final userInfoString = await _localDataUseCase.getUserInfo();
    if (userInfoString.isEmptyOrNull == false) {
      _userInfoClass = UserInfoClass.fromJson(
          jsonDecode(userInfoString) as Map<String, dynamic>);
      emit(UserInformationLoaded(userInfoClass: _userInfoClass));
    }
    add(GetFollowingPostEvent(isLoading: false, isPagination: false));
    add(GetTrendingPostEvent(isLoading: false, isPagination: false));
  }

  FutureOr<void> _getFollowingPost(
      GetFollowingPostEvent event, Emitter<PostState> emit) async {
    if (!event.isPagination) {
      _currentPage = 0;
      _hasMoreData = true;
      _followingPostList.clear();
    }

    if (event.isPagination && (_isLoadingMore || !_hasMoreData)) {
      return;
    }

    _isLoadingMore = true;

    final apiResult = await _getFollowingPostUseCase.executeGetFollowingPost(
      isLoading: event.isLoading,
      page: _currentPage,
      pageLimit: _pageSize,
    );

    if (apiResult.isSuccess) {
      final newPosts = apiResult.data?.data as List<PostData>;

      if (newPosts.length < _pageSize) {
        _hasMoreData = false;
      }

      if (event.isPagination) {
        _followingPostList.addAll(newPosts);
      } else {
        _followingPostList.clear();
        _followingPostList.addAll(newPosts);
      }

      _currentPage++;
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isLoadingMore = false;
    emit(FollowingPostsLoadedState(followingPosts: _followingPostList));
  }

  FutureOr<void> _getTrendingPost(
      GetTrendingPostEvent event, Emitter<PostState> emit) async {
    if (!event.isPagination) {
      _trendingCurrentPage = 0;
      _hasTrendingMoreData = true;
      _trendingPostList.clear();
    }

    if (event.isPagination &&
        (_isTrendingLoadingMore || !_hasTrendingMoreData)) {
      return;
    }

    _isTrendingLoadingMore = true;

    final apiResult = await _getTrendingPostUseCase.executeGetTrendingPost(
      isLoading: event.isLoading,
      page: _trendingCurrentPage,
      pageLimit: _trendingPageSize,
    );

    if (apiResult.isSuccess) {
      final newPosts = apiResult.data?.data as List<PostData>;
      if (newPosts.isEmpty) {
        _hasTrendingMoreData = false;
      } else {
        _trendingCurrentPage++;
        if (event.isPagination) {
          _trendingPostList.addAll(newPosts);
        } else {
          _trendingPostList.clear();
          _trendingPostList.addAll(newPosts);
        }
        emit(TrendingPostsLoadedState(trendingPosts: _trendingPostList));
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isTrendingLoadingMore = false;
  }

  FutureOr<void> _goToCamera(CameraEvent event, Emitter<PostState> emit) async {
    final result = await InjectionUtils.getRouteManagement()
        .goToCameraView(context: event.context);
    PostAttributeClass? postAttributeClass = PostAttributeClass();
    if (result != null) {
      final mediaSource = result['mediaSource'] as MediaSource?;
      final mediaType = result['mediaType'] as PostType?;
      final mediaFile = result['mediaFile'] as XFile?;
      if (mediaFile?.path.isEmptyOrNull == false) {
        postAttributeClass.file = File(mediaFile?.path ?? '');
        postAttributeClass.url = mediaFile?.path;
        if (postAttributeClass.file == null) return;
        if (postAttributeClass.file?.path == null) return;
        if (postAttributeClass.file?.path.isEmpty == true) return;
        final trimmedVideoThumbnailPath = await VideoThumbnail.thumbnailFile(
              video: postAttributeClass.file?.path ?? '',
              imageFormat: ImageFormat.PNG,
              quality: 50,
              thumbnailPath: (await getTemporaryDirectory()).path,
            ) ??
            '';
        if (trimmedVideoThumbnailPath.isEmpty) return;
        final trimmedVideoThumbnailBytes =
            await File(trimmedVideoThumbnailPath).readAsBytes();
        postAttributeClass.thumbnailUrl = trimmedVideoThumbnailPath;
        postAttributeClass.thumbnailBytes = trimmedVideoThumbnailBytes;
        postAttributeClass.duration = result['duration'] as int? ?? 0;
        postAttributeClass.postType = mediaType;
      }
      if (event.context.mounted) {
        if (mediaSource != null &&
            mediaSource == MediaSource.gallery &&
            mediaType == PostType.video) {
          postAttributeClass = await InjectionUtils.getRouteManagement()
              .goToVideoTrimView(
                  context: event.context,
                  postAttributeClass: postAttributeClass);
          if (postAttributeClass != null && event.context.mounted) {
            InjectionUtils.getRouteManagement().goToPostAttributeView(
                context: event.context, postAttributeClass: postAttributeClass);
          }
        } else {
          InjectionUtils.getRouteManagement().goToPostAttributeView(
              context: event.context, postAttributeClass: postAttributeClass);
        }
      }
    }
  }

  FutureOr<void> _createPost(
      CreatePostEvent event, Emitter<PostState> emit) async {
    final apiResult = await _createPostUseCase.executeCreatePost(
      isLoading: true,
      createPostRequest: event.createPostRequest?.toJson(),
    );
    if (apiResult.isSuccess) {
    } else {
      ErrorHandler.showAppError(
          appError: apiResult.error, isNeedToShowError: true);
    }
  }

  FutureOr<void> _followUser(
      FollowUserEvent event, Emitter<PostState> emit) async {
    final apiResult = await _followPostUseCase.executeFollowPost(
      isLoading: false,
      followingId: event.followingId,
    );

    if (apiResult.isSuccess) {
      emit(FollowSuccessState(userId: event.followingId));
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }

  FutureOr<void> _savePost(SavePostEvent event, Emitter<PostState> emit) async {
    final apiResult = await _savePostUseCase.executeSavePost(
      isLoading: false,
      postId: event.postId,
    );

    if (apiResult.isSuccess) {
      emit(SavePostSuccessState(postId: event.postId));
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }

  FutureOr<void> _likePost(LikePostEvent event, Emitter<PostState> emit) async {
    final apiResult = await _likePostUseCase.executeLikePost(
      isLoading: false,
      postId: event.postId,
      userId: event.userId,
      likeAction: event.likeAction,
    );

    if (apiResult.isSuccess) {
      emit(LikeSuccessState(
        postId: event.postId,
        likeAction: event.likeAction,
      ));
      event.onComplete.call(true);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
      event.onComplete.call(false);
    }
  }
}
