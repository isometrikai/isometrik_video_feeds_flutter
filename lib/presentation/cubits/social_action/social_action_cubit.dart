import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

part 'social_action_state.dart';

class IsmSocialActionCubit extends Cubit<IsmSocialActionState> {
  IsmSocialActionCubit(
    this._followPostUseCase,
    this._getPostDetailsUseCase,
    this._likePostUseCase,
  ) : super(IsmSocialActionState());

  final FollowUnFollowUserUseCase _followPostUseCase;
  final GetPostDetailsUseCase _getPostDetailsUseCase;
  final LikePostUseCase _likePostUseCase;

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

  loadPostFollowState({required String postId}) async {
    final postData = await getAsyncPostById(postId);
    final isFollow = postData?.isFollowing ?? false;
    final userId = postData?.userId ?? '';
    emit(IsmFollowUserState(isFollowing: isFollow, userId: userId));
  }

  followUser({required String userId}) async {
    emit(IsmFollowUserState(
        isFollowing: false, isLoading: true, userId: userId));
    final apiResult = await _followPostUseCase.executeFollowUser(
      isLoading: false,
      followingId: userId,
      followAction: FollowAction.follow,
    );
    if (apiResult.isSuccess) {
      emit(IsmFollowUserState(isFollowing: true, userId: userId)); // to update button/widget state
      _uniquePostList.values
          .where((e) => e.userId == userId)
          .forEach((element) {
        element.isFollowing = true;
      });
      emit(IsmFollowActionListenerState(
          isFollowing: true,
          userId: userId)); // on api success to invoke listener
    } else {
      emit(IsmFollowUserState(isFollowing: false, userId: userId));
      ErrorHandler.showAppError(appError: apiResult.error);
    }
  }

  unfollowUser({required String userId}) async {
    emit(
        IsmFollowUserState(isFollowing: true, isLoading: true, userId: userId));
    final apiResult = await _followPostUseCase.executeFollowUser(
      isLoading: false,
      followingId: userId,
      followAction: FollowAction.unfollow,
    );
    if (apiResult.isSuccess) {
      emit(IsmFollowUserState(isFollowing: false, userId: userId)); // to update button/widget state
      _uniquePostList.values
          .where((e) => e.userId == userId)
          .forEach((element) {
        element.isFollowing = false;
      });
      emit(IsmFollowActionListenerState(
          isFollowing: false,
          userId: userId)); // on api success to invoke listener
    } else {
      emit(IsmFollowUserState(
          isFollowing: true, userId: userId));
      ErrorHandler.showAppError(appError: apiResult.error);
    }
  }

  loadPostLikeState({required String postId}) async {
    final postData = await getAsyncPostById(postId);
    final isLiked= postData?.isLiked ?? false;
    final _likeCount = postData?.engagementMetrics?.likeTypes?.love?.toInt() ?? 0;
    debugPrint('IsmSocialActionCubit: likeState , like: ${postData?.isLiked}, count ${postData?.engagementMetrics?.likeTypes?.love}');
    emit(IsmLikePostState(isLiked: isLiked, likeCount: max(_likeCount, 0), postId: postId));
  }

  likePost(String postId, int _likeCount) async {
    final likeCount = max(_likeCount, 0);
    emit(IsmLikePostState(isLiked: false, likeCount: likeCount, postId: postId, isLoading: true));
    final apiResult = await _likePostUseCase.executeLikePost(
      isLoading: false,
      postId: postId,
      likeAction: LikeAction.like,
    );


    if (apiResult.isSuccess) {
      final successLikeCount = likeCount + 1;
      emit(IsmLikePostState(isLiked: true, postId: postId, likeCount: successLikeCount)); // to update button/widget state
      getPostById(postId)?.let((post) {
        post.isLiked = true;
        post.engagementMetrics?.likeTypes?.love = successLikeCount;
      });
      debugPrint('IsmSocialActionCubit: likePost: success , like: ${getPostById(postId)?.isLiked}, count ${getPostById(postId)?.engagementMetrics?.likeTypes?.love}');
      emit(IsmLikeActionListenerState(
        isLiked: true,
        postId: postId,
      )); // on api success to invoke listener
    } else {
      emit(IsmLikePostState(isLiked: false, postId: postId, likeCount: likeCount)); // to update button/widget state
      ErrorHandler.showAppError(appError: apiResult.error);
    }
  }

  unLikePost(String postId, int _likeCount) async {
    final likeCount = max(_likeCount, 0);
    emit(IsmLikePostState(isLiked: true, likeCount: likeCount, postId: postId, isLoading: true));
    final apiResult = await _likePostUseCase.executeLikePost(
      isLoading: false,
      postId: postId,
      likeAction: LikeAction.unlike,
    );


    if (apiResult.isSuccess) {
      final successLikeCount = max(0, likeCount - 1);
      emit(IsmLikePostState(isLiked: false, postId: postId, likeCount: successLikeCount)); // to update button/widget state
      getPostById(postId)?.let((post) {
        post.isLiked = false;
        post.engagementMetrics?.likeTypes?.love = successLikeCount;
      });
      debugPrint('IsmSocialActionCubit: unLikePost: success , like: ${getPostById(postId)?.isLiked}, count ${getPostById(postId)?.engagementMetrics?.likeTypes?.love}');
      emit(IsmLikeActionListenerState(
        isLiked: false,
        postId: postId,
      )); // on api success to invoke listener
    } else {
      emit(IsmLikePostState(isLiked: true, postId: postId, likeCount: likeCount)); // to update button/widget state
      ErrorHandler.showAppError(appError: apiResult.error);
    }
  }
}
