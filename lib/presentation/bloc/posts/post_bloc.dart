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
    this._createPostUseCase,
  ) : super(PostInitial(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<GetFollowingPostEvent>(_getFollowingPost);
    on<CreatePostEvent>(_createPost);
    on<CameraEvent>(_goToCamera);
  }

  final LocalDataUseCase _localDataUseCase;
  final GetFollowingPostUseCase _getFollowingPostUseCase;
  final CreatePostUseCase _createPostUseCase;
  final List<PostData> _followingPostList = [];
  var reelsPageFollowingController = PageController();
  UserInfoClass? _userInfoClass;
  var reelsPageTrendingController = PageController();

  void _onStartPost(StartPost event, Emitter<PostState> emit) async {
    final userInfoString = await _localDataUseCase.getUserInfo();
    if (userInfoString.isEmptyOrNull == false) {
      _userInfoClass = UserInfoClass.fromJson(jsonDecode(userInfoString) as Map<String, dynamic>);
      emit(UserInformationLoaded(userInfoClass: _userInfoClass));
    }
    add(GetFollowingPostEvent(isLoading: false));
  }

  FutureOr<void> _getFollowingPost(GetFollowingPostEvent event, Emitter<PostState> emit) async {
    final apiResult = await _getFollowingPostUseCase.executeGetFollowingPost(isLoading: event.isLoading);
    _followingPostList.clear();
    if (apiResult.isSuccess) {
      _followingPostList.addAll(apiResult.data?.data as Iterable<PostData>);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }
    emit(PostDataLoadedState(postDataList: _followingPostList));
  }

  FutureOr<void> _goToCamera(CameraEvent event, Emitter<PostState> emit) async {
    final result = await InjectionUtils.getRouteManagement().goToCameraView();
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
        final trimmedVideoThumbnailBytes = await File(trimmedVideoThumbnailPath).readAsBytes();
        postAttributeClass.thumbnailUrl = trimmedVideoThumbnailPath;
        postAttributeClass.thumbnailBytes = trimmedVideoThumbnailBytes;
        postAttributeClass.duration = result['duration'] as int? ?? 0;
        postAttributeClass.postType = mediaType;
      }
      if (mediaSource != null && mediaSource == MediaSource.gallery && mediaType == PostType.video) {
        postAttributeClass =
            await InjectionUtils.getRouteManagement().goToVideoTrimView(postAttributeClass: postAttributeClass);
        if (postAttributeClass != null) {
          InjectionUtils.getRouteManagement().goToPostAttributeView(postAttributeClass: postAttributeClass);
        }
      } else {
        InjectionUtils.getRouteManagement().goToPostAttributeView(postAttributeClass: postAttributeClass);
      }
    }
  }

  FutureOr<void> _createPost(CreatePostEvent event, Emitter<PostState> emit) async {
    final apiResult = await _createPostUseCase.executeCreatePost(
      isLoading: true,
      createPostRequest: event.createPostRequest?.toJson(),
    );
    if (apiResult.isSuccess) {
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }
}
