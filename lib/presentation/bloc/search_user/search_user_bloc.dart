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
  final List<SocialUserData> _searchUsersList = [];
  final List<HashTagData> _searchTagList = [];

  FutureOr<void> _searchUser(
      SearchUserEvent event, Emitter<SearchStates> emit) async {
    if (event.searchText.isEmptyOrNull) {
      if (event.onComplete != null) {
        event.onComplete!([]);
        return;
      }
    }
    final apiResult = await searchUserUseCase.executeSearchUser(
      isLoading: event.isLoading == true,
      limit: 20,
      page: 1,
      searchText: event.searchText,
    );
    _searchUsersList.clear();
    if (apiResult.isSuccess) {
      _searchUsersList.addAll(apiResult.data?.data ?? []);
    }
    if (event.onComplete != null) {
      event.onComplete!(_searchUsersList);
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
