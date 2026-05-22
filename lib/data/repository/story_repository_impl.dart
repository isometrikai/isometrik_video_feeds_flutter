import 'dart:convert';

import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

List<StoryData> _decodeStoryListPayload(Map<String, dynamic> jsonData) {
  final dynamic data = jsonData['data'];
  if (data is List<dynamic>) {
    return data
        .map((e) => StoryData.fromMap(e as Map<String, dynamic>))
        .toList();
  }
  if (data is Map<String, dynamic>) {
    final list = data['stories'] as List<dynamic>? ??
        data['items'] as List<dynamic>? ??
        [];
    return list
        .map((e) => StoryData.fromMap(e as Map<String, dynamic>))
        .toList();
  }
  return [];
}

class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl(this._apiService, this._dataSource);

  final StoryApiService _apiService;
  final DataSource _dataSource;
  final CommonMapper _mapper = CommonMapper();

  @override
  Future<CustomResponse<ResponseClass?>> createStory({
    required bool isLoading,
    required CreateStoryRequest request,
  }) async {
    final response = await _apiService.createStory(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      requestMap: request.toJson(),
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<List<StoryData>?>> getStories({
    required bool isLoading,
    required String userId,
  }) async {
    final response = await _apiService.getStories(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      userId: userId,
    );
    final mapped = _mapper.mapResponseData(response);
    final jsonData =
        jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
    final storyList = _decodeStoryListPayload(jsonData);
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: storyList,
    );
  }

  @override
  Future<CustomResponse<List<StoryData>?>> getMyStories({
    required bool isLoading,
  }) async {
    final response = await _apiService.getMyStories(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
    );
    final mapped = _mapper.mapResponseData(response);
    final jsonData =
        jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
    final storyList = _decodeStoryListPayload(jsonData);
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: storyList,
    );
  }

  @override
  Future<CustomResponse<ResponseClass?>> startStoryProcessing({
    required bool isLoading,
    required String storyId,
  }) async {
    final response = await _apiService.startStoryProcessing(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      storyId: storyId,
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<StoryFeedResponse?>> getStoryFeed({
    required bool isLoading,
    int? limit,
    String? cursor,
  }) async {
    final response = await _apiService.getStoryFeed(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      limit: limit,
      cursor: cursor,
    );
    final mapped = _mapper.mapResponseData(response);
    final jsonData =
        jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: StoryFeedResponse.fromMap(
          jsonData['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  Future<CustomResponse<ResponseClass?>> createStoryHighlight({
    required bool isLoading,
    required CreateStoryHighlightRequest request,
  }) async {
    final response = await _apiService.createStoryHighlight(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      requestMap: request.toJson(),
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<List<StoryHighlightData>?>> getStoryHighlights({
    required bool isLoading,
    required String userId,
    int? page,
    int? pageSize,
  }) async {
    final response = await _apiService.getStoryHighlights(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      userId: userId,
      page: page,
      pageSize: pageSize,
    );
    final mapped = _mapper.mapResponseData(response);
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: storyHighlightsFromResponseData(mapped.data?.data ?? '{}'),
    );
  }

  @override
  Future<CustomResponse<StoryHighlightData?>> getStoryHighlightById({
    required bool isLoading,
    required String highlightId,
  }) async {
    final response = await _apiService.getStoryHighlightById(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      highlightId: highlightId,
    );
    final mapped = _mapper.mapResponseData(response);
    final jsonData =
        jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: StoryHighlightData.fromMap(
          jsonData['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  Future<CustomResponse<ResponseClass?>> updateStoryHighlight({
    required bool isLoading,
    required String highlightId,
    required UpdateStoryHighlightRequest request,
  }) async {
    final response = await _apiService.updateStoryHighlight(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      highlightId: highlightId,
      requestMap: request.toJson(),
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<ResponseClass?>> deleteStoryHighlight({
    required bool isLoading,
    required String highlightId,
  }) async {
    final response = await _apiService.deleteStoryHighlight(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      highlightId: highlightId,
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<ResponseClass?>> addStoriesToHighlight({
    required bool isLoading,
    required String highlightId,
    required AddStoriesToHighlightRequest request,
  }) async {
    final response = await _apiService.addStoriesToHighlight(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      highlightId: highlightId,
      requestMap: request.toJson(),
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<ResponseClass?>> removeStoryFromHighlight({
    required bool isLoading,
    required String highlightId,
    required String storyId,
  }) async {
    final response = await _apiService.removeStoryFromHighlight(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      highlightId: highlightId,
      storyId: storyId,
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<StoryData?>> getStoryDetail({
    required bool isLoading,
    required String storyId,
  }) async {
    final response = await _apiService.getStoryDetail(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      storyId: storyId,
    );
    final mapped = _mapper.mapResponseData(response);
    final jsonData =
        jsonDecode(mapped.data?.data ?? '{}') as Map<String, dynamic>;
    return CustomResponse(
      responseCode: mapped.responseCode,
      data: StoryData.fromMap(jsonData['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  Future<CustomResponse<ResponseClass?>> deleteStory({
    required bool isLoading,
    required String storyId,
  }) async {
    final response = await _apiService.deleteStory(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      storyId: storyId,
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<ResponseClass?>> markStoryViewed({
    required bool isLoading,
    required String storyId,
  }) async {
    final response = await _apiService.markStoryViewed(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      storyId: storyId,
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<ResponseClass?>> addStoryReaction({
    required bool isLoading,
    required String storyId,
    required String reactionType,
  }) async {
    final response = await _apiService.addStoryReaction(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      storyId: storyId,
      reactionType: reactionType,
    );
    return _mapper.mapResponseData(response);
  }

  @override
  Future<CustomResponse<ResponseClass?>> removeStoryReaction({
    required bool isLoading,
    required String storyId,
  }) async {
    final response = await _apiService.removeStoryReaction(
      isLoading: isLoading,
      header: await _dataSource.getHeader(),
      storyId: storyId,
    );
    return _mapper.mapResponseData(response);
  }
}
