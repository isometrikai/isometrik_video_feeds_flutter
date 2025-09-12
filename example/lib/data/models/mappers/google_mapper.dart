import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GoogleMapper {
  CustomResponse<GoogleAddressResponse?> mapAddressFromLatLng(
          ResponseModel response) =>
      CustomResponse(data: googleAddressResponseFromJson(response.data));

  CustomResponse<GoogleAddressResponse?> mapAddressFromPinCode(
          ResponseModel response) =>
      CustomResponse(data: googleAddressResponseFromJson(response.data));

  CustomResponse<AddressPlacesAutocompleteResponse> placesAutocompleteResponse(
          ResponseModel response) =>
      CustomResponse(
          data: addressPlacesAutocompleteResponseFromJson(response.data));

  CustomResponse<PlaceDetails> placeDetailResultResponse(
          ResponseModel response) =>
      CustomResponse(data: placeDetailsFromJson(response.data));
}
