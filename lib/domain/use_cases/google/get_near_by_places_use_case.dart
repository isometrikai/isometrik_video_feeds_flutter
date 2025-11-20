import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetNearByPlacesUseCase extends BaseUseCase {
  GetNearByPlacesUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<NearByPlaceResponse?>> executeGetNearByPlaces({
    required bool isLoading,
    required String placeType,
    double? radius, // in meters
  }) async =>
      await super.execute(() async {
        final response = await _repository.getNearByPlaces(
          isLoading: isLoading,
          placeType: placeType,
          radius: radius,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}

class PlaceType {
  const PlaceType(this.apiString);
  final String apiString;

  static const geocode = PlaceType('geocode');
  static const address = PlaceType('address');
  static const establishment = PlaceType('establishment');
  static const region = PlaceType('(region)');
  static const cities = PlaceType('(cities)');
}
