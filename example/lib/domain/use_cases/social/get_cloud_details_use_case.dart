import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GetCloudDetailsUseCase extends BaseUseCase {
  GetCloudDetailsUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<CloudDetailsResponse?>> executeGetCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getCloudDetails(
          isLoading: isLoading,
          key: key,
          value: value,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
