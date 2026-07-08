// coverage:ignore-file
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/models/network_config.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:talker/talker.dart';

/// handles network call for all the APIs and handle the error status codes
class NetworkClient with AppMixin {
  NetworkClient({
    required this.baseUrl,
  }) {
    _client = _getOrCreateClient();
  }

  // Static shared HttpClient for connection reuse across all instances
  static HttpClient? _sharedHttpClient;
  static IOClient? _sharedIOClient;

  /// Creates or returns the shared IOClient for connection reuse
  static IOClient _getOrCreateClient() {
    if (_sharedIOClient != null) return _sharedIOClient!;

    _sharedHttpClient = HttpClient()
      ..connectionTimeout = IsrAppConstants.timeOutDuration
      ..idleTimeout = const Duration(minutes: 15) // Keep connections alive longer
      ..maxConnectionsPerHost = 6 // Increase max connections
      ..autoUncompress = true; // Enable automatic decompression

    // Enable HTTP/1.1 keep-alive and connection reuse
    _sharedHttpClient!.findProxy = (uri) => 'DIRECT';

    _sharedIOClient = IOClient(_sharedHttpClient!);
    return _sharedIOClient!;
  }

  late final IOClient _client;

  final String baseUrl;
  Talker? get _talker => IsmInjectionUtils.getOtherClassIfPresent();
  final localStorageManager = isrGetIt<LocalStorageManager>();

  var _isRefreshing = false;
  var responseCode = 200;

  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  Future<ResponseModel> makeRequest(
    String apiUrl,
    NetworkRequestType request,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool isLoading, {
    List<String>? pathSegments,
  }) async {
    final resolvedRequest = _applyNetworkOverrides(
      apiUrl: apiUrl,
      request: request,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      pathSegments: pathSegments,
    );
    final isNetworkAvailable = await Utility.isNetworkAvailable;
    if (isNetworkAvailable) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      var responseModel = await makeFinalRequest(
        resolvedRequest.apiUrl,
        request,
        resolvedRequest.data,
        resolvedRequest.queryParameters,
        isLoading,
        resolvedRequest.headers,
        resolvedRequest.pathSegments,
      );
      if (responseModel.statusCode == 406) {
        _isRefreshing = true;
        final newToken = refreshToken();
        _isRefreshing = false;
        if (resolvedRequest.headers?.containsKey('Authorization') == true) {
          resolvedRequest.headers?['Authorization'] = newToken;
        }
        if (resolvedRequest.headers?.containsKey('authorization') == true) {
          resolvedRequest.headers?['authorization'] = newToken;
        }
        responseModel = await makeFinalRequest(
          resolvedRequest.apiUrl,
          request,
          resolvedRequest.data,
          resolvedRequest.queryParameters,
          isLoading,
          resolvedRequest.headers,
          resolvedRequest.pathSegments,
        );
        _isRefreshing = false;
      }
      return responseModel;
    } else {
      throw AppError(IsrTranslationFile.noInternet, statusCode: 1000);
    }
  }

  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  Future<ResponseModel> makeFinalRequest(
    String url,
    NetworkRequestType request,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isLoading,
    Map<String, String>? headers,
    List<String>? pathSegments,
  ) async {
    if (!(await Utility.isNetworkAvailable)) {
      return const ResponseModel(
        data: '{"message": "No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = baseUrl + url;
    var finalUrl = Uri.parse(uri);
    finalUrl = Uri.parse(uri).replace(
      pathSegments: [
        ...finalUrl.pathSegments, // keep existing segments
        if (pathSegments != null) ...pathSegments, // append new segments
      ],
      queryParameters: queryParameters,
    );

    if (isLoading) Utility.showLoader();

    try {
      final response = await getFinalResponse(finalUrl, headers, data, request);
      if (isLoading) Utility.closeProgressDialog();
      final res = returnResponse(response);

      logRequest(this, response, data, finalUrl, headers, res, 0, _talker);

      if (res.hasError) {
        return _proceedWithErrorResponse(res, response);
      }
      return res;
    } on TimeoutException {
      throw TimeoutError(IsrTranslationFile.timeoutError);
    } catch (error, stackTrace) {
      if (isLoading) Utility.closeProgressDialog();
      Utility.debugCatchLog(error: error, stackTrace: stackTrace);
      if (error is AppError) {
        rethrow;
      }
      throw NetworkError(error.toString());
    }
  }

  ResponseModel _proceedWithErrorResponse(ResponseModel res, http.Response response) {
    final message = Utility.getErrorMessage(res);
    if (res.statusCode == 401) {
      return res;
    } else {
      if (response.statusCode == 204) {
        return res;
      } else {
        throw ApiError(message, statusCode: res.statusCode);
      }
    }
  }

  /// Method to return the API response based upon the status code of the server
  ResponseModel returnResponse(http.Response response) {
    final statusCode = response.statusCode;
    final isSuccessful = statusCode >= 200 && statusCode <= 307;

    return ResponseModel(
      data: response.body,
      hasError: !isSuccessful,
      statusCode: statusCode,
    );
    // switch (response.statusCode) {
    //   case 200:
    //   case 201:
    //   case 202:
    //   case 203:
    //   case 205:
    //   case 208:
    //   case 307:
    //     return ResponseModel(
    //       data: response.body,
    //       hasError: false,
    //       statusCode: response.statusCode,
    //     );
    //   case 204:
    //     return ResponseModel(
    //       data: response.body,
    //       hasError: response.request?.method == 'GET' && response.request!.url.path == CartApiEndPoints.getCartDetails,
    //       statusCode: response.statusCode,
    //     );
    //   case 401:
    //
    //     /// unauthorized
    //     localStorageManager.saveValue(LocalStorageKeys.isLoggedIn, false, SavedValueDataType.bool);
    //     // localStorageManager.clearData();
    //     // localStorageManager.deleteAllSecuredValues();
    //     if (response.request!.url.path != AuthEndPoints.signIn) {
    //       RouteManagement.goToLogin();
    //     }
    //
    //     return ResponseModel(
    //       data: response.body,
    //       hasError: true,
    //       statusCode: response.statusCode,
    //     );
    //   case 409:
    //   case 404:
    //   case 411:
    //   case 412:
    //   case 422:
    //   case 500:
    //   case 504:
    //   case 522:
    //     return ResponseModel(
    //       data: response.body,
    //       hasError: true,
    //       statusCode: response.statusCode,
    //     );
    //   default:
    //     return ResponseModel(
    //       data: response.body,
    //       hasError: true,
    //       statusCode: response.statusCode,
    //     );
    // }
  }

  /// calls api to refresh the token
  String refreshToken() => '';

  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  Future<ResponseModel> makeMultiPartRequest(
    String apiUrl,
    NetworkRequestType request,
    Map<String, dynamic>? queryParameters,
    Map<String, String> data,
    bool isLoading,
    List<http.MultipartFile>? multipartFiles,
    Map<String, String> headers,
  ) async {
    if (await Utility.isNetworkAvailable) {
      final resolvedRequest = _applyNetworkOverrides(
        apiUrl: apiUrl,
        request: request,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      );
      var uri = baseUrl + resolvedRequest.apiUrl;
      if (isLoading) Utility.showLoader();
      final finalUrl = Uri.parse(uri)
          .replace(queryParameters: resolvedRequest.queryParameters);
      final multipartRequest = http.MultipartRequest('POST', finalUrl);
      if (multipartFiles != null && multipartFiles.isNotEmpty) {
        for (var file in multipartFiles) {
          multipartRequest.files.add(file);
        }
      }
      final multipartData = resolvedRequest.data is Map<String, String>
          ? resolvedRequest.data as Map<String, String>
          : data;
      multipartRequest.fields.addAll(multipartData);
      multipartRequest.headers
          .addAll(_sanitizeHeaders(resolvedRequest.headers ?? headers));

      final streamedResponse = await multipartRequest.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (isLoading) Utility.closeProgressDialog();
      var res = returnResponse(response);
      if (multipartFiles != null && multipartFiles.isNotEmpty) {
        final msg =
            'Method: ${response.request?.method}\nURL :- ${response.request?.url.toString()}\nbody :- ${jsonEncode(data)}\nMultiPart :-${multipartRequest.files.first.filename}\nqueryParams :- ${finalUrl.queryParameters}\nHeaders :- $headers\nResponse :-\nStatus Code :- ${res.statusCode}\nResponse Data :- ${res.data}';
        _talker?.log(msg);
        printLog(this, msg);
      }
      return res;
    } else {
      return const ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }
  }

  Future<http.Response> getFinalResponse(
      Uri finalUrl, Map<String, String>? headers, data, NetworkRequestType requestType) async {
    final safeHeaders = headers != null ? _sanitizeHeaders(headers) : null;

    switch (requestType) {
      case NetworkRequestType.get:
        return await _client
            .get(
              finalUrl,
              headers: safeHeaders,
            )
            .timeout(IsrAppConstants.timeOutDuration);
      case NetworkRequestType.post:
        return _client
            .post(
              finalUrl,
              body: jsonEncode(data),
              headers: safeHeaders,
            )
            .timeout(IsrAppConstants.timeOutDuration);
      case NetworkRequestType.put:
        return _client
            .put(
              finalUrl,
              body: jsonEncode(data),
              headers: safeHeaders,
            )
            .timeout(IsrAppConstants.timeOutDuration);
      case NetworkRequestType.patch:
        return _client
            .patch(
              finalUrl,
              body: jsonEncode(data),
              headers: safeHeaders,
            )
            .timeout(IsrAppConstants.timeOutDuration);
      case NetworkRequestType.delete:
        return _client
            .delete(
              finalUrl,
              body: jsonEncode(data),
              headers: safeHeaders,
            )
            .timeout(IsrAppConstants.timeOutDuration);
    }
  }

  /// Percent-encodes any non-ASCII characters in a header value so it
  /// satisfies RFC 7230 (header field values must be visible US-ASCII).
  /// Values that are already ASCII are returned unchanged.
  String _sanitizeHeaderValue(String value) {
    for (final unit in value.codeUnits) {
      if (unit > 0x7F) {
        return Uri.encodeComponent(value);
      }
    }
    return value;
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) =>
      headers.map((k, v) => MapEntry(k, _sanitizeHeaderValue(v)));

  _ResolvedNetworkRequest _applyNetworkOverrides({
    required String apiUrl,
    required NetworkRequestType request,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    List<String>? pathSegments,
  }) {
    final networkConfig = IsrVideoReelConfig.networkConfig;
    if (networkConfig == null) {
      return _ResolvedNetworkRequest(
        apiUrl: apiUrl,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        pathSegments: pathSegments,
      );
    }

    var context = NetworkRequestContext(
      apiUrl: apiUrl,
      requestType: request,
      data: data,
      headers: headers,
      queryParameters: queryParameters,
      pathSegments: pathSegments,
    );

    final resolvedApiUrl = networkConfig.apiUrlOverride?.call(context) ?? apiUrl;
    context = context.copyWith(apiUrl: resolvedApiUrl);

    final resolvedHeaders =
        networkConfig.headerOverride?.call(context) ?? headers;
    context = context.copyWith(headers: resolvedHeaders);

    final resolvedQuery =
        networkConfig.queryOverride?.call(context) ?? queryParameters;
    context = context.copyWith(queryParameters: resolvedQuery);

    final resolvedPathSegments =
        networkConfig.pathSegmentsOverride?.call(context) ?? pathSegments;
    context = context.copyWith(pathSegments: resolvedPathSegments);

    final resolvedData =
        networkConfig.requestDataOverride?.call(context) ?? data;

    return _ResolvedNetworkRequest(
      apiUrl: resolvedApiUrl,
      data: resolvedData,
      queryParameters: resolvedQuery,
      headers: resolvedHeaders,
      pathSegments: resolvedPathSegments,
    );
  }

  void dispose() {
    _client.close();
  }
}

class _ResolvedNetworkRequest {
  const _ResolvedNetworkRequest({
    required this.apiUrl,
    required this.data,
    required this.queryParameters,
    required this.headers,
    required this.pathSegments,
  });

  final String apiUrl;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
  final List<String>? pathSegments;
}
