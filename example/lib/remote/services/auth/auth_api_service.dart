import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';

abstract class AuthApiService extends BaseService {
  Future<ResponseModel> login({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? loginMap,
  });

  Future<ResponseModel> guestLogin({
    required bool isLoading,
    required Header header,
  });

  Future<ResponseModel> verifyOtp({
    required bool isLoading,
    required Header header,
    required String otpId,
    required String otp,
    required String mobileNumber,
  });

  Future<ResponseModel> sendOtp({
    required bool isLoading,
    required Header header,
    required String mobileNumber,
  });
}
