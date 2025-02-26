import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._apiService, this._dataSource);

  final PostApiService _apiService;
  final DataSource _dataSource;
  final CommonMapper _mapper = CommonMapper();
  final PostMapper _postMapper = PostMapper();

  @override
  Future<CustomResponse<ResponseClass?>> createPost({
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
      return _mapper.mapResponseData(response);
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
      return _postMapper.mapPostResponseData(response);
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
      return _postMapper.mapPostResponseData(response);
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
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.savePost(
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
  }) async {
    try {
      final response = await _apiService.getReportReasons(
        isLoading: isLoading,
        header: await _dataSource.getHeader(),
      );

      return _mapper.mapReasonData(response);
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

      return _postMapper.mapCloudinaryData(response);
    } catch (e) {
      rethrow;
    }
  }
}
