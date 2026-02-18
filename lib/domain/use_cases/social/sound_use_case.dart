import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class SoundUseCase extends BaseUseCase {
  SoundUseCase(this._repository);

  final SocialRepository _repository;

  /// get sound list
  Future<ApiResult<SoundListResponseModel?>> executeGetSoundList({
    required bool isLoading,
    required int page,
    required int pageSize,
    String? search,
    SoundListTypes soundListTypes = SoundListTypes.sound,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getSoundList(
          isLoading: isLoading,
          page: page,
          pageSize: pageSize,
          search: search,
          soundListTypes: soundListTypes,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });
}
