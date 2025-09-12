class AppError implements Exception {
  AppError(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class NetworkError extends AppError {
  NetworkError(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

class ApiError extends AppError {
  ApiError(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

class UnknownError extends AppError {
  UnknownError(String message) : super(message);
}

class TimeoutError extends AppError {
  TimeoutError(String message) : super(message);
}
