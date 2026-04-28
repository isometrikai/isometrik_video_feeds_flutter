import 'package:bloc/bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

part 'follow_requests_state.dart';

/// Coordinates follow-request lists and actions. Use cases are injected (SDK pattern).
class FollowRequestsCubit extends Cubit<FollowRequestsState> {
  FollowRequestsCubit({
    required GetIncomingFollowRequestsUseCase getIncomingFollowRequestsUseCase,
    required GetOutgoingFollowRequestsUseCase getOutgoingFollowRequestsUseCase,
    required AcceptFollowRequestUseCase acceptFollowRequestUseCase,
    required DeclineFollowRequestUseCase declineFollowRequestUseCase,
    required CancelOutgoingFollowRequestUseCase
        cancelOutgoingFollowRequestUseCase,
  })  : _getIncoming = getIncomingFollowRequestsUseCase,
        _getOutgoing = getOutgoingFollowRequestsUseCase,
        _accept = acceptFollowRequestUseCase,
        _decline = declineFollowRequestUseCase,
        _cancelOutgoing = cancelOutgoingFollowRequestUseCase,
        super(
          const FollowRequestsState(
            incomingLoading: true,
            outgoingLoading: true,
          ),
        );

  static const int _pageSize = 20;

  final GetIncomingFollowRequestsUseCase _getIncoming;
  final GetOutgoingFollowRequestsUseCase _getOutgoing;
  final AcceptFollowRequestUseCase _accept;
  final DeclineFollowRequestUseCase _decline;
  final CancelOutgoingFollowRequestUseCase _cancelOutgoing;

  /// Call once when the screen opens.
  void loadInitial() {
    loadIncoming(refresh: true);
    loadOutgoing(refresh: true);
  }

  Future<void> loadIncoming({required bool refresh}) async {
    if (refresh) {
      emit(state.copyWith(
        incomingPage: 1,
        incomingHasMore: true,
        incomingLoading: true,
      ));
    } else if (!state.incomingHasMore) {
      return;
    } else {
      emit(state.copyWith(incomingLoading: true));
    }

    final pageToLoad = refresh ? 1 : state.incomingPage;
    final res = await _getIncoming.getIncoming(
      isLoading: false,
      page: pageToLoad,
      pageSize: _pageSize,
    );

    if (isClosed) return;

    var next = state;
    final data = res.data;
    if (data != null) {
      final list = refresh
          ? List<FollowRequestItem>.from(data.items)
          : [...state.incoming, ...data.items];
      next = state.copyWith(
        incoming: list,
        incomingHasMore: data.hasMore,
        incomingPage: data.hasMore ? pageToLoad + 1 : pageToLoad,
        incomingLoading: false,
      );
    } else {
      next = state.copyWith(incomingLoading: false);
    }
    emit(next);
  }

  Future<void> loadOutgoing({required bool refresh}) async {
    if (refresh) {
      emit(state.copyWith(
        outgoingPage: 1,
        outgoingHasMore: true,
        outgoingLoading: true,
      ));
    } else if (!state.outgoingHasMore) {
      return;
    } else {
      emit(state.copyWith(outgoingLoading: true));
    }

    final pageToLoad = refresh ? 1 : state.outgoingPage;
    final res = await _getOutgoing.getOutgoing(
      isLoading: false,
      page: pageToLoad,
      pageSize: _pageSize,
    );

    if (isClosed) return;

    var next = state;
    final data = res.data;
    if (data != null) {
      final list = refresh
          ? List<FollowRequestItem>.from(data.items)
          : [...state.outgoing, ...data.items];
      next = state.copyWith(
        outgoing: list,
        outgoingHasMore: data.hasMore,
        outgoingPage: data.hasMore ? pageToLoad + 1 : pageToLoad,
        outgoingLoading: false,
      );
    } else {
      next = state.copyWith(outgoingLoading: false);
    }
    emit(next);
  }

  Future<void> acceptRequest(FollowRequestItem item) async {
    final ok = await _accept.accept(
      isLoading: true,
      requestId: item.id,
    );
    if (ok.isSuccess && !isClosed) {
      emit(state.copyWith(
        incoming: state.incoming.where((e) => e.id != item.id).toList(),
      ));
    }
  }

  Future<void> declineRequest(FollowRequestItem item) async {
    final ok = await _decline.decline(
      isLoading: true,
      requestId: item.id,
    );
    if (ok.isSuccess && !isClosed) {
      emit(state.copyWith(
        incoming: state.incoming.where((e) => e.id != item.id).toList(),
      ));
    }
  }

  Future<void> cancelOutgoingRequest(FollowRequestItem item) async {
    final userId = item.user.targetId ?? '';
    if (userId.isEmpty) return;
    final ok = await _cancelOutgoing.cancel(
      isLoading: true,
      targetId: userId,
    );
    if (ok.isSuccess && !isClosed) {
      emit(state.copyWith(
        outgoing: state.outgoing.where((e) => e.id != item.id).toList(),
      ));
    }
  }
}
