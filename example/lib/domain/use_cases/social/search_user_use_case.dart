import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class SearchUserUseCase extends BaseUseCase {
  SearchUserUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<SearchUserResponse?>> executeSearchUser({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
  }) async =>
      await super.execute(
        () async {
          final response = await _repository.searchUser(
            isLoading: isLoading,
            limit: limit,
            page: page,
            searchText: searchText,
          );
          return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null,
          );
        },
      );
}
