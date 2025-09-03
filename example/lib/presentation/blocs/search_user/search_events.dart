part of 'search_user_bloc.dart';

abstract class SearchEvents {
  const SearchEvents();
}

class SearchUserEvent extends SearchEvents {
  const SearchUserEvent({
    required this.searchText,
    this.onComplete,
  });

  final String searchText;
  final Function(List<SocialUserData>)? onComplete;
}
