import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class ReportUseCase extends BaseUseCase {
  ReportUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeReport({
    required bool isLoading,
    required ReportRequest reportRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.report(
          isLoading: isLoading,
          reportRequest: reportRequest,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });
}
