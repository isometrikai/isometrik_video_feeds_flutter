import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class StoryApiServiceProvider extends StoryApiService {
  StoryApiServiceProvider({
    required this.networkClient,
  });

  final NetworkClient networkClient;

  Future<Map<String, String>> _getHeaders(
    Header header,
  ) async {
    final appVersion = await Utility.getAppVersion();

    return {
      if (AppConstants.headerAccept.isEmptyOrNull == false)
        'Accept': AppConstants.headerAccept,
      if (AppConstants.headerContentType.isEmptyOrNull == false)
        'Content-Type': AppConstants.headerContentType,
      if (header.accessToken.isEmptyOrNull == false)
        'Authorization': header.accessToken,
      if (header.language.isEmptyOrNull == false) 'lan': header.language,
      if (header.city.isEmptyOrNull == false) 'city': header.city,
      if (header.state.isEmptyOrNull == false) 'state': header.state,
      if (header.country.isEmptyOrNull == false) 'country': header.country,
      if (header.latitude != 0) 'latitude': header.latitude.toString(),
      if (header.longitude != 0) 'longitude': header.longitude.toString(),
      if (header.ipAddress.isEmptyOrNull == false)
        'ipaddress': header.ipAddress,
      if (appVersion.isEmptyOrNull == false) 'version': appVersion,
      if (header.currencySymbol.isEmptyOrNull == false)
        'currencySymbol': header.currencySymbol,
      if (header.currencyCode.isEmptyOrNull == false)
        'currencyCode': header.currencyCode,
      if (header.platForm.platformText.isEmptyOrNull == false)
        'platform': header.platForm.platformText,
      if (header.xTenantId.isEmptyOrNull == false)
        'x-tenant-id': header.xTenantId,
      if (header.xProjectId.isEmptyOrNull == false)
        'x-project-id': header.xProjectId,
      if (IsrVideoReelConfig.additionalHeader != null)
        ...IsrVideoReelConfig.additionalHeader!
    };
  }

  Future<ResponseModel> _makeRequest({
    required Header header,
    required String endpoint,
    required NetworkRequestType requestType,
    required bool isLoading,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    List<String>? pathSegments,
  }) =>
      _getHeaders(header).then(
        (headers) => networkClient.makeRequest(
          endpoint,
          requestType,
          body?.removeEmptyValues(),
          query?.removeEmptyValues(),
          headers,
          isLoading,
          pathSegments: pathSegments,
        ),
      );

  @override
  Future<ResponseModel> createStory({
    required bool isLoading,
    required Header header,
    required Map<String, dynamic> requestMap,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postStory,
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
        body: requestMap,
      );

  @override
  Future<ResponseModel> getStories({
    required bool isLoading,
    required Header header,
    required String userId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.getStories,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'user_id': userId},
      );

  @override
  Future<ResponseModel> startStoryProcessing({
    required bool isLoading,
    required Header header,
    required String storyId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postStoryStartProcessing(storyId),
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> getStoryFeed({
    required bool isLoading,
    required Header header,
    int? limit,
    String? cursor,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.getStoryFeed,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {
          'limit': limit?.toString(),
          'cursor': cursor,
        },
      );

  @override
  Future<ResponseModel> createStoryHighlight({
    required bool isLoading,
    required Header header,
    required Map<String, dynamic> requestMap,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postStoryHighlights,
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
        body: requestMap,
      );

  @override
  Future<ResponseModel> getStoryHighlights({
    required bool isLoading,
    required Header header,
    required String userId,
    int? page,
    int? pageSize,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.getStoryHighlights,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {
          'user_id': userId,
          'page': page?.toString(),
          'page_size': pageSize?.toString(),
        },
      );

  @override
  Future<ResponseModel> getStoryHighlightById({
    required bool isLoading,
    required Header header,
    required String highlightId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.getStoryHighlightById(highlightId),
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> updateStoryHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
    required Map<String, dynamic> requestMap,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.patchStoryHighlightById(highlightId),
        requestType: NetworkRequestType.patch,
        isLoading: isLoading,
        body: requestMap,
      );

  @override
  Future<ResponseModel> deleteStoryHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.deleteStoryHighlightById(highlightId),
        requestType: NetworkRequestType.delete,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> addStoriesToHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
    required Map<String, dynamic> requestMap,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postAddStoriesToHighlight(highlightId),
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
        body: requestMap,
      );

  @override
  Future<ResponseModel> removeStoryFromHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
    required String storyId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.deleteStoryFromHighlight(
          highlightId: highlightId,
          storyId: storyId,
        ),
        requestType: NetworkRequestType.delete,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> getStoryDetail({
    required bool isLoading,
    required Header header,
    required String storyId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.getStoryDetail(storyId),
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> deleteStory({
    required bool isLoading,
    required Header header,
    required String storyId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.deleteStory(storyId),
        requestType: NetworkRequestType.delete,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> markStoryViewed({
    required bool isLoading,
    required Header header,
    required String storyId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postStoryView(storyId),
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
      );

  @override
  Future<ResponseModel> addStoryReaction({
    required bool isLoading,
    required Header header,
    required String storyId,
    required String reactionType,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postStoryReaction(storyId),
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
        query: {'reaction_type': reactionType},
      );

  @override
  Future<ResponseModel> removeStoryReaction({
    required bool isLoading,
    required Header header,
    required String storyId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: StoryApiEndPoints.postStoryReaction(storyId),
        requestType: NetworkRequestType.delete,
        isLoading: isLoading,
      );
}
