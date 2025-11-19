import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'tag_details_event.dart';
part 'tag_details_state.dart';

class TagDetailsBloc extends Bloc<TagDetailsEvent, TagDetailsState> {
  TagDetailsBloc(
    this._getTaggedPostUseCase,
  ) : super(TagDetailsInitialState()) {
    on<GetTagDetailsEvent>(_getTagDetails);
    on<RefreshTagDetailsEvent>(_refreshTagDetails);
  }

  final GetTaggedPostsUseCase _getTaggedPostUseCase;

  var _currentPage = 1;
  final _pageLimit = 20;
  final List<TimeLineData> _posts = [];

  FutureOr<void> _getTagDetails(
      GetTagDetailsEvent event, Emitter<TagDetailsState> emit) async {
    try {
      emit(const TagDetailsLoadingState(isLoading: true));

      if (!event.isFromPagination) {
        _currentPage = 1;
        _posts.clear();
      }

      // Use tag value to search for posts tagged with this tag
      final apiResult = await _getTaggedPostUseCase.executeGetTaggedPosts(
        page: _currentPage,
        pageLimit: _pageLimit,
        isLoading: false,
        tagValue: event.tagValue,
        tagType: event.tagType,
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

        emit(TagDetailsLoadedState(
          posts: List.from(_posts),
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
          tagValue: event.tagValue,
          tagType: event.tagType,
        ));

        if (hasMoreData) {
          _currentPage++;
        }
      } else {
        if (!event.isFromPagination) {
          _posts.clear();
        }

        emit(TagDetailsLoadedState(
          posts: List.from(_posts),
          hasMoreData: false,
          currentPage: _currentPage,
          tagValue: event.tagValue,
          tagType: event.tagType,
        ));
      }
    } catch (e) {
      emit(TagDetailsErrorState(error: e.toString()));
    }
  }

  FutureOr<void> _refreshTagDetails(
      RefreshTagDetailsEvent event, Emitter<TagDetailsState> emit) async {
    // Reset pagination and fetch fresh data
    _currentPage = 1;
    _posts.clear();

    add(GetTagDetailsEvent(
      tagValue: event.tagValue,
      tagType: event.tagType,
      isFromPagination: false,
    ));
  }
}
