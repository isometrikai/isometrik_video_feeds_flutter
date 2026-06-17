import 'package:bloc/bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'blocked_users_state.dart';

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit({
    required GetBlockedUsersUseCase getBlockedUsersUseCase,
    required UnblockUserUseCase unblockUserUseCase,
  })  : _getBlockedUsers = getBlockedUsersUseCase,
        _unblockUser = unblockUserUseCase,
        super(const BlockedUsersState());

  static const int _pageSize = 20;

  final GetBlockedUsersUseCase _getBlockedUsers;
  final UnblockUserUseCase _unblockUser;

  void loadInitial() {
    loadBlockedUsers(refresh: true);
  }

  Future<void> loadBlockedUsers({
    required bool refresh,
    String? search,
  }) async {
    if (!refresh && (state.loading || state.loadingMore)) return;
    if (!refresh && !state.hasMore) return;

    final query = search ?? state.searchQuery;

    if (refresh) {
      emit(state.copyWith(
        page: 1,
        hasMore: true,
        loading: true,
        loadingMore: false,
        searchQuery: query,
      ));
    } else {
      emit(state.copyWith(loadingMore: true));
    }

    final pageToLoad = refresh ? 1 : state.page;
    final res = await _getBlockedUsers.getBlockedUsers(
      isLoading: false,
      page: pageToLoad,
      pageSize: _pageSize,
      search: query.isEmpty ? null : query,
    );

    if (isClosed) return;

    final data = res.data;
    if (data != null) {
      final list = refresh
          ? List<BlockedUserItem>.from(data.items)
          : [...state.items, ...data.items];
      emit(state.copyWith(
        items: list,
        hasMore: data.hasMore,
        page: data.hasMore ? pageToLoad + 1 : pageToLoad,
        loading: false,
        loadingMore: false,
      ));
    } else {
      emit(state.copyWith(loading: false, loadingMore: false));
    }
  }

  Future<void> search(String query) async {
    await loadBlockedUsers(refresh: true, search: query.trim());
  }

  Future<void> unblockUser(BlockedUserItem item) async {
    final res = await _unblockUser.unblock(
      isLoading: true,
      blockedId: item.userId,
    );
    if (res.isSuccess && !isClosed) {
      emit(state.copyWith(
        items: state.items.where((e) => e.userId != item.userId).toList(),
      ));
      Utility.showToastMessage(IsrTranslationFile.userUnblockedSuccessfully);
    }
  }
}
