part of 'search_user_bloc.dart';

abstract class SearchEvents {
  const SearchEvents();
}

class SearchUserEvent extends SearchEvents {
  const SearchUserEvent({
    required this.searchText,
    this.onComplete,
    this.isLoading = true,
  });

  final bool? isLoading;
  final String searchText;
  final Function(List<SocialUserData>)? onComplete;
}

class SearchTagEvent extends SearchEvents {
  const SearchTagEvent({
    required this.searchText,
    this.onComplete,
    this.isLoading = true,
  });

  final bool? isLoading;
  final String searchText;
  final Function(List<HashTagData>)? onComplete;
}
