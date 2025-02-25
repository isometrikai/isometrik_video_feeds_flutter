import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetReportReasonsUseCase extends BaseUseCase {
  GetReportReasonsUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<List<String>?>> executeGetReportReasons({
    required bool isLoading,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getReportReasons(
          isLoading: isLoading,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
