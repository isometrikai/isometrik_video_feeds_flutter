import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

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
  Future<CustomResponse<PostResponse?>> getTrendingPost({
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
      return _socialMapper.mapPostResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<ResponseClass?>> followPost({
    required bool isLoading,
    required String followingId,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.followPost(
        isLoading: isLoading,
        header: header,
        followingId: followingId,
      );
      return _mapper.mapResponseData(response);
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
    required String userId,
    required LikeAction likeAction,
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.likePost(
        isLoading: isLoading,
        header: header,
        postId: postId,
        userId: userId,
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
  Future<CustomResponse<List<String>?>> getReportReasons({
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
  }) async {
    try {
      final response = await _apiService.getPostComments(
        isLoading: isLoading,
        postId: postId,
        header: await _dataSource.getHeader(),
      );

      return _socialMapper.mapCommentsResponse(response);
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
  Future<CustomResponse<PostDetailsResponse?>> getPostDetails({
    required bool isLoading,
    List<String>? productIds,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _apiService.getPostDetails(
        isLoading: isLoading,
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
}
