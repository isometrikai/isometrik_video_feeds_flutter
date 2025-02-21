import 'package:ism_video_reel_player_example/domain/domain.dart';

abstract class AuthRepository extends BaseRepository {
  Future<CustomResponse<ResponseClass?>> login({
    required bool isLoading,
    required Map<String, dynamic>? loginMap,
  });

  Future<CustomResponse<ResponseClass?>> guestLogin({
    required bool isLoading,
  });

  Future<CustomResponse<LoginSignupData?>> verifyOtp({
    required bool isLoading,
    required String otpId,
    required String otp,
    required String mobileNumber,
  });

  Future<CustomResponse<LoginSignupData?>> sendOtp({
    required bool isLoading,
    required String mobileNumber,
  });
}
