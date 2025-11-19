import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class SearchTagUseCase extends BaseUseCase {
  SearchTagUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<HashTagResponse?>> executeSearchTag({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
  }) async =>
      await super.execute(
        () async {
          final response = await _repository.searchTag(
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
