import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GeocodeSearchAddressUseCase extends BaseUseCase {
  GeocodeSearchAddressUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<AddressPlacesAutocompleteResponse?>> executeGetAddressByAutoCompleteSearch({
    required String searchText,
    required String placeType,
    required List<String>? countries,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getAddressByAutoCompleteSearch(
          searchText: searchText,
          countries: countries,
          placeType: placeType,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
