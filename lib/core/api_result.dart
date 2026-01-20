import 'package:ism_video_reel_player/core/core.dart';

/// A typed wrapper for API call results.
///
/// An [ApiResult] can represent either:
/// - a successful response ([data] is non-null), or
/// - a failure ([error] is non-null).
///
/// The [statusCode] is included for convenience when the transport layer
/// provides it.
class ApiResult<T> {
  /// Creates an [ApiResult].
  ///
  /// - [data]: The decoded response payload for successful calls.
  /// - [error]: The error for failed calls.
  /// - [statusCode]: HTTP status code when available (defaults to 200).
  ApiResult({this.data, this.error, this.statusCode = 200});

  /// The response payload for successful calls.
  final T? data;

  /// Error information for failed calls.
  final AppError? error;

  /// HTTP status code when available.
  final int? statusCode;

  /// Whether this result represents a successful call.
  bool get isSuccess => data != null;

  /// Whether this result represents a failed call.
  bool get isError => error != null;
}
