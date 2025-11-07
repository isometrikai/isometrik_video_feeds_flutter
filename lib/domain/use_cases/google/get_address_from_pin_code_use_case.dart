import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetAddressFromPinCodeUseCase extends BaseUseCase {
  GetAddressFromPinCodeUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<GoogleAddressResponse?>> executeGetAddressFromPinCode({
    required bool isLoading,
    required String pinCode,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getAddressFromPinCode(
          isLoading: isLoading,
          pinCode: pinCode,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
