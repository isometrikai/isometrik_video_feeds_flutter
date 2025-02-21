import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class VerifyOtpUseCase extends BaseUseCase {
  VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<ApiResult<LoginSignupData?>> executeVerifyOtp({
    required bool isLoading,
    required String otpId,
    required String otp,
    required String mobileNumber,
  }) async =>
      await super.execute(() async {
        final response = await _repository.verifyOtp(
          isLoading: isLoading,
          otpId: otpId,
          otp: otp,
          mobileNumber: mobileNumber,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
