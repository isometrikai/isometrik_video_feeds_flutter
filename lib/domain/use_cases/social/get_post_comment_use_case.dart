import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetPostCommentUseCase extends BaseUseCase {
  GetPostCommentUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<CommentsResponse?>> executeGetPostComment({
    required bool isLoading,
    required String postId,
    String? parentCommitId,
    int? page = 1,
    int? pageLimit = 50,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getPostComments(
          isLoading: isLoading,
          postId: postId,
          parentCommitId: parentCommitId,
          page: page,
          pageLimit: pageLimit,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
