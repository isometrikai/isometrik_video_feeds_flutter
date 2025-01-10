import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class PostViewModel extends BaseViewModel {
  final _repository = kGetIt<PostRepository>();

  @override
  BaseRepository getRepository() => _repository;

  Future<PostResponse?> getFollowingPost({required bool isLoading}) async {
    try {
      final jsonString = await rootBundle.loadString('assets/json/post_response.json');
      return postResponseFromJson(jsonString);
    } catch (e, stackTrace) {
      printLog(this, e.toString(), stackTrace: stackTrace);
      return null;
    }
  }

  Future<CreatePostResponse?> createPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  }) async {
    try {
      var response = await _repository.createPost(
        isLoading: true,
        createPostRequest: createPostRequest,
      );
      if (response.hasError) {
        Utility.showInfoDialog(response);
        return null;
      }
      return createPostResponseFromJson(response.data);
    } catch (e, stackTrace) {
      printLog(this, e.toString(), stackTrace: stackTrace);
      return null;
    }
  }
}
