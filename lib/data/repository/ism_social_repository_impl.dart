import 'dart:io';

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._apiService, this._dataSource);

  final SocialApiService _apiService;
  final DataSource _dataSource;
  final CommonMapper _mapper = CommonMapper();
  final SocialMapper _socialMapper = SocialMapper();

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
  Future<CustomResponse<TimelineResponse?>> getTrendingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getTrendingPosts(
        isLoading: isLoading,
        header: header,
        page: page,
        pageLimit: pageLimit,
      );
      return _socialMapper.mapTimelineResponse(response);
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
  Future<CustomResponse<List<ReportReason>?>> getReportReasons({
    required bool isLoading,
    ReasonsFor? reasonFor,
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
      return _socialMapper.mapTimelineData(response);
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
      return _socialMapper.mapPostData(response);
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
    final response = await GoogleCloudStorageUploader.uploadFileWithRealProgress(
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
      return _socialMapper.mapTimelineResponse(response);
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
      return _socialMapper.mapSearchUserResponse(response);
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
      final response =
          await _apiService.getUserProfile(isLoading: isLoading, header: header, userId: userId);
      return _socialMapper.mapUserProfileResponse(response);
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
      return _socialMapper.mapTimelineResponse(response);
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
    return _socialMapper.mapTimelineResponse(response);
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

    return _socialMapper.mapTimelineResponse(response);
  }

  @override
  Future<CustomResponse<TimelineResponse?>> getForYouPosts({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getForYouPosts(
        isLoading: isLoading,
        header: header,
        page: page,
        pageLimit: pageLimit,
      );
      return _socialMapper.mapTimelineResponse(response);
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
}
