import 'package:ism_video_reel_player/core/core.dart';

class ApiResult<T> {
  ApiResult({this.data, this.error, this.statusCode = 200});

  final T? data;
  final AppError? error;
  final int? statusCode;

  bool get isSuccess => data != null;

  bool get isError => error != null;
}
