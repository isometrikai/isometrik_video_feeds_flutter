import 'package:ism_video_reel_player/utils/enums.dart' show NetworkRequestType;

/// Request details passed to network override callbacks before each API call.
class NetworkRequestContext {
  const NetworkRequestContext({
    required this.apiUrl,
    required this.requestType,
    this.data,
    this.headers,
    this.queryParameters,
    this.pathSegments,
  });

  factory NetworkRequestContext.fromMap(Map<String, dynamic> map) =>
      NetworkRequestContext(
        apiUrl: map['apiUrl'] as String? ?? map['api_url'] as String? ?? '',
        requestType: _requestTypeFromValue(
          map['requestType'] ?? map['request_type'],
        ),
        data: map['data'],
        headers: _stringMapFromDynamic(map['headers']),
        queryParameters: map['queryParameters'] == null &&
                map['query_parameters'] == null
            ? null
            : Map<String, dynamic>.from(
                (map['queryParameters'] ?? map['query_parameters'])
                    as Map<dynamic, dynamic>,
              ),
        pathSegments: _stringListFromDynamic(
          map['pathSegments'] ?? map['path_segments'],
        ),
      );

  final String apiUrl;
  final NetworkRequestType requestType;
  final dynamic data;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  final List<String>? pathSegments;

  Map<String, dynamic> toMap() => {
        'apiUrl': apiUrl,
        'requestType': requestType.name,
        if (data != null) 'data': data,
        if (headers != null) 'headers': headers,
        if (queryParameters != null) 'queryParameters': queryParameters,
        if (pathSegments != null) 'pathSegments': pathSegments,
      };

  NetworkRequestContext copyWith({
    String? apiUrl,
    NetworkRequestType? requestType,
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    List<String>? pathSegments,
  }) =>
      NetworkRequestContext(
        apiUrl: apiUrl ?? this.apiUrl,
        requestType: requestType ?? this.requestType,
        data: data ?? this.data,
        headers: headers ?? this.headers,
        queryParameters: queryParameters ?? this.queryParameters,
        pathSegments: pathSegments ?? this.pathSegments,
      );

  static NetworkRequestType _requestTypeFromValue(dynamic value) {
    if (value is NetworkRequestType) return value;
    final name = value?.toString();
    if (name == null || name.isEmpty) return NetworkRequestType.get;
    return NetworkRequestType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => NetworkRequestType.get,
    );
  }

  static Map<String, String>? _stringMapFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is! Map) return null;
    return value.map(
      (key, dynamic item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static List<String>? _stringListFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map((item) => item.toString()).toList();
  }
}

/// Override query parameters before the request is sent.
typedef NetworkQueryOverride = Map<String, dynamic>? Function(
  NetworkRequestContext context,
);

/// Override request headers before the request is sent.
typedef NetworkHeaderOverride = Map<String, String>? Function(
  NetworkRequestContext context,
);

/// Override request body/fields before the request is sent.
typedef NetworkRequestDataOverride = dynamic Function(
  NetworkRequestContext context,
);

/// Override the API path segment before the request is sent.
typedef NetworkApiUrlOverride = String? Function(
  NetworkRequestContext context,
);

/// Override path segments appended to the API URL.
typedef NetworkPathSegmentsOverride = List<String>? Function(
  NetworkRequestContext context,
);

/// Configuration for intercepting and customizing SDK network calls.
///
/// Provide optional override callbacks on [SocialConfig.networkConfig]. Each
/// callback receives a [NetworkRequestContext] with the current API details and
/// may return updated values. Return `null` from a callback to keep the
/// SDK-provided value for that field.
///
/// **Usage example:**
/// ```dart
/// SocialConfig(
///   networkConfig: NetworkConfig(
///     headerOverride: (context) => {
///       ...?context.headers,
///       'x-custom-header': 'value',
///     },
///     queryOverride: (context) => {
///       ...?context.queryParameters,
///       'locale': 'en',
///     },
///     requestDataOverride: (context) {
///       if (context.data is Map<String, dynamic>) {
///         return {
///           ...context.data as Map<String, dynamic>,
///           'source': 'host-app',
///         };
///       }
///       return context.data;
///     },
///   ),
/// )
/// ```
class NetworkConfig {
  const NetworkConfig({
    this.queryOverride,
    this.headerOverride,
    this.requestDataOverride,
    this.apiUrlOverride,
    this.pathSegmentsOverride,
  });

  final NetworkQueryOverride? queryOverride;
  final NetworkHeaderOverride? headerOverride;
  final NetworkRequestDataOverride? requestDataOverride;
  final NetworkApiUrlOverride? apiUrlOverride;
  final NetworkPathSegmentsOverride? pathSegmentsOverride;

  NetworkConfig copyWith({
    NetworkQueryOverride? queryOverride,
    NetworkHeaderOverride? headerOverride,
    NetworkRequestDataOverride? requestDataOverride,
    NetworkApiUrlOverride? apiUrlOverride,
    NetworkPathSegmentsOverride? pathSegmentsOverride,
  }) =>
      NetworkConfig(
        queryOverride: queryOverride ?? this.queryOverride,
        headerOverride: headerOverride ?? this.headerOverride,
        requestDataOverride: requestDataOverride ?? this.requestDataOverride,
        apiUrlOverride: apiUrlOverride ?? this.apiUrlOverride,
        pathSegmentsOverride:
            pathSegmentsOverride ?? this.pathSegmentsOverride,
      );
}
