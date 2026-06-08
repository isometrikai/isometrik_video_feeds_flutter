import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class BlockUserUseCase extends BaseUseCase {
  BlockUserUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> block({
    required bool isLoading,
    required String blockedId,
    String reason = 'blocked',
  }) async =>
      await super.execute(() async {
        final response = await _repository.blockUser(
          isLoading: isLoading,
          blockedId: blockedId,
          reason: reason,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}

class GetBlockedUsersUseCase extends BaseUseCase {
  GetBlockedUsersUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<BlockedUsersListResponse?>> getBlockedUsers({
    required bool isLoading,
    required int page,
    required int pageSize,
    String? search,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getBlockedUsers(
          isLoading: isLoading,
          page: page,
          pageSize: pageSize,
          search: search,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}

class UnblockUserUseCase extends BaseUseCase {
  UnblockUserUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> unblock({
    required bool isLoading,
    required String blockedId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.unblockUser(
          isLoading: isLoading,
          blockedId: blockedId,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}
