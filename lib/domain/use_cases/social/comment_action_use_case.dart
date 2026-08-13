import 'dart:convert';

import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';

class CommentActionUseCase extends BaseUseCase {
  CommentActionUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass>> executeCommentAction({
    required bool isLoading,
    required Map<String, dynamic> commentRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.doCommentAction(
          isLoading: isLoading,
          commentRequest: commentRequest,
        );
        final statusCode =
            response.responseCode ?? response.data?.statusCode ?? 500;
        final isOk = statusCode == 200 ||
            statusCode == 201 ||
            response.data?.statusCode == 200;
        if (isOk && response.data != null) {
          return ApiResult(
            data: response.data,
            statusCode: statusCode,
          );
        }

        final message = _errorMessage(response.data?.data, statusCode);
        return ApiResult(
          error: statusCode == IsrAppConstants.noInternetErrorCode
              ? NetworkError(message, statusCode: statusCode)
              : AppError(message, statusCode: statusCode),
          statusCode: statusCode,
        );
      });

  static String _errorMessage(String? rawData, int statusCode) {
    final data = rawData?.trim() ?? '';
    if (data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map && decoded['message'] != null) {
          final message = decoded['message'].toString().trim();
          if (message.isNotEmpty) return message;
        }
      } catch (_) {
        if (data.isNotEmpty) return data;
      }
    }
    if (statusCode == IsrAppConstants.noInternetErrorCode) {
      return IsrTranslationFile.noInternet;
    }
    return IsrTranslationFile.somethingWentWrong;
  }
}
