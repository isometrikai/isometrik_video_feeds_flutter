/// Base exception type used across the SDK.
///
/// - [message] is a human-readable description.
/// - [statusCode] is an optional transport/status code when applicable.
class AppError implements Exception {
  /// Creates an [AppError].
  ///
  /// - [message]: Human-readable error message.
  /// - [statusCode]: Optional status/response code if available.
  AppError(this.message, {this.statusCode});

  /// Human-readable error message.
  final String message;

  /// Optional status/response code associated with the error.
  final int? statusCode;
}

/// Error thrown when the device cannot reach the network or connectivity fails.
class NetworkError extends AppError {
  /// Creates a [NetworkError].
  NetworkError(super.message, {super.statusCode});
}

/// Error thrown when the API returns a non-successful response.
class ApiError extends AppError {
  /// Creates an [ApiError].
  ApiError(super.message, {super.statusCode});
}

/// Error thrown when an unexpected/unknown failure occurs.
class UnknownError extends AppError {
  /// Creates an [UnknownError].
  UnknownError(super.message);
}

/// Error thrown when an operation times out.
class TimeoutError extends AppError {
  /// Creates a [TimeoutError].
  TimeoutError(super.message);
}
