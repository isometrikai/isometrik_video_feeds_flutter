import 'package:bloc/bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

part 'social_action_state.dart';

class IsmSocialActionCubit extends Cubit<IsmSocialActionState> {
  IsmSocialActionCubit(
    this._followPostUseCase,
    this._getPostDetailsUseCase,
  ) : super(IsmSocialActionState());

  final FollowUnFollowUserUseCase _followPostUseCase;
  final GetPostDetailsUseCase _getPostDetailsUseCase;

  final _uniquePostList = <String, TimeLineData>{};

  updatePostList(List<TimeLineData> postList) {
    for (var element in postList) {
      if (element.id != null) {
        _uniquePostList[element.id!] = element;
      }
    }
  }

  TimeLineData? getPostById(String postId) => _uniquePostList[postId];

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
      emit(IsmFollowUserState(isFollowing: true, userId: userId));
      _uniquePostList.values
          .where((e) => e.userId == userId)
          .forEach((element) {
        element.isFollowing = true;
      });
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
      emit(IsmFollowUserState(isFollowing: false, userId: userId));
      _uniquePostList.values
          .where((e) => e.userId == userId)
          .forEach((element) {
        element.isFollowing = false;
      });
    } else {
      emit(IsmFollowUserState(isFollowing: true, userId: userId));
      ErrorHandler.showAppError(appError: apiResult.error);
    }
  }
}
