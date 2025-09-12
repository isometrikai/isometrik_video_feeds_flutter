import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class ReportPostUseCase extends BaseUseCase {
  ReportPostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeReportPost({
    required bool isLoading,
    required String postId,
    required String message,
    required String reason,
  }) async =>
      await super.execute(() async {
        final response = await _repository.reportPost(
          isLoading: isLoading,
          postId: postId,
          message: message,
          reason: reason,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
