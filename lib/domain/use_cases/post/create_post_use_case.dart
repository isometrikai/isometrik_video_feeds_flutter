import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class CreatePostUseCase extends BaseUseCase {
  CreatePostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<ResponseClass?>> executeCreatePost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.createPost(
          isLoading: isLoading,
          createPostRequest: createPostRequest,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
