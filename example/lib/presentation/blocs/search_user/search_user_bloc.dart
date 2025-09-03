import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/example_export.dart';

part 'search_events.dart';
part 'search_states.dart';

class SearchUserBloc extends Bloc<SearchEvents, SearchStates> {
  SearchUserBloc(
    this.localDataUseCase,
    this.searchUserUseCase,
  ) : super(LoadingSearchState()) {
    on<SearchUserEvent>(_searchUser);
  }

  final LocalDataUseCase localDataUseCase;
  final SearchUserUseCase searchUserUseCase;
  final List<SocialUserData> _searchUsersList = [];
  final DeBouncer _deBouncer = DeBouncer();

  FutureOr<void> _searchUser(SearchUserEvent event, Emitter<SearchStates> emit) async {
    _deBouncer.run(() {
      _getUsers(event, emit);
    });
  }

  void _getUsers(SearchUserEvent event, Emitter<SearchStates> emit) async {
    final apiResult = await searchUserUseCase.executeSearchUser(
      isLoading: true,
      limit: 20,
      page: 1,
      searchText: event.searchText,
    );
    if (apiResult.isSuccess) {
      _searchUsersList.addAll(apiResult.data?.data ?? []);
    }
    if (event.onComplete != null) {
      event.onComplete!(_searchUsersList);
    }
  }
}
