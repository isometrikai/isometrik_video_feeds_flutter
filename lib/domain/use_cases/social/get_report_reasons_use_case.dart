import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class GetReportReasonsUseCase extends BaseUseCase {
  GetReportReasonsUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<List<ReportReason>?>> executeGetReportReasons({
    required bool isLoading,
    required ReasonsFor reasonFor,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getReportReasons(
          isLoading: isLoading,
          reasonFor: reasonFor,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
