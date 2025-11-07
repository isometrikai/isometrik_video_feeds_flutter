import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class GetTaggedPostsUseCase extends BaseUseCase {
  GetTaggedPostsUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<TimelineResponse?>> executeGetTaggedPosts({
    required bool isLoading,
    required String tagValue,
    required TagType tagType,
    required int page,
    required int pageLimit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getTaggedPosts(
          isLoading: isLoading,
          page: page,
          pageLimit: pageLimit,
          tagValue: tagValue,
          tagType: tagType,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
