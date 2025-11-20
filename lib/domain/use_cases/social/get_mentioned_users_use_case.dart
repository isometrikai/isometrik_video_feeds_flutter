import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetMentionedUsersUseCase extends BaseUseCase {
  GetMentionedUsersUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<SearchUserResponse?>> executeGetMentionedUser({
    required bool isLoading,
    required String postId,
    required int page,
    required int pageLimit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getMentionedUsers(
          isLoading: isLoading,
          postId: postId,
          page: page,
          pageLimit: pageLimit,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
