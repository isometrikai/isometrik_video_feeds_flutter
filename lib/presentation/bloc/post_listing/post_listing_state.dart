part of 'post_listing_bloc.dart';

abstract class PostListingState {}

class PostListingInitialState extends PostListingState {}

class PostListingLoadingState extends PostListingState {
  PostListingLoadingState({required this.isLoading});

  final bool isLoading;
}

class PostLoadedState extends PostListingState {
  PostLoadedState({required this.postList, this.isLoadMore = false});

  final List<TimeLineData> postList;
  final bool isLoadMore;
}

class SearchResultsLoadedState extends PostListingState {
  SearchResultsLoadedState({
    required this.results,
    required this.tabType,
    this.isFromPagination = false,
  });

  final List<dynamic> results;
  final SearchTabType tabType;
  final bool isFromPagination;
}
