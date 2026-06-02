import 'package:ism_video_reel_player/domain/domain.dart';

abstract class SoundsRepository extends BaseRepository {
  Future<CustomResponse<List<SoundData>?>> listSounds({
    required bool isLoading,
    String? search,
    String? categoryIds,
    int? page,
    int? pageSize,
  });

  Future<CustomResponse<List<SoundData>?>> listTrendingSounds({
    required bool isLoading,
    int page,
    int pageSize,
  });

  Future<CustomResponse<List<SoundData>?>> listRecentSounds({
    required bool isLoading,
    int limit,
  });

  Future<CustomResponse<List<SoundData>?>> listRecommendedSounds({
    required bool isLoading,
    int page,
    int pageSize,
  });

  Future<CustomResponse<List<SoundData>?>> listSavedSounds({
    required bool isLoading,
    int skip,
    int limit,
  });

  Future<CustomResponse<SoundData?>> getSoundDetails({
    required bool isLoading,
    required String soundId,
  });

  Future<CustomResponse<bool>> saveSound({
    required bool isLoading,
    required String soundId,
    required String userId,
  });

  Future<CustomResponse<bool>> unsaveSound({
    required bool isLoading,
    required String soundId,
  });

  Future<CustomResponse<bool>> isSoundSaved({
    required bool isLoading,
    required String soundId,
  });
}
