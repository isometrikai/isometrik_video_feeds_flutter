import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'place_details_event.dart';
part 'place_details_state.dart';

class PlaceDetailsBloc extends Bloc<PlaceDetailsEvent, PlaceDetailsState> {
  PlaceDetailsBloc(
    this._getTaggedPostUseCase,
  ) : super(PlaceDetailsInitialState()) {
    on<GetPlacePostsEvent>(_getPlacePosts);
    on<RefreshPlacePostsEvent>(_refreshPlacePosts);
  }

  final GetTaggedPostsUseCase _getTaggedPostUseCase;

  var _currentPage = 1;
  final _pageLimit = 20;
  final List<TimeLineData> _posts = [];

  FutureOr<void> _getPlacePosts(GetPlacePostsEvent event, Emitter<PlaceDetailsState> emit) async {
    try {
      emit(const PlaceDetailsLoadingState(isLoading: true));

      if (!event.isFromPagination) {
        _currentPage = 1;
        _posts.clear();
      }

      // Use place name as tag value to search for posts tagged with this place
      final apiResult = await _getTaggedPostUseCase.executeGetTaggedPosts(
        page: _currentPage,
        pageLimit: _pageLimit,
        isLoading: false,
        tagValue: event.placeId,
        tagType: TagType.place,
      );

      if (apiResult.isSuccess && apiResult.data?.data != null) {
        final newPosts = apiResult.data!.data!;

        if (event.isFromPagination) {
          _posts.addAll(newPosts);
        } else {
          _posts.clear();
          _posts.addAll(newPosts);
        }

        final hasMoreData = newPosts.length == _pageLimit;

        emit(PlacePostsLoadedState(
          posts: List.from(_posts),
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
        ));

        if (hasMoreData) {
          _currentPage++;
        }
      } else {
        if (!event.isFromPagination) {
          _posts.clear();
        }

        emit(PlacePostsLoadedState(
          posts: List.from(_posts),
          hasMoreData: false,
          currentPage: _currentPage,
        ));
      }
    } catch (e) {
      emit(PlaceDetailsErrorState(error: e.toString()));
    }
  }

  FutureOr<void> _refreshPlacePosts(
      RefreshPlacePostsEvent event, Emitter<PlaceDetailsState> emit) async {
    // Reset pagination and fetch fresh data
    _currentPage = 1;
    _posts.clear();

    add(GetPlacePostsEvent(
      placeId: event.placeId,
      latitude: event.latitude,
      longitude: event.longitude,
      isFromPagination: false,
    ));
  }
}
