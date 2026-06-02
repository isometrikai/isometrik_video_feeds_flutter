import 'dart:convert';

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

class SoundsRepositoryImpl implements SoundsRepository {
  SoundsRepositoryImpl(this._apiService, this._dataSource);

  final SoundsApiService _apiService;
  final DataSource _dataSource;
  final CommonMapper _mapper = CommonMapper();

  CustomResponse<List<SoundData>?> _mapSoundList(ResponseModel response) {
    final mapped = _mapper.mapResponseData(response);
    final httpCode = mapped.responseCode;
    if (httpCode != 200 && httpCode != 201) {
      return CustomResponse(responseCode: httpCode, data: null);
    }
    try {
      final jsonData =
          jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
      final parsed = SoundsListResponse.fromMap(jsonData);
      final statusCode = parsed.statusCode ?? httpCode;
      if (!parsed.isSuccess && parsed.sounds.isEmpty) {
        return CustomResponse(responseCode: statusCode, data: []);
      }
      return CustomResponse(
        responseCode: statusCode,
        data: parsed.sounds,
      );
    } catch (_) {
      return CustomResponse(responseCode: httpCode, data: []);
    }
  }

  @override
  Future<CustomResponse<List<SoundData>?>> listSounds({
    required bool isLoading,
    String? search,
    String? categoryIds,
    int? page,
    int? pageSize,
  }) async {
    final response = await _apiService.listSounds(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      search: search,
      categoryIds: categoryIds,
      page: page,
      pageSize: pageSize,
    );
    return _mapSoundList(response);
  }

  @override
  Future<CustomResponse<List<SoundData>?>> listTrendingSounds({
    required bool isLoading,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiService.listTrendingSounds(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      page: page,
      pageSize: pageSize,
    );
    return _mapSoundList(response);
  }

  @override
  Future<CustomResponse<List<SoundData>?>> listRecentSounds({
    required bool isLoading,
    int limit = 10,
  }) async {
    final response = await _apiService.listRecentSounds(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      limit: limit,
    );
    return _mapSoundList(response);
  }

  @override
  Future<CustomResponse<List<SoundData>?>> listRecommendedSounds({
    required bool isLoading,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiService.listRecommendedSounds(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      page: page,
      pageSize: pageSize,
    );
    return _mapSoundList(response);
  }

  @override
  Future<CustomResponse<List<SoundData>?>> listSavedSounds({
    required bool isLoading,
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _apiService.listSavedSounds(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      skip: skip,
      limit: limit,
    );
    return _mapSoundList(response);
  }

  @override
  Future<CustomResponse<SoundData?>> getSoundDetails({
    required bool isLoading,
    required String soundId,
  }) async {
    final response = await _apiService.getSoundDetails(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      soundId: soundId,
    );
    final mapped = _mapper.mapResponseData(response);
    try {
      final jsonData = jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
      return CustomResponse(
        responseCode: mapped.responseCode,
        data: soundDataFromResponseBody(jsonData),
      );
    } catch (_) {
      return CustomResponse(responseCode: mapped.responseCode, data: null);
    }
  }

  @override
  Future<CustomResponse<bool>> saveSound({
    required bool isLoading,
    required String soundId,
    required String userId,
  }) async {
    final response = await _apiService.saveSound(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      body: {'sound_id': soundId, 'user_id': userId},
    );
    final mapped = _mapper.mapResponseData(response);
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: mapped.responseCode == 200 || mapped.responseCode == 201,
    );
  }

  @override
  Future<CustomResponse<bool>> unsaveSound({
    required bool isLoading,
    required String soundId,
  }) async {
    final response = await _apiService.unsaveSound(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      soundId: soundId,
    );
    final mapped = _mapper.mapResponseData(response);
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: mapped.responseCode == 200 || mapped.responseCode == 204,
    );
  }

  @override
  Future<CustomResponse<bool>> isSoundSaved({
    required bool isLoading,
    required String soundId,
  }) async {
    final response = await _apiService.isSoundSaved(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      soundId: soundId,
    );
    final mapped = _mapper.mapResponseData(response);
    try {
      final jsonData =
          jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
      return CustomResponse(
        responseCode: mapped.responseCode,
        data: isSoundSavedFromResponseBody(jsonData),
      );
    } catch (_) {
      return CustomResponse(responseCode: mapped.responseCode, data: false);
    }
  }
}
