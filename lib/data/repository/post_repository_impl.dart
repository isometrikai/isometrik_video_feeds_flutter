import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

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
  }) async {
    try {
      final header = await _dataSource.getHeader();
      final response = await _apiService.getTrendingPosts(
        isLoading: isLoading,
        header: header,
      );
      return _postMapper.mapPostResponseData(response);
    } catch (e) {
      rethrow;
    }
  }
}
