import 'package:ism_video_reel_player/data/data.dart';

abstract class PostApiService {
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  });
}
