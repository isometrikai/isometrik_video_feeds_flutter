import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class CommentActionUseCase extends BaseUseCase {
  CommentActionUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass>> executeCommentAction({
    required bool isLoading,
    required Map<String, dynamic> commentRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.doCommentAction(
          isLoading: isLoading,
          commentRequest: commentRequest,
        );
        return ApiResult(
          data: response.data?.statusCode == 200 || response.responseCode == 201
              ? response.data
              : null,
          statusCode: response.data?.statusCode,
        );
      });
}
