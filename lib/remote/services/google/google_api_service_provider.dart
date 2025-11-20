import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class GoogleApiServiceProvider extends GoogleApiService with AppMixin {
  GoogleApiServiceProvider(this._localStorageManager, {required this.apiKey});

  final LocalStorageManager _localStorageManager;

  final String apiKey;

  @override
  Future<ResponseModel> getAddressFromPinCode({
    required bool isLoading,
    required String pinCode,
    required List<String>? countries,
  }) async {
    var apiURL =
        '${GoogleApiEndPoints.getGeocodeAddress}?address=$pinCode&key=$apiKey';

    for (var i = 0; i < countries!.length; i++) {
      final country = countries[i];

      if (i == 0) {
        apiURL = '$apiURL&components=country:$country';
      } else {
        apiURL = '$apiURL|country:$country';
      }
    }

    if (isLoading) Utility.showLoader();

    final response = await http.get(Uri.parse(apiURL));

    if (isLoading) Utility.closeProgressDialog();
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL :- $apiURL\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
      return ResponseModel(
        data: response.body,
        hasError: true,
        statusCode: response.statusCode,
      );
    } else {
      Utility.closeProgressDialog();
      throw Exception('Failed to load address');
    }
  }

  @override
  Future<ResponseModel> getAddressFromSearch({
    required bool isLoading,
    required String searchText,
  }) async {
    // Encode the search text for URL
    final encodedSearch = Uri.encodeQueryComponent(searchText);

    // Build the API URL - using Places Autocomplete API
    final apiURL =
        '${GoogleApiEndPoints.getGeocodeAddress}?address=$encodedSearch&key=$apiKey&language=en&types=geocode';

    final response = await http.get(Uri.parse(apiURL));
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL :- $apiURL\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
      return ResponseModel(
        data: response.body,
        hasError: true,
        statusCode: response.statusCode,
      );
    } else {
      throw Exception('Failed to load address');
    }
  }

  @override
  Future<ResponseModel> getAddressByAutoCompleteSearch({
    required String searchText,
    required String placeType,
    required List<String>? countries,
  }) async {
    var apiURL =
        '${GoogleApiEndPoints.getAddressByAutoCompleteSearch}?input=$searchText&key=$apiKey&language=en';

    for (var i = 0; i < countries!.length; i++) {
      final country = countries[i];

      if (i == 0) {
        apiURL = '$apiURL&components=country:$country';
      } else {
        apiURL = '$apiURL|country:$country';
      }
    }
    apiURL += '&types=$placeType';

    final response = await http.get(Uri.parse(apiURL));
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL :- $apiURL\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
      return ResponseModel(
        data: response.body,
        hasError: true,
        statusCode: response.statusCode,
      );
    } else {
      Utility.closeProgressDialog();
      throw Exception('Failed to load address');
    }
  }

  @override
  Future<ResponseModel> getPlaceDetails({
    required String placeId,
  }) async {
    final apiURL =
        '${GoogleApiEndPoints.getPlaceDetails}?placeid=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(apiURL));
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL :- $apiURL\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
      return ResponseModel(
        data: response.body,
        hasError: true,
        statusCode: response.statusCode,
      );
    } else {
      Utility.closeProgressDialog();
      throw Exception('Failed to load address');
    }
  }

  @override
  Future<ResponseModel> getAddressFromLatLng({
    required bool isLoading,
    double? latitude,
    double? longitude,
  }) async {
    final saveLatitude = await _localStorageManager.getValue(
        LocalStorageKeys.latitude, SavedValueDataType.double) as double;
    final saveLongitude = await _localStorageManager.getValue(
        LocalStorageKeys.longitude, SavedValueDataType.double) as double;
    final url =
        '${GoogleApiEndPoints.getGeocodeAddress}?latlng=${latitude ?? saveLatitude},${longitude ?? saveLongitude}&key=$apiKey';

    if (isLoading) Utility.showLoader();

    final response = await http.get(Uri.parse(url));

    Utility.closeProgressDialog();
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL :- $url\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
      return ResponseModel(
        data: response.body,
        hasError: true,
        statusCode: response.statusCode,
      );
    } else {
      throw Exception('Failed to load address');
    }
  }

  @override
  Future<ResponseModel> getNearByPlaces({
    required String placeType,
    required bool isLoading,
    double radius = 10000, // meters
  }) async {
    final saveLatitude = await _localStorageManager.getValue(
        LocalStorageKeys.latitude, SavedValueDataType.double) as double;
    final saveLongitude = await _localStorageManager.getValue(
        LocalStorageKeys.longitude, SavedValueDataType.double) as double;
    final url =
        '${GoogleApiEndPoints.getNearByPlaces}?location=$saveLatitude,$saveLongitude&key=$apiKey&radius=$radius&types=$placeType';

    if (isLoading) Utility.showLoader();

    final response = await http.get(Uri.parse(url));

    Utility.closeProgressDialog();
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL :- $url\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
      return ResponseModel(
        data: response.body,
        hasError: true,
        statusCode: response.statusCode,
      );
    } else {
      throw Exception('Failed to load address');
    }
  }
}
