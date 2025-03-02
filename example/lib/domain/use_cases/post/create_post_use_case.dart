import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class CreatePostUseCase extends BaseUseCase {
  CreatePostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<CreatePostResponse?>> executeCreatePost({
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
