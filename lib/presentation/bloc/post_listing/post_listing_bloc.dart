import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'post_listing_event.dart';
part 'post_listing_state.dart';

class PostListingBloc extends Bloc<PostListingEvent, PostListingState> {
  PostListingBloc(
    this._getTaggedPostUseCase,
    this._searchTagUseCase,
    this._geocodeSearchAddressUseCase,
    this._getPlaceDetailsUseCase,
    this._searchUserUseCase,
    this._localDataUseCase,
    this._followUnFollowUserUseCase,
  ) : super(PostListingInitialState()) {
    on<GetHashTagPostEvent>(_getHashTagPosts);
    on<GetSearchResultsEvent>(_getSearchResults);
    on<GetPlaceDetailsEvent>(_getPlaceDetails);
    on<FollowSocialUserEvent>(_followSocialUser);
  }

  final GetTaggedPostsUseCase _getTaggedPostUseCase;
  final SearchTagUseCase _searchTagUseCase;
  final GeocodeSearchAddressUseCase _geocodeSearchAddressUseCase;
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final SearchUserUseCase _searchUserUseCase;
  final IsmLocalDataUseCase _localDataUseCase;
  final FollowUnFollowUserUseCase _followUnFollowUserUseCase;

  var _searchPostPage = 1;
  final _searchPostLimit = 20;

  FutureOr<void> _getHashTagPosts(GetHashTagPostEvent event, Emitter<PostListingState> emit) async {
    emit(PostListingLoadingState(isLoading: true));
    if (event.tagValue.isEmpty) {
      emit(PostLoadedState(postList: []));
      return;
    }
    _searchPostPage = event.isFromPagination ? _searchPostPage++ : 1;

    final apiResult = await _getTaggedPostUseCase.executeGetTaggedPosts(
      page: _searchPostPage,
      pageLimit: _searchPostLimit,
      isLoading: false,
      tagValue: event.tagValue,
      tagType: event.tagType,
    );
    if (apiResult.isSuccess) {
      emit(PostLoadedState(postList: apiResult.data?.data ?? []));
    } else {
      _searchPostPage = _searchPostPage == 1 ? 1 : _searchPostPage--;
      emit(PostLoadedState(postList: _searchPostPage == 1 ? [] : apiResult.data?.data ?? []));
    }
  }

  FutureOr<void> _getSearchResults(
      GetSearchResultsEvent event, Emitter<PostListingState> emit) async {
    emit(PostListingLoadingState(isLoading: true));
    if (event.searchQuery.isEmpty) {
      emit(SearchResultsLoadedState(results: [], tabType: event.tabType));
      return;
    }

    try {
      var results = <dynamic>[];

      switch (event.tabType) {
        case SearchTabType.posts:
          results = await _searchPosts(event.searchQuery);
          break;
        case SearchTabType.account:
          results = await _searchUsers(event.searchQuery);
          break;
        case SearchTabType.tags:
          results = await _searchTags(event.searchQuery);
          break;
        case SearchTabType.places:
          results = await _searchPlaces(event.searchQuery);
          break;
      }

      emit(SearchResultsLoadedState(results: results, tabType: event.tabType));
    } catch (e) {
      emit(SearchResultsLoadedState(results: [], tabType: event.tabType));
    }
  }

  Future<List<dynamic>> _searchPosts(String query) async {
    // Use existing tagged posts functionality for posts search
    final apiResult = await _getTaggedPostUseCase.executeGetTaggedPosts(
      page: 1,
      pageLimit: _searchPostLimit,
      isLoading: false,
      tagValue: query,
      tagType: TagType.hashtag,
    );

    if (apiResult.isSuccess) {
      return apiResult.data?.data ?? [];
    }
    return [];
  }

  Future<List<dynamic>> _searchTags(String query) async {
    final apiResult = await _searchTagUseCase.executeSearchTag(
      isLoading: false,
      limit: _searchPostLimit,
      page: 1,
      searchText: query,
    );

    if (apiResult.isSuccess) {
      return apiResult.data?.data ?? [];
    }
    return [];
  }

  Future<List<dynamic>> _searchPlaces(String searchQuery) async {
    final apiResult = await _geocodeSearchAddressUseCase.executeGeocodeSearch(
      isLoading: false,
      searchText: searchQuery,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      return response?.results ?? [];
    }
    return [];
  }

  FutureOr<void> _getPlaceDetails(
      GetPlaceDetailsEvent event, Emitter<PostListingState> emit) async {
    final apiResult = await _getPlaceDetailsUseCase.executeGetPlaceDetail(
      placeId: event.placeId,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      if (event.onComplete != null && response != null) {
        event.onComplete?.call(response);
      }
    }
  }

  Future<List<dynamic>> _searchUsers(String searchQuery) async {
    final apiResult = await _searchUserUseCase.executeSearchUser(
      isLoading: false,
      page: 1,
      limit: 20,
      searchText: searchQuery,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      return response?.data ?? [];
    }
    return [];
  }

  FutureOr<void> _followSocialUser(
      FollowSocialUserEvent event, Emitter<PostListingState> emit) async {
    final isLoggedIn = await _localDataUseCase.isLoggedIn();
    if (!isLoggedIn) {
      event.onComplete.call(false);
      return;
    }
    final apiResult = await _followUnFollowUserUseCase.executeFollowUser(
      isLoading: false,
      followingId: event.followingId,
      followAction: event.followAction,
    );

    event.onComplete.call(apiResult.isSuccess);
    if (apiResult.isError) {
      ErrorHandler.showAppError(
        appError: apiResult.error,
        isNeedToShowError: true,
        errorViewType: ErrorViewType.toast,
      );
    }
  }
}
