import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GetAddressFromLatLongUseCase extends BaseUseCase {
  GetAddressFromLatLongUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<GoogleAddressResponse?>> executeGetAddressFromLatLong({
    required bool isLoading,
    double? latitude,
    double? longitude,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getAddressFromLatLng(
          isLoading: isLoading,
          latitude: latitude,
          longitude: longitude,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
