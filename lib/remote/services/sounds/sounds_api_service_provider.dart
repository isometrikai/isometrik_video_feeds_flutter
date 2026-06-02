import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class SoundsApiServiceProvider extends SoundsApiService {
  SoundsApiServiceProvider({required this.networkClient});

  final NetworkClient networkClient;

  Future<Map<String, String>> _getHeaders(Header header) async {
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
        ...IsrVideoReelConfig.additionalHeader!,
    };
  }

  Future<ResponseModel> _makeRequest({
    required Header header,
    required String endpoint,
    required NetworkRequestType requestType,
    required bool isLoading,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) =>
      _getHeaders(header).then(
        (headers) => networkClient.makeRequest(
          endpoint,
          requestType,
          body?.removeEmptyValues(),
          query?.removeEmptyValues(),
          headers,
          isLoading,
        ),
      );

  @override
  Future<ResponseModel> listSounds({
    required bool isLoading,
    required Header header,
    String? search,
    String? categoryIds,
    int? page,
    int? pageSize,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.sounds,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryIds != null && categoryIds.isNotEmpty)
            'category_ids': categoryIds,
          if (page != null) 'page': page.toString(),
          if (pageSize != null) 'page_size': pageSize.toString(),
        },
      );

  @override
  Future<ResponseModel> listTrendingSounds({
    required bool isLoading,
    required Header header,
    int page = 1,
    int pageSize = 10,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.trending,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'page': page.toString(), 'page_size': pageSize.toString()},
      );

  @override
  Future<ResponseModel> listRecentSounds({
    required bool isLoading,
    required Header header,
    int limit = 10,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.recent,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'limit': limit.toString()},
      );

  @override
  Future<ResponseModel> listRecommendedSounds({
    required bool isLoading,
    required Header header,
    int page = 1,
    int pageSize = 10,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.recommended,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'page': page.toString(), 'page_size': pageSize.toString()},
      );

  @override
  Future<ResponseModel> listSavedSounds({
    required bool isLoading,
    required Header header,
    int skip = 0,
    int limit = 20,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.saved,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'skip': skip.toString(), 'limit': limit.toString()},
      );

  @override
  Future<ResponseModel> getSoundDetails({
    required bool isLoading,
    required Header header,
    required String soundId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.details,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'sound_id': soundId},
      );

  @override
  Future<ResponseModel> saveSound({
    required bool isLoading,
    required Header header,
    required Map<String, dynamic> body,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.save,
        requestType: NetworkRequestType.post,
        isLoading: isLoading,
        body: body,
      );

  @override
  Future<ResponseModel> unsaveSound({
    required bool isLoading,
    required Header header,
    required String soundId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.save,
        requestType: NetworkRequestType.delete,
        isLoading: isLoading,
        query: {'sound_id': soundId},
      );

  @override
  Future<ResponseModel> isSoundSaved({
    required bool isLoading,
    required Header header,
    required String soundId,
  }) =>
      _makeRequest(
        header: header,
        endpoint: SoundsApiEndPoints.isSaved,
        requestType: NetworkRequestType.get,
        isLoading: isLoading,
        query: {'sound_id': soundId},
      );
}
