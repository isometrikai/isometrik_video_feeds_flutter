part of 'blocked_users_cubit.dart';

class BlockedUsersState {
  const BlockedUsersState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.searchQuery = '',
  });

  final List<BlockedUserItem> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String searchQuery;

  BlockedUsersState copyWith({
    List<BlockedUserItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? searchQuery,
  }) =>
      BlockedUsersState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}
