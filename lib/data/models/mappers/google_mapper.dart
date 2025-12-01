import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GoogleMapper {
  CustomResponse<GoogleAddressResponse?> mapGeocodeResponse(
          ResponseModel response) =>
      CustomResponse(
          data: googleAddressResponseFromJson(response.data),
          responseCode: response.statusCode);

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

  CustomResponse<NearByPlaceResponse?> mapNearByResponse(
          ResponseModel response) =>
      CustomResponse(
          data: nearByPlaceResponseFromJson(response.data),
          responseCode: response.statusCode);
}
