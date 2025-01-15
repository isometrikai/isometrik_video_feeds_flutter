import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class PostViewModel extends BaseViewModel {
  final _repository = ismGetIt<PostRepository>();

  @override
  BaseRepository getRepository() => _repository;

  Future<PostResponse?> getFollowingPost({required bool isLoading}) async {
    try {
      // await rootBundle.loadString('AssetManifest.json').then(print);
      final jsonString = await rootBundle.loadString(AssetConstants.postResponseJson);
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
        IsmVideoReelUtility.showInfoDialog(response);
        return null;
      }
      return createPostResponseFromJson(response.data);
    } catch (e, stackTrace) {
      printLog(this, e.toString(), stackTrace: stackTrace);
      return null;
    }
  }
}
