import 'dart:io';

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._apiService, this._dataSource, this._localDataUseCase);

  final SocialApiService _apiService;
  final DataSource _dataSource;
  final CommonMapper _mapper = CommonMapper();
  final SocialMapper _socialMapper = SocialMapper();
  final IsmLocalDataUseCase _localDataUseCase;
  final LocalActionManager _localActionManager = LocalActionManager();

  @override
  Future<CustomResponse<CreatePostResponse?>> createPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.createPost(
        isLoading: isLoading,
        header: header,
        createPostRequest: createPostRequest,
      );
      return _socialMapper.mapCreatePostResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<CreatePostResponse?>> editPost({
    required bool isLoading,
    required String postId,
    Map<String, dynamic>? editPostRequest,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.editPost(
        isLoading: isLoading,
        header: header,
        postId: postId,
        editPostRequest: editPostRequest,
      );
      return _socialMapper.mapCreatePostResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<PostResponse?>> getFollowingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getFollowingPosts(
        isLoading: isLoading,
        header: header,
        page: page,
        pageLimit: pageLimit,
      );
      return _socialMapper.mapPostResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<TimelineDataResponse?>> getTrendingPost({
    required bool isLoading,
    required String? cursor,
    required int limit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getTrendingPosts(
        isLoading: isLoading,
        header: header,
        cursor: cursor,
        limit: limit,
      );
      return await _mapTimelineDataResponseWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<FollowUnfollowResponseModel?>> followUser({
    required bool isLoading,
    required String followingId,
    required FollowAction followAction,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.followUser(
        isLoading: isLoading,
        header: header,
        followingId: followingId,
        followAction: followAction,
      );
      await _storeFollowAction(followingId, followAction);
      return _socialMapper.mapFollowUnfollowData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> savePost({
    required bool isLoading,
    required String postId,
    required SocialPostAction socialPostAction,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.savePost(
        isLoading: isLoading,
        header: header,
        postId: postId,
        socialPostAction: socialPostAction,
      );
      await _storeSaveAction(postId, socialPostAction);
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> likePost({
    required bool isLoading,
    required String postId,
    required LikeAction likeAction,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.likePost(
        isLoading: isLoading,
        header: header,
        postId: postId,
        likeAction: likeAction,
      );
      await _storeLikeAction(postId, likeAction);
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> reportPost({
    required bool isLoading,
    required String postId,
    required String message,
    required String reason,
  }) async {
    try {
      final response = await _apiService.reportPost(
        isLoading: isLoading,
        postId: postId,
        message: message,
        reason: reason,
        header: await _dataSource.getHeader(),
      );

      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> report({
    required bool isLoading,
    required ReportRequest reportRequest,
  }) async {
    try {
      final response = await _apiService.report(
        isLoading: isLoading,
        reportBody: reportRequest.toJson(),
        header: await _dataSource.getHeader(),
      );

      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<List<ReportReason>?>> getReportReasons({
    required bool isLoading,
    required ReasonsFor reasonFor,
  }) async {
    try {
      final response = await _apiService.getReportReasons(
        isLoading: isLoading,
        reasonFor: reasonFor,
        header: await _dataSource.getHeader(),
      );

      return _socialMapper.mapReasonData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<CloudDetailsResponse?>> getCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
  }) async {
    try {
      final response = await _apiService.getCloudDetails(
        isLoading: isLoading,
        key: key,
        value: value,
        header: await _dataSource.getHeader(),
      );

      return _socialMapper.mapCloudinaryData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<CommentsResponse?>> getPostComments({
    required bool isLoading,
    required String postId,
    required String? parentCommitId,
    int? page,
    int? pageLimit,
  }) async {
    try {
      final response = await _apiService.getPostComments(
        isLoading: isLoading,
        postId: postId,
        parentCommitId: parentCommitId,
        header: await _dataSource.getHeader(),
        page: page,
        pageLimit: pageLimit,
      );

      return _socialMapper.mapCommentsResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<PostDetailsResponse?>> getSocialProducts({
    required bool isLoading,
    required String postId,
    List<String>? productIds,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _apiService.getSocialProducts(
        isLoading: isLoading,
        postId: postId,
        productIds: productIds,
        page: page,
        limit: limit,
        header: await _dataSource.getHeader(),
      );

      return _socialMapper.mapPostDetailsResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> doCommentAction({
    required bool isLoading,
    required Map<String, dynamic> commentRequest,
  }) async {
    try {
      final response = await _apiService.doCommentAction(
        isLoading: isLoading,
        commentRequest: commentRequest,
        header: await _dataSource.getHeader(),
      );

      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<TimeLineData?>> getPostDetails({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final response = await _apiService.getPostDetails(
        isLoading: isLoading,
        postId: postId,
        header: await _dataSource.getHeader(),
      );
      return await _mapTimelineDataWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<InsightsResponse?>> getPostInsight({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final response = await _apiService.getPostInsight(
        isLoading: isLoading,
        postId: postId,
        header: await _dataSource.getHeader(),
      );
      return _socialMapper.mapPostInsightResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> deletePost({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final response = await _apiService.deletePost(
        isLoading: isLoading,
        postId: postId,
        header: await _dataSource.getHeader(),
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> postScheduledPost({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final response = await _apiService.postScheduledPost(
        isLoading: isLoading,
        postId: postId,
        header: await _dataSource.getHeader(),
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<PostData?>> getPost({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final response = await _apiService.getPost(
        isLoading: isLoading,
        postId: postId,
        header: await _dataSource.getHeader(),
      );
      return await _mapPostDataWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> uploadMediaToGoogleCloud({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double p1)? onProgress,
    String? cloudFolderName,
  }) async {
    final response =
        await GoogleCloudStorageUploader.uploadFileWithRealProgress(
            file: file,
            fileName: fileName,
            fileExtension: fileExtension,
            userId: userId,
            onProgress: (progress) {
              if (onProgress == null) return;
              onProgress(progress);
            });
    return response ?? '';
  }

  @override
  Future<CustomResponse<TimelineResponse?>> getTimeLinePosts({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getTimeLinePosts(
        isLoading: isLoading,
        header: header,
        page: page,
        pageLimit: pageLimit,
      );
      return await _mapTimelineResponseWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> processMedia({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.processMedia(
        isLoading: isLoading,
        header: header,
        postId: postId,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<SearchUserResponse?>> searchUser({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.searchUser(
        isLoading: isLoading,
        header: header,
        limit: limit,
        page: page,
        searchText: searchText,
      );
      return await _mapSearchUserResponseWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<HashTagResponse?>> searchTag({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.searchTag(
        isLoading: isLoading,
        header: header,
        limit: limit,
        page: page,
        searchText: searchText,
      );
      return _socialMapper.mapSearchTagResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<SocialUserProfileResponse?>> getUserProfile({
    required bool isLoading,
    required String userId,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getUserProfile(
          isLoading: isLoading, header: header, userId: userId);
      return await _mapUserProfileResponseWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<TimelineResponse?>> getTaggedPosts({
    required bool isLoading,
    required String tagValue,
    required TagType tagType,
    required int page,
    required int pageLimit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getTaggedPosts(
        isLoading: isLoading,
        header: header,
        page: page,
        pageLimit: pageLimit,
        tagValue: tagValue,
        tagType: tagType,
      );
      return await _mapTimelineResponseWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<TimelineResponse?>> getProfileSavedPostData({
    required bool isLoading,
    required int page,
    required int pageSize,
    required String collectionId,
  }) async {
    final header = await _dataSource.getHeader();
    final response = await _apiService.getProfileSavedPostData(
      isLoading: isLoading,
      header: header,
      page: page,
      pageSize: pageSize,
      collectionId: collectionId,
    );
    return await _mapTimelineResponseWithLocalActions(response);
  }

  @override
  Future<CustomResponse<TimelineResponse?>> getProfileUserPostData({
    required bool isLoading,
    required int page,
    required int pageSize,
    required String memberId,
    required bool scheduledOnly,
  }) async {
    final header = await _dataSource.getHeader();
    final response = await _apiService.getProfileUserPostDataSocial(
      isLoading: isLoading,
      header: header,
      page: page,
      pageSize: pageSize,
      memberId: memberId,
      scheduledOnly: scheduledOnly,
    );

    return await _mapTimelineResponseWithLocalActions(response);
  }

  @override
  Future<CustomResponse<TimelineDataResponse?>> getForYouPosts({
    required bool isLoading,
    required String? cursor,
    required int limit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getForYouPosts(
        isLoading: isLoading,
        header: header,
        cursor: cursor,
        limit: limit,
      );
      return await _mapTimelineDataResponseWithLocalActions(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<SearchUserResponse?>> getMentionedUsers({
    required bool isLoading,
    required String postId,
    required int page,
    required int pageLimit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getMentionedUsers(
        isLoading: isLoading,
        header: header,
        postId: postId,
        page: page,
        pageLimit: pageLimit,
      );
      return _socialMapper.mapSearchUserResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> removeMentionFromPost({
    required bool isLoading,
    required String postId,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.removeMentionFromPost(
        isLoading: isLoading,
        header: header,
        postId: postId,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> onShareSuccessLog({
    required bool isLoading,
    required OnShareRequest request,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.onShareSuccessLog(
        isLoading: isLoading,
        header: header,
        requestMap: request.toJson(),
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> createCollection({
    required bool isLoading,
    required Map<String, dynamic> requestMap,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.createCollection(
        isLoading: isLoading,
        header: header,
        requestMap: requestMap,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<CollectionResponseModel?>> getCollectionList({
    required bool isLoading,
    required int page,
    required int pageSize,
    required bool isPublicOnly,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getCollectionList(
        isLoading: isLoading,
        header: header,
        page: page,
        pageSize: pageSize,
        isPublicOnly: isPublicOnly,
      );
      return _socialMapper.mapCollectionListResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> movePostToCollection({
    required bool isLoading,
    required String postId,
    required String collectionId,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.movePostToCollection(
        isLoading: isLoading,
        header: header,
        postId: postId,
        collectionId: collectionId,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> updateCollection({
    required bool isLoading,
    required String collectionId,
    required Map<String, dynamic> requestMap,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.updateCollection(
        isLoading: isLoading,
        header: header,
        collectionId: collectionId,
        requestMap: requestMap,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> deleteCollection({
    required bool isLoading,
    required String collectionId,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.deleteCollection(
        isLoading: isLoading,
        header: header,
        collectionId: collectionId,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> postImpression({
    required bool isLoading,
    required List<Map<String, dynamic>> impressionMapList,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.postImpression(
        isLoading: isLoading,
        header: header,
        impressionMapList: impressionMapList,
      );
      return _mapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomResponse<TimelineResponse?>> _mapTimelineResponseWithLocalActions(
      ResponseModel response) async {
    final viewerId = await _getViewerId();
    final mappedResponse = _socialMapper.mapTimelineResponse(response);
    _applyLocalActionsToPosts(
      mappedResponse.data?.data,
      viewerId: viewerId,
    );
    return mappedResponse;
  }

  Future<CustomResponse<TimelineDataResponse?>>
      _mapTimelineDataResponseWithLocalActions(
      ResponseModel response) async {
    final viewerId = await _getViewerId();
    final mappedResponse = _socialMapper.mapTimelineDataResponse(response);
    _applyLocalActionsToPosts(
      mappedResponse.data?.data?.posts,
      viewerId: viewerId,
    );
    return mappedResponse;
  }

  Future<CustomResponse<TimeLineData?>> _mapTimelineDataWithLocalActions(
      ResponseModel response) async {
    final viewerId = await _getViewerId();
    final mappedResponse = _socialMapper.mapTimelineData(response);
    _applyLocalActionsToPost(
      mappedResponse.data,
      viewerId: viewerId,
    );
    return mappedResponse;
  }

  Future<CustomResponse<PostData?>> _mapPostDataWithLocalActions(
      ResponseModel response) async {
    final viewerId = await _getViewerId();
    final mappedResponse = _socialMapper.mapPostData(response);
    final postId = mappedResponse.data?.id ?? mappedResponse.data?.postId;
    if (postId?.isNotEmpty == true) {
      final isLiked = postId!.isLiked(viewerId: viewerId);
      if (isLiked != null) {
        mappedResponse.data?.liked = isLiked;
      }
      final isSaved = postId.isSaved(viewerId: viewerId);
      if (isSaved != null) {
        mappedResponse.data?.isSavedPost = isSaved;
      }
    }
    return mappedResponse;
  }

  void _applyLocalActionsToPosts(
    List<TimeLineData>? posts, {
    required String viewerId,
  }) {
    if (posts == null) return;
    for (final post in posts) {
      _applyLocalActionsToPost(
        post,
        viewerId: viewerId,
      );
    }
  }

  void _applyLocalActionsToPost(
    TimeLineData? post, {
    required String viewerId,
  }) {
    if (post == null) return;
    final postId = post.id;
    if (postId?.isNotEmpty == true) {
      final isLiked = postId!.isLiked(viewerId: viewerId);
      if (isLiked != null) {
        post.isLiked = isLiked;
      }
      final isSaved = postId.isSaved(viewerId: viewerId);
      if (isSaved != null) {
        post.isSaved = isSaved;
      }
    }

    final userId = post.userId ?? post.user?.id;
    if (userId?.isNotEmpty == true) {
      final isFollowing = userId!.isFollowing(viewerId: viewerId);
      if (isFollowing != null) {
        post.isFollowing = isFollowing;
        post.user?.isFollowing = isFollowing;
      }
    }
  }

  Future<void> _storeFollowAction(
      String followingId, FollowAction followAction) async {
    final viewerId = await _getViewerId();
    _localActionManager.storeAction(
      action: followAction == FollowAction.follow
          ? CacheActionType.followingUser
          : CacheActionType.unFollowingUser,
      relevantId: followingId,
      viewerId: viewerId,
    );
  }

  Future<void> _storeLikeAction(String postId, LikeAction likeAction) async {
    final viewerId = await _getViewerId();
    _localActionManager.storeAction(
      action: likeAction == LikeAction.like
          ? CacheActionType.likePost
          : CacheActionType.deLikePost,
      relevantId: postId,
      viewerId: viewerId,
    );
  }

  Future<void> _storeSaveAction(
      String postId, SocialPostAction socialPostAction) async {
    final cacheActionType = switch (socialPostAction) {
      SocialPostAction.save => CacheActionType.savePost,
      SocialPostAction.unSave => CacheActionType.unSavePost,
      _ => null,
    };
    if (cacheActionType == null) return;
    final viewerId = await _getViewerId();
    _localActionManager.storeAction(
      action: cacheActionType,
      relevantId: postId,
      viewerId: viewerId,
    );
  }

  Future<CustomResponse<SocialUserProfileResponse?>>
      _mapUserProfileResponseWithLocalActions(ResponseModel response) async {
    final viewerId = await _getViewerId();
    final mappedResponse = _socialMapper.mapUserProfileResponse(response);
    final profileResponse = mappedResponse.data;
    final profileData = profileResponse?.data;
    final profileId = profileData?.id;
    if (profileId?.isNotEmpty != true) {
      return mappedResponse;
    }

    final isFollowing = profileId!.isFollowing(viewerId: viewerId);
    if (isFollowing == null) {
      return mappedResponse;
    }

    final updatedProfileResponse = profileResponse?.copyWith(
      data: profileData?.copyWith(isFollowing: isFollowing),
    );

    return CustomResponse(
      data: updatedProfileResponse,
      responseCode: mappedResponse.responseCode,
    );
  }

  Future<CustomResponse<SearchUserResponse?>>
      _mapSearchUserResponseWithLocalActions(
      ResponseModel response) async {
    final viewerId = await _getViewerId();
    final mappedResponse = _socialMapper.mapSearchUserResponse(response);
    for (final user in mappedResponse.data?.data ?? <SocialUserData>[]) {
      final userId = user.id;
      if (userId?.isNotEmpty != true) continue;
      final isFollowing = userId!.isFollowing(viewerId: viewerId);
      if (isFollowing != null && isFollowing != user.isFollowing) {
        user.isFollowing = isFollowing;
      }
    }
    return mappedResponse;
  }

  Future<String> _getViewerId() => _localDataUseCase.getUserId();
}
