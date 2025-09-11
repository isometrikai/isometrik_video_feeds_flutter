import 'dart:io';

import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';

class GoogleRepositoryImpl extends GoogleRepository {
  GoogleRepositoryImpl(this._apiService);

  final GoogleApiService _apiService;
  final GoogleMapper _googleMapper = GoogleMapper();

  @override
  Future<CustomResponse<GoogleAddressResponse?>> getAddressFromLatLng({
    required bool isLoading,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiService.getAddressFromLatLng(
        isLoading: isLoading,
        latitude: latitude,
        longitude: longitude,
      );
      return _googleMapper.mapAddressFromLatLng(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<GoogleAddressResponse?>> getAddressFromPinCode({
    required bool isLoading,
    required String pinCode,
  }) async {
    try {
      final response = await _apiService.getAddressFromPinCode(
        isLoading: isLoading,
        pinCode: pinCode,
      );
      return _googleMapper.mapAddressFromPinCode(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<AddressPlacesAutocompleteResponse?>> getAddressByAutoCompleteSearch({
    required String searchText,
    required String placeType,
    required List<String>? countries,
  }) async {
    try {
      final response = await _apiService.getAddressByAutoCompleteSearch(
        searchText: searchText,
        countries: countries,
        placeType: placeType,
      );
      return _googleMapper.placesAutocompleteResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<PlaceDetails?>> getPlaceDetail({
    required String placeId,
  }) async {
    try {
      final response = await _apiService.getPlaceDetails(
        placeId: placeId,
      );
      return _googleMapper.placeDetailResultResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> uploadMediaToGoogleCloud({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double p1)? onProgress,
    String? cloudFolderName,
  }) async {
    final response = await GoogleCloudStorageUploader.uploadFileWithRealProgress(
        file: file,
        fileName: fileName,
        fileExtension: fileExtension,
        userId: userId,
        onProgress: (progress) {
          if (onProgress == null) return;
          onProgress(progress);
        });
    return response ?? '';
  }
}
