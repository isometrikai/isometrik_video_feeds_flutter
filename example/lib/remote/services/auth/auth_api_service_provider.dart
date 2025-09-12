import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class AuthApiServiceProvider extends AuthApiService {
  AuthApiServiceProvider(
    this._deviceInfoManager,
    this.networkClient,
  );

  final NetworkClient networkClient;
  final DeviceInfoManager _deviceInfoManager;

  @override
  Future<ResponseModel> login({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? loginMap,
  }) async =>
      await networkClient.makeRequest(
        AuthApiEndPoints.signIn,
        NetworkRequestType.post,
        {
          'ipAddress': header.ipAddress,
          'deviceType': _deviceInfoManager.deviceTypeCode,
          'deviceId': _deviceInfoManager.deviceId.toString(),
          'deviceMake': _deviceInfoManager.deviceMake,
          'deviceModel': _deviceInfoManager.deviceModel,
          'deviceOsVersion': _deviceInfoManager.deviceOs,
          'deviceTime': DateTime.now().toIso8601String(),
          ...loginMap ?? {},
        }.removeEmptyValues(),
        {},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'deviceType': _deviceInfoManager.deviceTypeCode,
          'deviceId': _deviceInfoManager.deviceId.toString(),
          'deviceMake': _deviceInfoManager.deviceMake ?? '',
          'deviceModel': _deviceInfoManager.deviceModel ?? '',
          'deviceOsVersion': _deviceInfoManager.deviceOs,
          'deviceTime': DateTime.now().toIso8601String(),
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );

  @override
  Future<ResponseModel> verifyOtp({
    required bool isLoading,
    required Header header,
    required String otpId,
    required String otp,
    required String mobileNumber,
  }) async =>
      await networkClient.makeRequest(
        AuthApiEndPoints.postVerifyOtp,
        NetworkRequestType.post,
        {
          'otpId': otpId,
          'otpCode': otp,
          'verifyType': '2',
        },
        {},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );

  @override
  Future<ResponseModel> sendOtp({
    required bool isLoading,
    required Header header,
    required String mobileNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<ResponseModel> guestLogin({
    required bool isLoading,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        AuthApiEndPoints.postGuestSignIn,
        NetworkRequestType.post,
        {
          'deviceMake': _deviceInfoManager.deviceMake,
          'deviceModel': _deviceInfoManager.deviceModel,
          'deviceOsVersion': _deviceInfoManager.deviceOs,
          'deviceTime': DateTime.now().toIso8601String(),
          'deviceId': _deviceInfoManager.deviceId.toString(),
        },
        {},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );
}
