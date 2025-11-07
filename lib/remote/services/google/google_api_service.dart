import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

abstract class GoogleApiService extends BaseService {
  Future<ResponseModel> getAddressFromPinCode({
    required bool isLoading,
    required String pinCode,
  });

  Future<ResponseModel> getAddressFromLatLng({
    required bool isLoading,
    double? latitude,
    double? longitude,
  });

  Future<ResponseModel> getAddressByAutoCompleteSearch({
    required String searchText,
    required String placeType,
    required List<String>? countries,
  });

  Future<ResponseModel> getPlaceDetails({
    required String placeId,
  });
}
