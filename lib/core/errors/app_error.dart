class AppError implements Exception {
  AppError(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class NetworkError extends AppError {
  NetworkError(super.message, {super.statusCode});
}

class ApiError extends AppError {
  ApiError(super.message, {super.statusCode});
}

class UnknownError extends AppError {
  UnknownError(super.message);
}

class TimeoutError extends AppError {
  TimeoutError(super.message);
}
