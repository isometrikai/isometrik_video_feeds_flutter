import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GeocodeSearchAddressUseCase extends BaseUseCase {
  GeocodeSearchAddressUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<GoogleAddressResponse?>> executeGeocodeSearch({
    required bool isLoading,
    required String searchText,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getAddressFromSearch(
          isLoading: isLoading,
          searchText: searchText,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
