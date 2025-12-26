import 'dart:async';

import 'package:flutter/foundation.dart';
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
    this._getUserPostDataUseCase,
    this._deletePostUseCase,
    this._createPostUseCase,
    this._postScheduledPostUseCase,
  ) : super(PostListingInitialState()) {
    on<GetHashTagPostEvent>(_getHashTagPosts);
    on<GetSearchResultsEvent>(_getSearchResults);
    on<GetPlaceDetailsEvent>(_getPlaceDetails);
    on<FollowSocialUserEvent>(_followSocialUser);
    on<GetUserPostListEvent>(_getUserPosts);
    on<ModifyPostScheduleEvent>(_modifySchedulePost);
    on<DeleteUserPostEvent>(_deletePost);
    on<PostScheduledPostPostEvent>(_postScheduledPost);
  }

  final GetTaggedPostsUseCase _getTaggedPostUseCase;
  final SearchTagUseCase _searchTagUseCase;
  final GeocodeSearchAddressUseCase _geocodeSearchAddressUseCase;
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final SearchUserUseCase _searchUserUseCase;
  final IsmLocalDataUseCase _localDataUseCase;
  final FollowUnFollowUserUseCase _followUnFollowUserUseCase;
  final GetUserPostDataUseCase _getUserPostDataUseCase;
  final DeletePostUseCase _deletePostUseCase;
  final CreatePostUseCase _createPostUseCase;
  final PostScheduledPostUseCase _postScheduledPostUseCase;

  var _searchPostPage = 1;
  var _searchTagsPage = 1;
  var _searchPlacesPage = 1;
  var _searchAccountsPage = 1;
  final _searchPostLimit = 20;

  FutureOr<void> _getHashTagPosts(GetHashTagPostEvent event, Emitter<PostListingState> emit) async {
    // Only emit loading state if not pagination
    if (!event.isFromPagination) {
      emit(PostListingLoadingState(isLoading: true));
    }

    if (event.tagValue.isEmpty) {
      emit(PostLoadedState(postList: []));
      return;
    }

    // Fix: Use pre-increment or add 1 explicitly
    if (event.isFromPagination) {
      _searchPostPage = _searchPostPage + 1;
    } else {
      _searchPostPage = 1;
    }

    final apiResult = await _getTaggedPostUseCase.executeGetTaggedPosts(
      page: _searchPostPage,
      pageLimit: _searchPostLimit,
      isLoading: false,
      tagValue: event.tagValue,
      tagType: event.tagType,
    );
    if (apiResult.isSuccess && apiResult.data?.data.isEmptyOrNull == false) {
      emit(PostLoadedState(postList: apiResult.data?.data ?? []));
    } else {
      // Fix: Decrement properly on error
      _searchPostPage = _searchPostPage > 1 ? _searchPostPage - 1 : 1;
      emit(PostLoadedState(postList: _searchPostPage == 1 ? [] : apiResult.data?.data ?? []));
    }
  }

  FutureOr<void> _getSearchResults(
      GetSearchResultsEvent event, Emitter<PostListingState> emit) async {
    // Only emit loading state if not pagination
    if (!event.isFromPagination) {
      emit(PostListingLoadingState(isLoading: event.isLoading));
    }

    if (event.searchQuery.isEmpty) {
      emit(SearchResultsLoadedState(results: [], tabType: event.tabType));
      return;
    }

    try {
      var results = <dynamic>[];

      switch (event.tabType) {
        case SearchTabType.posts:
          results = await _searchPosts(event.searchQuery, event.isFromPagination);
          break;
        case SearchTabType.account:
          results = await _searchUsers(event.searchQuery, event.isFromPagination);
          break;
        case SearchTabType.tags:
          results = await _searchTags(event.searchQuery, event.isFromPagination);
          break;
        case SearchTabType.places:
          results = await _searchPlaces(event.searchQuery, event.isFromPagination);
          break;
      }

      // Always emit state, but mark if it's from pagination
      // The view will handle empty pagination results by not clearing existing data
      emit(SearchResultsLoadedState(
        results: results,
        tabType: event.tabType,
        isFromPagination: event.isFromPagination,
      ));
    } catch (e) {
      debugPrint('❌ Error in search: $e');
      emit(SearchResultsLoadedState(
        results: [],
        tabType: event.tabType,
        isFromPagination: event.isFromPagination,
      ));
    }
  }

  Future<List<dynamic>> _searchPosts(String query, bool isFromPagination) async {
    // Handle pagination for posts
    if (isFromPagination) {
      _searchPostPage = _searchPostPage + 1;
    } else {
      _searchPostPage = 1;
    }

    debugPrint('📄 Posts: Requesting page $_searchPostPage (pagination: $isFromPagination)');

    // Use existing tagged posts functionality for posts search
    final apiResult = await _getTaggedPostUseCase.executeGetTaggedPosts(
      page: _searchPostPage,
      pageLimit: _searchPostLimit,
      isLoading: false,
      tagValue: query,
      tagType: TagType.hashtag,
    );

    if (apiResult.isSuccess) {
      final results = apiResult.data?.data ?? [];
      debugPrint('✅ Posts: Page $_searchPostPage returned ${results.length} items');
      // If pagination returns empty, decrement page and return empty to signal no more data
      if (isFromPagination && results.isEmpty) {
        _searchPostPage = _searchPostPage > 1 ? _searchPostPage - 1 : 1;
        debugPrint('⚠️ Posts: No more data. Staying at page $_searchPostPage');
      }
      return results;
    } else {
      // Decrement on error
      debugPrint('❌ Posts: API error on page $_searchPostPage');
      _searchPostPage = _searchPostPage > 1 ? _searchPostPage - 1 : 1;
    }
    return [];
  }

  Future<List<dynamic>> _searchTags(String query, bool isFromPagination) async {
    // Handle pagination for tags
    if (isFromPagination) {
      _searchTagsPage = _searchTagsPage + 1;
    } else {
      _searchTagsPage = 1;
    }

    final apiResult = await _searchTagUseCase.executeSearchTag(
      isLoading: false,
      limit: _searchPostLimit,
      page: _searchTagsPage,
      searchText: query,
    );

    if (apiResult.isSuccess) {
      final results = apiResult.data?.data ?? [];
      // If pagination returns empty, decrement page and return empty to signal no more data
      if (isFromPagination && results.isEmpty) {
        _searchTagsPage = _searchTagsPage > 1 ? _searchTagsPage - 1 : 1;
      }
      return results;
    } else {
      // Decrement on error
      _searchTagsPage = _searchTagsPage > 1 ? _searchTagsPage - 1 : 1;
    }
    return [];
  }

  Future<List<dynamic>> _searchPlaces(String searchQuery, bool isFromPagination) async {
    // Note: Google Places API might not support pagination the same way
    // If it does, implement similar to other methods
    // For now, keeping it simple
    if (isFromPagination) {
      _searchPlacesPage = _searchPlacesPage + 1;
    } else {
      _searchPlacesPage = 1;
    }

    final apiResult = await _geocodeSearchAddressUseCase.executeGetPlaceWithTextSearch(
      isLoading: false,
      searchText: searchQuery,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      final results = response?.results ?? [];
      // If pagination returns empty, decrement page and return empty to signal no more data
      if (isFromPagination && results.isEmpty) {
        _searchPlacesPage = _searchPlacesPage > 1 ? _searchPlacesPage - 1 : 1;
      }
      return results;
    } else {
      // Decrement on error
      _searchPlacesPage = _searchPlacesPage > 1 ? _searchPlacesPage - 1 : 1;
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

  Future<List<dynamic>> _searchUsers(String searchQuery, bool isFromPagination) async {
    // Handle pagination for users
    if (isFromPagination) {
      _searchAccountsPage = _searchAccountsPage + 1;
    } else {
      _searchAccountsPage = 1;
    }

    final apiResult = await _searchUserUseCase.executeSearchUser(
      isLoading: false,
      page: _searchAccountsPage,
      limit: _searchPostLimit,
      searchText: searchQuery,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      final results = response?.data ?? [];
      // If pagination returns empty, decrement page and return empty to signal no more data
      if (isFromPagination && results.isEmpty) {
        _searchAccountsPage = _searchAccountsPage > 1 ? _searchAccountsPage - 1 : 1;
      }
      return results;
    } else {
      // Decrement on error
      _searchAccountsPage = _searchAccountsPage > 1 ? _searchAccountsPage - 1 : 1;
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

  FutureOr<void> _deletePost(DeleteUserPostEvent event, Emitter<PostListingState> emit) async {
    final userId = await _localDataUseCase.getUserId();
    if (userId.isEmptyOrNull) {
      event.onComplete(false);
      return;
    }
    final apiResult = await _deletePostUseCase.executeDeletePost(
      isLoading: event.isLoading,
      postId: event.postId,
    );
    event.onComplete(apiResult.isSuccess);
  }

  FutureOr<void> _postScheduledPost(
      PostScheduledPostPostEvent event, Emitter<PostListingState> emit) async {
    final userId = await _localDataUseCase.getUserId();
    if (userId.isEmptyOrNull) {
      event.onComplete(false);
      return;
    }
    final apiResult = await _postScheduledPostUseCase.executePostNow(
      isLoading: event.isLoading,
      postId: event.postId,
    );
    event.onComplete(apiResult.isSuccess);
  }

  FutureOr<void> _modifySchedulePost(
      ModifyPostScheduleEvent event, Emitter<PostListingState> emit) async {
    final apiResult = await _createPostUseCase.executeEditPost(
      isLoading: true,
      postId: event.postId,
      editPostRequest: {
        'scheduled_at': event.scheduleTime,
      },
    );
    event.onComplete?.call(apiResult.isSuccess);

    if (apiResult.isError) {
      ErrorHandler.showAppError(
        appError: apiResult.error,
        isNeedToShowError: true,
        errorViewType: ErrorViewType.toast,
      );
    }
  }

  FutureOr<void> _getUserPosts(GetUserPostListEvent event, Emitter<PostListingState> emit) async {
    if (event.onComplete == null) {
      emit(PostListingLoadingState(isLoading: event.isLoading));
    }
    final apiResult = await _getUserPostDataUseCase.executeGetUserProfilePostData(
      isLoading: event.isLoading,
      page: event.page,
      pageSize: event.pageSize,
      memberId: await _localDataUseCase.getUserId(),
      scheduledOnly: event.scheduledOnly,
    );
    if (event.onComplete == null) {
      emit(PostLoadedState(postList: apiResult.data?.data ?? [], isLoadMore: event.page > 1));
    } else {
      event.onComplete?.call(apiResult.data?.data ?? []);
    }

    if (apiResult.isError) {
      ErrorHandler.showAppError(
        appError: apiResult.error,
        isNeedToShowError: true,
        errorViewType: ErrorViewType.toast,
      );
    }
  }
}
