import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Centralized error mapping + presentation helpers.
///
/// This is used to normalize arbitrary thrown exceptions into the SDK's [AppError]
/// type and to optionally render a user-visible error UI.
class ErrorHandler {
  /// Converts any thrown [error] to an [AppError] and logs the failure.
  ///
  /// - [error]: The thrown error/exception.
  /// - [stackTrace]: Stack trace captured at the throw site.
  static AppError handleError(dynamic error, StackTrace stackTrace) {
    // Log the error (you can implement a more sophisticated logging mechanism)
    _logError(error, stackTrace);

    if (error is NetworkError) {
      return NetworkError(error.message, statusCode: error.statusCode);
    } else if (error is ApiError) {
      return AppError(error.message, statusCode: error.statusCode);
    } else {
      return AppError('An unexpected error occurred: $error', statusCode: 500);
    }
  }

  /// Logs [error] and [stackTrace] to the SDK logging sink.
  static void _logError(dynamic error, StackTrace stackTrace) {
    // Implement logging logic here (e.g., send to a logging service)
    AppLog.error('Error logged: $error', stackTrace);
  }

  /// Displays an [appError] to the user (dialog/snackbar/etc.) when allowed.
  ///
  /// - [appError]: Normalized SDK error to show.
  /// - [message]: Optional message override (useful for custom copy).
  /// - [context]: Optional context (kept for API compatibility).
  /// - [errorViewType]: Presentation strategy (defaults to dialog).
  /// - [isNeedToShowError]: Forces showing errors (even non-network errors).
  static void showAppError({
    required AppError? appError,
    String? message,
    BuildContext? context,
    ErrorViewType errorViewType = ErrorViewType.dialog,
    bool isNeedToShowError = false,
  }) {
    if (isNeedToShowError || appError is NetworkError) {
      Utility.showAppError(
        message: message ?? appError?.message ?? '',
        errorViewType: errorViewType,
      );
    }
  }
}
