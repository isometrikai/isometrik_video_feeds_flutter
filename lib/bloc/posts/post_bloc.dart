import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

part 'post_event.dart';
part 'post_state.dart';

@lazySingleton
class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc() : super(PostInitial()) {
    on<StartPost>(_onStartPost);
    on<GetFollowingPostEvent>(_getFollowingPost);
    on<CreatePostEvent>(_createPost);
    on<CameraEvent>(_goToCamera);
  }

  final List<PostData> _followingPostList = [];
  var reelsPageFollowingController = PageController();
  var _userProfilePic = '';
  var _userProfileName = '';
  var reelsPageTrendingController = PageController();
  final _postViewModel = kGetIt<PostViewModel>();

  void _onStartPost(StartPost event, Emitter<PostState> emit) async {
    _userProfilePic = '';
    _userProfileName = '';
  }

  FutureOr<void> _getFollowingPost(GetFollowingPostEvent event, Emitter<PostState> emit) async {
    final response = await _postViewModel.getFollowingPost(isLoading: event.isLoading);
    _followingPostList.clear();
    if (response != null) {
      _followingPostList.addAll(response.data as Iterable<PostData>);
    }
    emit(PostDataLoadedState(postDataList: _followingPostList));
  }

  String getProfileImageUrl() => _userProfilePic;

  String getProfileName() => _userProfileName;

  FutureOr<void> _goToCamera(CameraEvent event, Emitter<PostState> emit) async {
    final result = await RouteManagement.goToCameraView();
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
        postAttributeClass = await RouteManagement.goToVideoTrimView(postAttributeClass: postAttributeClass);
        if (postAttributeClass != null) {
          RouteManagement.goToNewPostView(postAttributeClass: postAttributeClass);
        }
      } else {
        RouteManagement.goToNewPostView(postAttributeClass: postAttributeClass);
      }
    }
  }

  FutureOr<void> _createPost(CreatePostEvent event, Emitter<PostState> emit) async {
    final response = await _postViewModel.createPost(
      isLoading: true,
      createPostRequest: event.createPostRequest?.toJson(),
    );
    if (response != null) {}
  }
}
