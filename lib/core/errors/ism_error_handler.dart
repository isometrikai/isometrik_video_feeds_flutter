import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class IsmErrorHandler {
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

  static void _logError(dynamic error, StackTrace stackTrace) {
    // Implement logging logic here (e.g., send to a logging service)
    AppLog.error('Error logged: $error', stackTrace);
  }

  static void showAppError({
    required AppError? appError,
    String? message,
    BuildContext? context,
    ErrorViewType errorViewType = ErrorViewType.dialog,
    bool isNeedToShowError = false,
  }) {
    if (isNeedToShowError || appError is NetworkError) {
      IsrVideoReelUtility.showAppError(message: message ?? appError?.message ?? '', errorViewType: errorViewType);
    }
  }
}
