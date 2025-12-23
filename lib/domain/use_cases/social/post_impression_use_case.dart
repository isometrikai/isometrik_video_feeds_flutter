import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class PostImpressionUseCase extends BaseUseCase {
  PostImpressionUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executePostImpression({
    required bool isLoading,
    required List<Map<String, dynamic>> impressionMapList,
  }) async =>
      await super.execute(() async {
        final response = await _repository.postImpression(
          isLoading: isLoading,
          impressionMapList: impressionMapList,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });
}
