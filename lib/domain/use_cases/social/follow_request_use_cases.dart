import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetIncomingFollowRequestsUseCase extends BaseUseCase {
  GetIncomingFollowRequestsUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<FollowRequestsListResponse?>> getIncoming({
    required bool isLoading,
    required int page,
    required int pageSize,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getFollowRequestsIncoming(
          isLoading: isLoading,
          page: page,
          pageSize: pageSize,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}

class GetOutgoingFollowRequestsUseCase extends BaseUseCase {
  GetOutgoingFollowRequestsUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<FollowRequestsListResponse?>> getOutgoing({
    required bool isLoading,
    required int page,
    required int pageSize,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getFollowRequestsOutgoing(
          isLoading: isLoading,
          page: page,
          pageSize: pageSize,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}

class AcceptFollowRequestUseCase extends BaseUseCase {
  AcceptFollowRequestUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> accept({
    required bool isLoading,
    required String requestId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.acceptFollowRequest(
          isLoading: isLoading,
          requestId: requestId,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}

class DeclineFollowRequestUseCase extends BaseUseCase {
  DeclineFollowRequestUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> decline({
    required bool isLoading,
    required String requestId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.declineFollowRequest(
          isLoading: isLoading,
          requestId: requestId,
        );
        final ok = response.responseCode == 200 || response.responseCode == 201;
        return ApiResult(data: ok ? response.data : null);
      });
}

class CancelOutgoingFollowRequestUseCase extends BaseUseCase {
  CancelOutgoingFollowRequestUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> cancel({
    required bool isLoading,
    required String targetId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.cancelOutgoingFollowRequest(
          isLoading: isLoading,
          targetId: targetId,
        );
        final code = response.responseCode;
        final ok = code == 200 || code == 201 || code == 204;
        if (!ok) {
          return ApiResult(data: null, statusCode: code);
        }
        return ApiResult(
          data: response.data ?? ResponseClass.success(''),
        );
      });
}
