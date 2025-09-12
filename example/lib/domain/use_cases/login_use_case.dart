import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class LoginUseCase extends BaseUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<ApiResult<ResponseClass?>> executeLogin({
    required bool isLoading,
    Map<String, dynamic>? loginMap,
  }) async =>
      await super.execute(() async {
        final response = await _repository.login(
          isLoading: isLoading,
          loginMap: loginMap,
        );
        return ApiResult(
            data: response.data?.statusCode == 200 ? response.data : null,
            statusCode: response.responseCode);
      });
}
