// coverage:ignore-file
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// handles network call for all the APIs and handle the error status codes
class NetworkClient with AppMixin {
  NetworkClient({
    required this.baseUrl,
  });

  final String baseUrl;
  final localStorageManager = isrGetIt<LocalStorageManager>();

  final networkClient = http.Client();

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
    final isNetworkAvailable = await Utility.isNetworkAvailable;
    if (isNetworkAvailable) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      var responseModel = await makeFinalRequest(
        apiUrl,
        request,
        data,
        queryParameters,
        isLoading,
        headers,
        pathSegments,
      );
      if (responseModel.statusCode == 406) {
        _isRefreshing = true;
        final newToken = refreshToken();
        _isRefreshing = false;
        if (headers?.containsKey('Authorization') == true) {
          headers?['Authorization'] = newToken;
        }
        if (headers?.containsKey('authorization') == true) {
          headers?['authorization'] = newToken;
        }
        responseModel = await makeFinalRequest(
          apiUrl,
          request,
          data,
          queryParameters,
          isLoading,
          headers,
          pathSegments,
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

      logRequest(this, response, data, finalUrl, headers, res, 0);

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

  void _logRequest(http.Response response, dynamic data, Uri finalUrl, Map<String, String>? headers,
      ResponseModel res) {
    printLog(
      this,
      '\nMethod: ${response.request?.method}\nURL: ${response.request?.url}\nBody: ${jsonEncode(data)}\nQuery Params: ${finalUrl.queryParameters}\nHeaders: $headers\nResponse:\nStatus Code: ${res.statusCode}\nResponse Data: ${res.data}',
    );
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
      var uri = baseUrl + apiUrl;
      if (isLoading) Utility.showLoader();
      final finalUrl = Uri.parse(uri).replace(queryParameters: queryParameters);
      var request = http.MultipartRequest('POST', finalUrl);
      if (multipartFiles != null && multipartFiles.isNotEmpty) {
        for (var file in multipartFiles) {
          request.files.add(file);
        }
      }
      request.fields.addAll(data);
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (isLoading) Utility.closeProgressDialog();
      var res = returnResponse(response);
      if (multipartFiles != null && multipartFiles.isNotEmpty) {
        printLog(
          this,
          'Method: ${response.request?.method}\nURL :- ${response.request?.url.toString()}\nbody :- ${jsonEncode(data)}\nMultiPart :-${request.files.first.filename}\nqueryParams :- ${finalUrl.queryParameters}\nHeaders :- $headers\nResponse :-\nStatus Code :- ${res.statusCode}\nResponse Data :- ${res.data}',
        );
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
    switch (requestType) {
      case NetworkRequestType.get:
        return await http.Client()
            .get(
              finalUrl,
              headers: headers,
            )
            .timeout(AppConstants.timeOutDuration);
      case NetworkRequestType.post:
        return await http.Client()
            .post(
              finalUrl,
              body: jsonEncode(data),
              headers: headers,
            )
            .timeout(AppConstants.timeOutDuration);
      case NetworkRequestType.put:
        return await http.Client()
            .put(
              finalUrl,
              body: jsonEncode(data),
              headers: headers,
            )
            .timeout(AppConstants.timeOutDuration);
      case NetworkRequestType.patch:
        return await http.Client()
            .patch(
              finalUrl,
              body: jsonEncode(data),
              headers: headers,
            )
            .timeout(AppConstants.timeOutDuration);
      case NetworkRequestType.delete:
        return await http.Client()
            .delete(
              finalUrl,
              body: jsonEncode(data),
              headers: headers,
            )
            .timeout(AppConstants.timeOutDuration);
    }
  }
}
