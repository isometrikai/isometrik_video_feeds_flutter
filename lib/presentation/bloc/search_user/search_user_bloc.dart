import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'search_events.dart';
part 'search_states.dart';

class SearchUserBloc extends Bloc<SearchEvents, SearchStates> {
  SearchUserBloc(
    this.searchUserUseCase,
    this.searchTagUseCase,
  ) : super(LoadingSearchState()) {
    on<SearchUserEvent>(_searchUser);
    on<SearchTagEvent>(_searchTag);
  }

  final SearchUserUseCase searchUserUseCase;
  final SearchTagUseCase searchTagUseCase;
  final List<HashTagData> _searchTagList = [];

  var _searchUserPage = 1;
  final _searchUserLimit = 20;

  FutureOr<void> _searchUser(
      SearchUserEvent event, Emitter<SearchStates> emit) async {
    if (event.searchText.isEmptyOrNull) {
      if (event.onComplete != null) {
        event.onComplete!([]);
        return;
      }
    }

    if (event.isFromPagination) {
      _searchUserPage = _searchUserPage + 1;
    } else {
      _searchUserPage = 1;
    }

    final apiResult = await searchUserUseCase.executeSearchUser(
      isLoading: event.isLoading == true,
      limit: _searchUserLimit,
      page: _searchUserPage,
      searchText: event.searchText,
    );

    var results = <SocialUserData>[];
    if (apiResult.isSuccess) {
      results = apiResult.data?.data ?? [];
      if (event.isFromPagination && results.isEmpty) {
        _searchUserPage = _searchUserPage > 1 ? _searchUserPage - 1 : 1;
      }
    } else if (event.isFromPagination) {
      _searchUserPage = _searchUserPage > 1 ? _searchUserPage - 1 : 1;
    }

    if (event.onComplete != null) {
      event.onComplete!(results);
    }
  }

  FutureOr<void> _searchTag(
      SearchTagEvent event, Emitter<SearchStates> emit) async {
    final apiResult = await searchTagUseCase.executeSearchTag(
      isLoading: event.isLoading == true,
      limit: 20,
      page: 1,
      searchText: event.searchText,
    );
    _searchTagList.clear();
    if (apiResult.isSuccess) {
      _searchTagList.addAll(apiResult.data?.data ?? []);
    }
    if (event.onComplete != null) {
      event.onComplete!(_searchTagList);
    }
  }
}
