import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/data/data.dart';

mixin AppMixin {
  void printLog<T>(
    T classname,
    String message, {
    StackTrace? stackTrace,
  }) {
    if (stackTrace != null) {
      log('$T: $message\nStack Trace = $stackTrace');
    } else {
      log('$T: $message');
    }
  }

  void logRequest<T>(T classname, http.Response response, dynamic data, Uri finalUrl,
      Map<String, String>? headers, ResponseModel res, int timeTaken) {
    final method = response.request?.method ?? 'GET';
    final url = response.request?.url.toString() ?? finalUrl.toString();
    /* final requestStartTime = DateTime.now().subtract(Duration(
        milliseconds: response.request?.headers['x-request-time'] != null
            ? int.parse(response.request!.headers['x-request-time']!)
            : 0));
    final responseTime = DateTime.now().difference(requestStartTime);*/

    // Construct headers
    var headerString = '';
    if (headers != null) {
      headerString = headers.entries.map((e) => '-H "${e.key}: ${e.value}"').join(' ');
    }

    // Construct body
    var bodyString = '';
    if (method != 'GET' && data != null) {
      bodyString = "-d '${jsonEncode(data)}'";
    }

    // Construct the final cURL command (Postman-compatible)
    final curlCommand = 'curl -X $method $headerString $bodyString "$url"';

    printLog(
      classname,
      '\nGenerated cURL :\n$curlCommand\n\nResponse:\nStatus Code: ${res.statusCode}\nResponse Data: ${res.data}',
    );
  }
}
