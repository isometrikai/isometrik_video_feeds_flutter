import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetPlaceDetailsUseCase extends BaseUseCase {
  GetPlaceDetailsUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<PlaceDetails?>> executeGetPlaceDetail({
    required String placeId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getPlaceDetail(
          placeId: placeId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
