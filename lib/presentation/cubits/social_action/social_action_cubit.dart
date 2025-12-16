import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

part 'social_action_state.dart';

class IsmSocialActionCubit extends Cubit<IsmSocialActionState> {
  IsmSocialActionCubit._() : super(IsmSocialActionState());
  static IsmSocialActionCubit? _instance;

  static IsmSocialActionCubit instance() {
    if (_instance == null || _instance!.isClosed) {
      _instance = IsmSocialActionCubit._();
    }
    return _instance!;
  }

  final FollowUnFollowUserUseCase _followPostUseCase =
      IsmInjectionUtils.getUseCase<FollowUnFollowUserUseCase>();
  final GetPostDetailsUseCase _getPostDetailsUseCase =
      IsmInjectionUtils.getUseCase<GetPostDetailsUseCase>();
  final SocialUserProfileUseCase _socialUserProfileUseCase =
      IsmInjectionUtils.getUseCase<SocialUserProfileUseCase>();
  final LikePostUseCase _likePostUseCase =
      IsmInjectionUtils.getUseCase<LikePostUseCase>();
  final SavePostUseCase _savePostUseCase =
      IsmInjectionUtils.getUseCase<SavePostUseCase>();

  final _uniquePostList = <String, TimeLineData>{};

  updatePostList(List<TimeLineData> postList) {
    for (var element in postList) {
      if (element.id != null) {
        _uniquePostList[element.id!] = element;
      }
    }
  }

  TimeLineData? getPostById(String postId) => _uniquePostList[postId];

  List<TimeLineData> getPostList({bool Function(TimeLineData)? filter}) =>
      filter != null
          ? _uniquePostList.values.where(filter).toList()
          : _uniquePostList.values.toList();

  Future<TimeLineData?> getAsyncPostById(String postId) async =>
      _uniquePostList[postId] ?? await _getPostDetails(postId);

  Future<TimeLineData?> _getPostDetails(String postId,
      {bool showError = false}) async {
    final result = await _getPostDetailsUseCase.executeGetPostDetails(
      isLoading: false,
      postId: postId,
    );

    final postData = result.data;

    if (postData != null) {
      updatePostList([postData]);
    }
    if (result.isError && showError) {
      ErrorHandler.showAppError(
          appError: result.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }

    return postData;
  }

  Future<SocialUserProfileData?> _getSocialUserDetails(String userId,
      {bool showError = false}) async {
    final result = await _socialUserProfileUseCase.executeSearchUser(
      isLoading: false,
      userId: userId,
    );

    final userData = result.data?.data;

    if (result.isError && showError) {
      ErrorHandler.showAppError(
          appError: result.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast);
    }

    return userData;
  }

  loadPostFollowState(String postId) async {
    final postData = await getAsyncPostById(postId);
    final isFollow = postData?.isFollowing ?? false;
    final userId = postData?.userId ?? '';
    emit(IsmFollowUserState(isFollowing: isFollow, userId: userId));
  }

  loadFollowState(String userId,
      {bool? isFollowing, bool callApi = false}) async {
    if (callApi && userId.isNotEmpty) {
      emit(IsmFollowUserState(
          isFollowing: isFollowing == true, userId: userId, isLoading: true));
      final userData = await _getSocialUserDetails(userId, showError: true);
      final apiFollowStatue = userData?.isFollowing ?? isFollowing ?? false;
      emit(IsmFollowUserState(isFollowing: apiFollowStatue, userId: userId));
    } else {
      emit(
          IsmFollowUserState(isFollowing: isFollowing == true, userId: userId));
    }
  }

  followUser(
    String userId, {
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    debugPrint('IsmSocialActionCubit hashCode -> $hashCode');

    try {
      emit(IsmFollowUserState(
          isFollowing: true, isLoading: true, userId: userId));

      final bool isSuccess;
      AppError? error;

      if (apiCallBack != null) {
        isSuccess = await apiCallBack();
      } else {
        final apiResult = await _followPostUseCase.executeFollowUser(
          isLoading: false,
          followingId: userId,
          followAction: FollowAction.follow,
        );
        isSuccess = apiResult.isSuccess;
        error = apiResult.error;
      }

      if (isSuccess) {
        emit(IsmFollowUserState(isFollowing: true, userId: userId));
        _uniquePostList.values
            .where((e) => e.userId == userId)
            .forEach((e) => e.isFollowing = true);

        emit(IsmFollowActionListenerState(isFollowing: true, userId: userId));

        _logFollowEvent(
          FollowAction.follow,
          reelsData: reelData,
          watchDuration: watchDuration,
          postSectionType: postSectionType,
        );
      } else {
        // Emit error state first, then revert UI state
        final errorMessage =
            error?.message ?? 'Failed to follow user. Please try again.';
        emit(IsmFollowErrorState(
          userId: userId,
          errorMessage: errorMessage,
          wasFollowing: false,
        ));

        // Revert to previous state after error
        emit(IsmFollowUserState(isFollowing: false, userId: userId));

        // Show error to user - always show, not just NetworkError
        ErrorHandler.showAppError(
          appError: error,
          message: errorMessage,
          isNeedToShowError: true, // ✅ Always show error!
        );
      }
    } catch (e, stackTrace) {
      // Catch unexpected exceptions
      debugPrint('❌ Unexpected error in followUser: $e');
      debugPrint('   Stack trace: $stackTrace');

      final errorMessage = 'An unexpected error occurred. Please try again.';
      emit(IsmFollowErrorState(
        userId: userId,
        errorMessage: errorMessage,
        wasFollowing: false,
      ));

      // Revert state
      emit(IsmFollowUserState(isFollowing: false, userId: userId));

      // Show error
      ErrorHandler.showAppError(
        appError: null,
        message: errorMessage,
        isNeedToShowError: true,
      );
    }
  }

  unfollowUser(
    String userId, {
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    debugPrint('IsmSocialActionCubit hashCode -> $hashCode');

    try {
      emit(IsmFollowUserState(
          isFollowing: false, isLoading: true, userId: userId));

      final bool isSuccess;
      AppError? error;

      if (apiCallBack != null) {
        isSuccess = await apiCallBack();
      } else {
        final apiResult = await _followPostUseCase.executeFollowUser(
          isLoading: false,
          followingId: userId,
          followAction: FollowAction.unfollow,
        );
        isSuccess = apiResult.isSuccess;
        error = apiResult.error;
      }

      if (isSuccess) {
        emit(IsmFollowUserState(isFollowing: false, userId: userId));
        _uniquePostList.values
            .where((e) => e.userId == userId)
            .forEach((e) => e.isFollowing = false);

        emit(IsmFollowActionListenerState(isFollowing: false, userId: userId));

        _logFollowEvent(
          FollowAction.unfollow,
          reelsData: reelData,
          watchDuration: watchDuration,
          postSectionType: postSectionType,
        );
      } else {
        // Emit error state first, then revert UI state
        final errorMessage =
            error?.message ?? 'Failed to unfollow user. Please try again.';
        emit(IsmFollowErrorState(
          userId: userId,
          errorMessage: errorMessage,
          wasFollowing: true,
        ));

        // Revert to previous state after error
        emit(IsmFollowUserState(isFollowing: true, userId: userId));

        // Show error to user - always show, not just NetworkError
        ErrorHandler.showAppError(
          appError: error,
          message: errorMessage,
          isNeedToShowError: true, // ✅ Always show error!
        );
      }
    } catch (e, stackTrace) {
      // Catch unexpected exceptions
      debugPrint('❌ Unexpected error in unfollowUser: $e');
      debugPrint('   Stack trace: $stackTrace');

      final errorMessage = 'An unexpected error occurred. Please try again.';
      emit(IsmFollowErrorState(
        userId: userId,
        errorMessage: errorMessage,
        wasFollowing: true,
      ));

      // Revert state
      emit(IsmFollowUserState(isFollowing: true, userId: userId));

      // Show error
      ErrorHandler.showAppError(
        appError: null,
        message: errorMessage,
        isNeedToShowError: true,
      );
    }
  }

  loadPostLikeState(String postId) async {
    final postData = await getAsyncPostById(postId);
    final isLiked = postData?.isLiked ?? false;
    final _likeCount =
        postData?.engagementMetrics?.likeTypes?.love?.toInt() ?? 0;
    debugPrint(
        'IsmSocialActionCubit: likeState , like: ${postData?.isLiked}, count ${postData?.engagementMetrics?.likeTypes?.love}');
    emit(IsmLikePostState(
        isLiked: isLiked, likeCount: max(_likeCount, 0), postId: postId));
  }

  likePost(
    String postId,
    int _likeCount, {
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    final likeCount = max(_likeCount, 0);

    emit(IsmLikePostState(
        isLiked: true, likeCount: likeCount, postId: postId, isLoading: true));

    final bool isSuccess;
    AppError? error;

    if (apiCallBack != null) {
      isSuccess = await apiCallBack();
    } else {
      final apiResult = await _likePostUseCase.executeLikePost(
        isLoading: false,
        postId: postId,
        likeAction: LikeAction.like,
      );
      isSuccess = apiResult.isSuccess;
      error = apiResult.error;
    }

    if (isSuccess) {
      final successLikeCount = likeCount + 1;

      emit(IsmLikePostState(
          isLiked: true, postId: postId, likeCount: successLikeCount));

      final post = await getAsyncPostById(postId);
      post?.isLiked = true;
      post?.engagementMetrics?.likeTypes?.love = successLikeCount;

      emit(IsmLikeActionListenerState(
          isLiked: true,
          postId: postId,
          postData: post,
          likeCount: successLikeCount));

      _logLikeEvent(
        LikeAction.like,
        reelsData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
      );
    } else {
      emit(IsmLikePostState(
          isLiked: false, postId: postId, likeCount: likeCount));
      ErrorHandler.showAppError(appError: error);
    }
  }

  unLikePost(
    String postId,
    int _likeCount, {
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    final likeCount = max(_likeCount, 0);

    emit(IsmLikePostState(
        isLiked: false, likeCount: likeCount, postId: postId, isLoading: true));

    final bool isSuccess;
    AppError? error;

    if (apiCallBack != null) {
      isSuccess = await apiCallBack();
    } else {
      final apiResult = await _likePostUseCase.executeLikePost(
        isLoading: false,
        postId: postId,
        likeAction: LikeAction.unlike,
      );
      isSuccess = apiResult.isSuccess;
      error = apiResult.error;
    }

    if (isSuccess) {
      final successLikeCount = max(0, likeCount - 1);

      emit(IsmLikePostState(
          isLiked: false, postId: postId, likeCount: successLikeCount));

      final post = await getAsyncPostById(postId);
      post?.isLiked = false;
      post?.engagementMetrics?.likeTypes?.love = successLikeCount;

      emit(IsmLikeActionListenerState(
          isLiked: false,
          postId: postId,
          postData: post,
          likeCount: successLikeCount));

      _logLikeEvent(
        LikeAction.unlike,
        reelsData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
      );
    } else {
      emit(IsmLikePostState(
          isLiked: true, postId: postId, likeCount: likeCount));
      ErrorHandler.showAppError(appError: error);
    }
  }

  loadPostSaveState(String postId) async {
    final postData = await getAsyncPostById(postId);
    final isSaved = postData?.isSaved ?? false;
    emit(IsmSavePostState(isSaved: isSaved, postId: postId));
  }

  Future<bool> savePost(
    String postId, {
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    emit(IsmSavePostState(
      isSaved: true,
      postId: postId,
      isLoading: true,
    ));

    final bool isSuccess;
    AppError? error;

    if (apiCallBack != null && reelData != null) {
      isSuccess = await apiCallBack();
    } else {
      final apiResult = await _savePostUseCase.executeSavePost(
        isLoading: false,
        postId: postId,
        socialPostAction: SocialPostAction.save,
      );
      isSuccess = apiResult.isSuccess;
      error = apiResult.error;
    }

    if (isSuccess) {
      emit(IsmSavePostState(
          isSaved: true, postId: postId)); // update widget state

      final post = await getAsyncPostById(postId);
      post?.isSaved = true;
      emit(IsmSaveActionListenerState(
        isSaved: true,
        postId: postId,
        postData: post,
      ));

      _logSaveEvent(
        SaveAction.save,
        reelsData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
      );
    } else {
      emit(IsmSavePostState(isSaved: false, postId: postId));
      ErrorHandler.showAppError(appError: error);
    }
    return isSuccess;
  }

  Future<bool> unSavePost(
    String postId, {
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  }) async {
    emit(IsmSavePostState(
      isSaved: false,
      postId: postId,
      isLoading: true,
    ));

    final bool isSuccess;
    AppError? error;

    if (apiCallBack != null) {
      isSuccess = await apiCallBack();
    } else {
      final apiResult = await _savePostUseCase.executeSavePost(
        isLoading: false,
        postId: postId,
        socialPostAction: SocialPostAction.unSave,
      );
      isSuccess = apiResult.isSuccess;
      error = apiResult.error;
    }

    if (isSuccess) {
      emit(IsmSavePostState(
          isSaved: false, postId: postId)); // update widget state

      final post = await getAsyncPostById(postId);
      post?.isSaved = false;
      emit(IsmSaveActionListenerState(
        isSaved: false,
        postId: postId,
        postData: post,
      ));

      _logSaveEvent(
        SaveAction.unsave,
        reelsData: reelData,
        watchDuration: watchDuration,
        postSectionType: postSectionType,
      );
    } else {
      emit(IsmSavePostState(isSaved: true, postId: postId));
      ErrorHandler.showAppError(appError: error);
    }
    return isSuccess;
  }

  void onPostCreated({String? postId, TimeLineData? postData}) {
    debugPrint(
        'IsmSocialActionCubit onPostCreated -> postId: $postId, postData: ${postData?.toMap()}');
    emit(IsmCreatePostActionListenerState(postData: postData, postId: postId));
  }

  void onPostEdited({String? postId, TimeLineData? postData}) {
    debugPrint(
        'IsmSocialActionCubit onPostEdited -> postId: $postId, postData: ${postData?.toMap()}');
    emit(IsmEditPostActionListenerState(postData: postData, postId: postId));
  }

  void onPostDeleted({String? postId}) {
    debugPrint('IsmSocialActionCubit onPostDeleted -> postId: $postId');
    emit(IsmDeletedPostActionListenerState(postId: postId));
    _uniquePostList.remove(postId);
  }

  void _logFollowEvent(
    FollowAction followAction, {
    ReelsData? reelsData,
    PostSectionType? postSectionType,
    int? watchDuration,
  }) {
    final eventMap = <String, dynamic>{
      'time_to_like_seconds': 1,
    };
    sendAnalyticsEvent(
      followAction == FollowAction.follow
          ? EventType.userFollowed.value
          : EventType.userUnFollowed.value,
      eventMap,
      reelsData: reelsData,
      postSectionType: postSectionType,
    );
  }

  void _logLikeEvent(
    LikeAction likeAction, {
    ReelsData? reelsData,
    PostSectionType? postSectionType,
    int? watchDuration,
  }) {
    final eventMap = <String, dynamic>{
      likeAction == LikeAction.like
          ? 'time_to_like_seconds'
          : 'time_to_unlike_seconds': watchDuration,
    };
    sendAnalyticsEvent(
      likeAction == LikeAction.unlike
          ? EventType.postUnliked.value
          : EventType.postLiked.value,
      eventMap,
      reelsData: reelsData,
      postSectionType: postSectionType,
    );
  }

  void _logSaveEvent(
    SaveAction saveAction, {
    ReelsData? reelsData,
    PostSectionType? postSectionType,
    int? watchDuration,
  }) {
    if (saveAction == SaveAction.save) {
      sendAnalyticsEvent(
        EventType.postSaved.value,
        {},
        reelsData: reelsData,
        postSectionType: postSectionType,
      );
    }
  }

  /// Implementation of PostHelperCallBacks interface
  /// This method is called by VideoPlayerWidget to send analytics events
  void sendAnalyticsEvent(
    String eventName,
    Map<String, dynamic> analyticsData, {
    ReelsData? reelsData,
    PostSectionType? postSectionType,
  }) async {
    try {
      // Prepare analytics event in the required format: "Post Viewed"
      final postViewedEvent = {
        'post_id': reelsData?.postId ?? '',
        'post_author_id': reelsData?.userId ?? '',
        'post_type': reelsData?.postData.as<TimeLineData>()?.type,
        'hashtags': reelsData?.tags?.hashtags?.isEmptyOrNull == false
            ? reelsData?.tags!.hashtags!.map((tag) => tag.tag).toList()
            : [],
        'interests': reelsData?.interests ?? [],
        'feed_type': postSectionType?.title ?? 'for_you',
      };
      final finalAnalyticsDataMap = {
        ...postViewedEvent,
        ...analyticsData,
      };

      unawaited(EventQueueProvider.instance
          .addEvent(eventName, finalAnalyticsDataMap.removeEmptyValues()));
    } catch (e) {
      debugPrint('❌ Error sending analytics event: $e');
      return null;
    }
  }
}
