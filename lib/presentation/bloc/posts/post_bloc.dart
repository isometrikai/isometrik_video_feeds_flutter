import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:path/path.dart' as path;
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
    this._reportPostUseCase,
    this._getReportReasonsUseCase,
    this._getCloudDetailsUseCase,
  ) : super(PostInitial(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<GetFollowingPostEvent>(_getFollowingPost);
    on<GetTrendingPostEvent>(_getTrendingPost);
    on<CreatePostEvent>(_createPost);
    on<MediaSourceEvent>(_openMediaSource);
    on<FollowUserEvent>(_followUser);
    on<SavePostEvent>(_savePost);
    on<LikePostEvent>(_likePost);
    on<ReportPostEvent>(_reportPost);
    on<GetReasonEvent>(_getReason);
  }

  final LocalDataUseCase _localDataUseCase;
  final GetFollowingPostUseCase _getFollowingPostUseCase;
  final GetTrendingPostUseCase _getTrendingPostUseCase;
  final CreatePostUseCase _createPostUseCase;
  final FollowPostUseCase _followPostUseCase;
  final SavePostUseCase _savePostUseCase;
  final LikePostUseCase _likePostUseCase;
  final ReportPostUseCase _reportPostUseCase;
  final GetReportReasonsUseCase _getReportReasonsUseCase;
  final GetCloudDetailsUseCase _getCloudDetailsUseCase;

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
  CloudDetailsData? cloudDetailsData;
  TextEditingController? descriptionController;
  final _createPostRequest = CreatePostRequest();

  void _onStartPost(StartPost event, Emitter<PostState> emit) async {
    final userInfoString = await _localDataUseCase.getUserInfo();
    if (userInfoString.isEmptyOrNull == false) {
      _userInfoClass = UserInfoClass.fromJson(jsonDecode(userInfoString) as Map<String, dynamic>);
      emit(UserInformationLoaded(userInfoClass: _userInfoClass));
    }

    // Load initial posts without pagination
    add(GetFollowingPostEvent(isLoading: false, isPagination: false));
    add(GetTrendingPostEvent(isLoading: false, isPagination: false));
  }

  FutureOr<void> _getFollowingPost(GetFollowingPostEvent event, Emitter<PostState> emit) async {
    // For refresh, clear cache and start from page 0
    if (event.isRefresh) {
      _followingPostList.clear();
      _currentPage = 0;
      _hasMoreData = true;
      _isLoadingMore = false;
    } else if (!event.isPagination && _followingPostList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      emit(FollowingPostsLoadedState(followingPosts: _followingPostList));
    }

    if (!event.isPagination) {
      _currentPage = event.isRefresh ? 0 : 1;
      _hasMoreData = true;
    } else if (_isLoadingMore || !_hasMoreData) {
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
        _followingPostList
          ..clear()
          ..addAll(newPosts);
      }

      _currentPage++;
      emit(FollowingPostsLoadedState(followingPosts: _followingPostList));
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isLoadingMore = false;
  }

  FutureOr<void> _getTrendingPost(GetTrendingPostEvent event, Emitter<PostState> emit) async {
    // For refresh, clear cache and start from page 0
    if (event.isRefresh) {
      _trendingPostList.clear();
      _trendingCurrentPage = 0;
      _hasTrendingMoreData = true;
      _isTrendingLoadingMore = false;
    } else if (!event.isPagination && _trendingPostList.isNotEmpty) {
      // If we have cached posts and it's not a refresh, emit them immediately
      emit(TrendingPostsLoadedState(trendingPosts: _trendingPostList));
    }

    if (!event.isPagination) {
      _trendingCurrentPage = event.isRefresh ? 0 : 1;
      _hasTrendingMoreData = true;
    } else if (_isTrendingLoadingMore || !_hasTrendingMoreData) {
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
        if (event.isPagination) {
          _trendingPostList.addAll(newPosts);
        } else {
          _trendingPostList
            ..clear()
            ..addAll(newPosts);
        }
        _trendingCurrentPage++;
        emit(TrendingPostsLoadedState(trendingPosts: _trendingPostList));
      }
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }

    _isTrendingLoadingMore = false;
  }

  FutureOr<void> _openMediaSource(MediaSourceEvent event, Emitter<PostState> emit) async {
    MediaInfoClass? mediaInfoClass;
    if (event.mediaSource == MediaSource.camera) {
      mediaInfoClass =
          await InjectionUtils.getRouteManagement().goToCameraView(context: event.context, mediaType: event.mediaType);
    }
    if (event.mediaSource == MediaSource.gallery && event.context.mounted) {
      mediaInfoClass = await _pickFromGallery(event.context, event.mediaType, event.mediaSource);
    }
    if (mediaInfoClass != null) {
      final postAttributeClass = await _processMediaInfo(event.context, mediaInfoClass, emit);
      emit(
        event.isCoverImage
            ? CoverImageSelected(coverImage: postAttributeClass?.url)
            : MediaSelectedState(postAttributeClass: postAttributeClass),
      );
      if (cloudDetailsData == null) {
        await _getCloudDetails();
      }
      if (cloudDetailsData == null) return;
      if (event.isCoverImage) {
        final fileName = _getFileName(postAttributeClass?.coverImage, 'thumbnail');
        _createPostRequest.thumbnailUrl =
            await _uploadImageToCloud(postAttributeClass?.coverImage, fileName, emit, true);
      } else {
        final fileName =
            _getFileName(postAttributeClass?.url, postAttributeClass?.postType == MediaType.photo ? 'photo' : 'video');
        _createPostRequest.fileName = fileName;
        if (postAttributeClass?.postType == MediaType.photo) {
          _createPostRequest.imageUrl = await _uploadImageToCloud(postAttributeClass?.url, fileName, emit, false);
          _createPostRequest.thumbnailUrl = _createPostRequest.imageUrl;
          if (_createPostRequest.thumbnailUrl?.contains('media_') == true) {
            _createPostRequest.thumbnailUrl = _createPostRequest.thumbnailUrl!.replaceAll('photo_', 'thumbnail_');
          }
        } else {
          _createPostRequest.url = await _uploadImageToCloud(postAttributeClass?.url, fileName, emit, false);
          final coverFileName = _getFileName(postAttributeClass?.thumbnailUrl, 'thumbnail');
          _createPostRequest.thumbnailUrl =
              await _uploadImageToCloud(postAttributeClass?.thumbnailUrl, coverFileName, emit, true);
        }
        _createPostRequest.mediaType = postAttributeClass?.postType?.mediaType;
        _createPostRequest.duration = postAttributeClass?.duration;
        _createPostRequest.description = descriptionController?.text;
        _createPostRequest.cloudinaryPublicId = cloudDetailsData?.publicId;
        _createPostRequest.size = postAttributeClass?.size;
      }
    }

    debugPrint('createPostRequest: ${_createPostRequest.toJson()}');
  }

  // Add this method in _CameraViewState
  Future<MediaInfoClass?> _pickFromGallery(BuildContext context, MediaType mediaType, MediaSource mediaSource) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      if (mediaType == MediaType.video) {
        file = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 30),
        );
      } else if (mediaType == MediaType.photo) {
        file = await picker.pickImage(
          source: ImageSource.gallery,
        );
      }

      if (file != null && file.path.isEmptyOrNull == false) {
        debugPrint('Selected media path: ${file.path}');
        final mediaInfoClass = MediaInfoClass(
          duration: 0,
          mediaType: mediaType,
          mediaSource: mediaSource,
          mediaFile: file,
        );
        return mediaInfoClass;
      }
    } catch (e) {
      if (context.mounted) {
        IsrVideoReelUtility.showInSnackBar('Error picking video from gallery', context);
      }
      debugPrint('Error picking video: $e');
    }
    return null;
  }

  FutureOr<PostAttributeClass?> _processMediaInfo(
      BuildContext context, MediaInfoClass mediaInfoClass, Emitter<PostState> emit) async {
    PostAttributeClass? postAttributeClass = PostAttributeClass();
    final mediaType = mediaInfoClass.mediaType;
    final mediaFile = mediaInfoClass.mediaFile;

    if (mediaFile?.path.isEmptyOrNull == false) {
      postAttributeClass.file = File(mediaFile?.path ?? '');
      postAttributeClass.size = postAttributeClass.file?.lengthSync();
      postAttributeClass.url = mediaFile?.path;
      postAttributeClass.coverImage = mediaFile?.path;

      if (postAttributeClass.file == null || postAttributeClass.file?.path.isEmptyOrNull == true) return null;

      postAttributeClass.duration = mediaInfoClass.duration;
      postAttributeClass.postType = mediaType;

      if (mediaType == MediaType.video) {
        final trimmedVideoThumbnailPath = await VideoThumbnail.thumbnailFile(
              video: postAttributeClass.file?.path ?? '',
              imageFormat: ImageFormat.PNG,
              quality: 50,
              thumbnailPath: (await getTemporaryDirectory()).path,
            ) ??
            '';
        if (trimmedVideoThumbnailPath.isEmpty) return null;
        final trimmedVideoThumbnailBytes = await File(trimmedVideoThumbnailPath).readAsBytes();
        postAttributeClass.thumbnailUrl = trimmedVideoThumbnailPath;
        postAttributeClass.coverImage = trimmedVideoThumbnailPath;
        postAttributeClass.thumbnailBytes = trimmedVideoThumbnailBytes;
        // if (context.mounted) {
        //   postAttributeClass = await InjectionUtils.getRouteManagement()
        //       .goToVideoTrimView(context: context, postAttributeClass: postAttributeClass);
        // }
      }
    }
    return postAttributeClass;
  }

  FutureOr<void> _createPost(CreatePostEvent event, Emitter<PostState> emit) async {
    _createPostRequest.description = descriptionController?.text;
    if (_createPostRequest.imageUrl == null && _createPostRequest.url == null) {
      IsrVideoReelUtility.showAppError(message: 'Select a media file', errorViewType: ErrorViewType.toast);
      return;
    }
    if (_createPostRequest.thumbnailUrl.isEmptyOrNull == true) {
      IsrVideoReelUtility.showAppError(message: 'Select a cover', errorViewType: ErrorViewType.toast);
      return;
    }
    final apiResult = await _createPostUseCase.executeCreatePost(
      isLoading: true,
      createPostRequest: _createPostRequest.toJson(),
    );
    if (apiResult.isSuccess) {
      emit(PostCreatedState(postId: 'postId'));
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }

  FutureOr<void> _followUser(FollowUserEvent event, Emitter<PostState> emit) async {
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

  FutureOr<void> _reportPost(ReportPostEvent event, Emitter<PostState> emit) async {
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

  FutureOr<void> _getReason(GetReasonEvent event, Emitter<PostState> emit) async {
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

  Future<void> _getCloudDetails() async {
    final apiResult = await _getCloudDetailsUseCase.executeGetCloudDetails(
      key: 'folder',
      value: '${AppConstants.cloudinaryFolder}/${DateTime.now().millisecondsSinceEpoch}',
      isLoading: false,
    );
    if (apiResult.isSuccess) {
      cloudDetailsData = apiResult.data?.data;
    }
  }

  Future<String> _uploadImageToCloud(
      String? coverImage, String fileName, Emitter<PostState> emit, bool isCoverImage) async {
    var finalUrl = '';
    final cloudinary = CloudinaryHandler.getCloudinary(
      apiKey: cloudDetailsData?.apiKey ?? '',
      apiSecret: cloudDetailsData?.apiSecretKey ?? '',
      cloudName: cloudDetailsData?.cloudName ?? '',
    );

    if (cloudinary != null) {
      final response = await CloudinaryHandler.uploadMedia(
        cloudinary: cloudinary,
        file: File(coverImage!),
        fileName: fileName,
        cloudinaryCustomFolder: AppConstants.cloudinaryFolder,
        resourceType: CloudinaryResourceType.image,
        progressCallback: (count, total) {
          final progress = (count * 100) / total;
          emit(isCoverImage ? UploadingCoverImageState(progress) : UploadingMediaState(progress));
        },
      );
      if (response != null) {
        finalUrl = response.secureUrl ?? '';
        return finalUrl;
      }
    }
    return finalUrl;
  }

  String _getFileName(String? file, String fileType) {
    // Example local path
    // Example Output: cover-1615564937000-photo-2025.jpg

    // Extract the file name
    var fileName = path.basename(file!);

    // Get the current timestamp (in milliseconds)
    var timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Modify the file name (convert to lowercase and replace spaces with hyphens)
    var modifiedFileName = fileName.toLowerCase().replaceAll(' ', '-');

    // Combine the file type, timestamp, and modified file name
    var newFileName = '$fileType-$timestamp-$modifiedFileName';
    return newFileName;
  }
}
