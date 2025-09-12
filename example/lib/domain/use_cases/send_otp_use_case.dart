import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class SendOtpUseCase extends BaseUseCase {
  SendOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<ApiResult<LoginSignupData?>> executeSendOtp({
    required bool isLoading,
    required String mobileNumber,
  }) async =>
      await super.execute(() async {
        final response = await _repository.sendOtp(
          isLoading: isLoading,
          mobileNumber: mobileNumber,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
