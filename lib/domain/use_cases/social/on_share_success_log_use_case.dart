import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class OnShareSuccessLogUseCase extends BaseUseCase {
  OnShareSuccessLogUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeOnShareSuccessLog({
    required bool isLoading,
    required OnShareRequest request,
  }) async =>
      await super.execute(() async {
        final response = await _repository.onShareSuccessLog(
          isLoading: isLoading,
          request: request,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
