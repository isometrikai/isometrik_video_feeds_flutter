import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class CreatePostUseCase extends BaseUseCase {
  CreatePostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<CreatePostResponse?>> executeCreatePost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.createPost(
          isLoading: isLoading,
          createPostRequest: createPostRequest,
        );
        return ApiResult(
            data: response.responseCode == 201 ? response.data : null);
      });

  Future<ApiResult<CreatePostResponse?>> executeEditPost({
    required bool isLoading,
    required String postId,
    Map<String, dynamic>? editPostRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.editPost(
          isLoading: isLoading,
          postId: postId,
          editPostRequest: editPostRequest,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}

/* create post request map example
{
  "caption": "Adventures from our weekend trip - swipe to see photos and videos! 🏔️ #Travel #Weekend @friendname",
  "media": [
    {
      "asset_id": "asset_567890",
      "description": "Morning view from our cabin",
      "height": 1080,
      "media_type": "image",
      "position": 1,
      "preview_url": "https://cdn.example.com/media/previews/image1_preview.jpg",
      "url": "https://cdn.example.com/media/image1.jpg",
      "width": 1920
    },
    {
      "asset_id": "asset_567891",
      "description": "Hiking up the mountain trail",
      "duration": 30.5,
      "height": 1080,
      "media_type": "video",
      "position": 2,
      "preview_url": "https://cdn.example.com/media/previews/video1_preview.jpg",
      "url": "https://cdn.example.com/media/video1.mp4",
      "width": 1920
    }
  ],
  "previews": [
    {
      "media_type": "image",
      "position": 1,
      "url": "https://cdn.example.com/media/previews/post_preview1.jpg"
    }
  ],
  "settings": {
    "advance_interval": 5,
    "age_restriction": false,
    "auto_advance": true,
    "comments_enabled": true,
    "duet_enabled": true,
    "save_enabled": true,
    "stitch_enabled": true
  },
  "sound_id": "sound_123",
  "sound_snapshot": {
    "captured_at": "2024-03-20T10:00:00Z",
    "end_time": 45,
    "fade_in": 1,
    "fade_out": 2,
    "loop": false,
    "original_status": "approved",
    "segment_duration": 30,
    "start_time": 15,
    "volume": 0.8
  },
  "status": "draft",
  "tags": {
    "hashtags": [
      {
        "position": {
          "end": 58,
          "start": 51
        },
        "tag": "Travel"
      }
    ],
    "mentions": [
      {
        "position": {
          "end": 79,
          "start": 68
        },
        "user_id": "user_456",
        "username": "@friendname"
      }
    ],
    "places": [],
    "products": []
  },
  "type": "carousel",
  "visibility": "public"
}
* */
