import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetAddressFromPinCodeUseCase extends BaseUseCase {
  GetAddressFromPinCodeUseCase(this._repository);

  final GoogleRepository _repository;

  Future<ApiResult<GoogleAddressResponse?>> executeGetAddressFromPinCode({
    required bool isLoading,
    required String pinCode,
    required List<String>? countries,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getAddressFromPinCode(
          isLoading: isLoading,
          pinCode: pinCode,
          countries: countries,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
