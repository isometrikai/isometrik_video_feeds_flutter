part of 'search_user_bloc.dart';

abstract class SearchStates {
  const SearchStates();
}

class LoadingSearchState extends SearchStates {
  LoadingSearchState({
    this.isLoading = false,
  });

  final bool? isLoading;
}

class LoadUserDataState extends SearchStates {
  const LoadUserDataState({
    required this.searchText,
  });

  final String searchText;
}
