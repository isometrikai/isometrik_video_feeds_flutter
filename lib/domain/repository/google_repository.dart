import 'dart:io';

import 'package:ism_video_reel_player/domain/domain.dart';

abstract class GoogleRepository extends BaseRepository {
  Future<CustomResponse<GoogleAddressResponse?>> getAddressFromPinCode({
    required bool isLoading,
    required String pinCode,
    required List<String>? countries,
  });

  Future<CustomResponse<GoogleAddressResponse?>> getAddressFromLatLng({
    required bool isLoading,
    double? latitude,
    double? longitude,
  });

  Future<CustomResponse<AddressPlacesAutocompleteResponse?>> getAddressByAutoCompleteSearch({
    required String searchText,
    required String placeType,
    required List<String>? countries,
  });

  Future<CustomResponse<PlaceDetails?>> getPlaceDetail({
    required String placeId,
  });

  Future<String?> uploadMediaToGoogleCloud({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double)? onProgress,
    String? cloudFolderName,
  });

  Future<CustomResponse<GoogleAddressResponse?>> getAddressFromSearch({
    required bool isLoading,
    required String searchText,
  });
}
