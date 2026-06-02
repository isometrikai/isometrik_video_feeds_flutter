import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

abstract class SoundsApiService extends BaseService {
  Future<ResponseModel> listSounds({
    required bool isLoading,
    required Header header,
    String? search,
    String? categoryIds,
    int? page,
    int? pageSize,
  });

  Future<ResponseModel> listTrendingSounds({
    required bool isLoading,
    required Header header,
    int page,
    int pageSize,
  });

  Future<ResponseModel> listRecentSounds({
    required bool isLoading,
    required Header header,
    int limit,
  });

  Future<ResponseModel> listRecommendedSounds({
    required bool isLoading,
    required Header header,
    int page,
    int pageSize,
  });

  Future<ResponseModel> listSavedSounds({
    required bool isLoading,
    required Header header,
    int skip,
    int limit,
  });

  Future<ResponseModel> getSoundDetails({
    required bool isLoading,
    required Header header,
    required String soundId,
  });

  Future<ResponseModel> saveSound({
    required bool isLoading,
    required Header header,
    required Map<String, dynamic> body,
  });

  Future<ResponseModel> unsaveSound({
    required bool isLoading,
    required Header header,
    required String soundId,
  });

  Future<ResponseModel> isSoundSaved({
    required bool isLoading,
    required Header header,
    required String soundId,
  });
}
