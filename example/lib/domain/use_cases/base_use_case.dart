import 'package:ism_video_reel_player_example/core/core.dart';

abstract class BaseUseCase {
  Future<ApiResult<T>> execute<T>(
      Future<ApiResult<T>> Function() action) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      final appError = handleError(e, stackTrace);
      return ApiResult(
        error: appError,
        statusCode: appError.statusCode,
      );
    }
  }

  // Define the handleError method here or import it from your error handler
  AppError handleError(Object e, StackTrace stackTrace) =>
      ErrorHandler.handleError(e, stackTrace);
}
