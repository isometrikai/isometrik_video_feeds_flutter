import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GuestLoginUseCase extends BaseUseCase {
  GuestLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<ApiResult<ResponseClass?>> executeGuestLogin({
    required bool isLoading,
  }) async =>
      await super.execute(() async {
        final response = await _repository.guestLogin(
          isLoading: isLoading,
        );
        return ApiResult(data: response.data?.statusCode == 200 ? response.data : null);
      });
}
