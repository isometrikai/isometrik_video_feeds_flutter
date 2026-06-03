import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

part 'sound_posts_detail_event.dart';
part 'sound_posts_detail_state.dart';

class SoundPostsDetailBloc
    extends Bloc<SoundPostsDetailEvent, SoundPostsDetailState> {
  SoundPostsDetailBloc(this._getPostsBySoundUseCase)
      : super(const SoundPostsDetailInitialState()) {
    on<GetSoundPostsDetailEvent>(_getSoundPosts);
    on<RefreshSoundPostsDetailEvent>(_refreshSoundPosts);
  }

  final GetPostsBySoundUseCase _getPostsBySoundUseCase;

  var _currentPage = 1;
  static const _pageSize = 20;
  final List<TimeLineData> _posts = [];

  FutureOr<void> _getSoundPosts(
    GetSoundPostsDetailEvent event,
    Emitter<SoundPostsDetailState> emit,
  ) async {
    try {
      emit(const SoundPostsDetailLoadingState(isLoading: true));

      if (!event.isFromPagination) {
        _currentPage = 1;
        _posts.clear();
      }

      final apiResult = await _getPostsBySoundUseCase.executeGetPostsBySound(
        page: _currentPage,
        pageSize: _pageSize,
        isLoading: false,
        soundId: event.soundId,
      );

      if (apiResult.isSuccess && apiResult.data?.data != null) {
        final envelope = apiResult.data!;
        final newPosts = envelope.data!;

        if (event.isFromPagination) {
          _posts.addAll(newPosts);
        } else {
          _posts
            ..clear()
            ..addAll(newPosts);
        }

        final hasMoreData = envelope.hasNext ??
            (newPosts.length == _pageSize);

        final totalPosts = envelope.total?.toInt();

        emit(SoundPostsDetailLoadedState(
          posts: List.from(_posts),
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
          soundId: event.soundId,
          totalPosts: totalPosts,
        ));

        if (hasMoreData) {
          _currentPage++;
        }
      } else {
        if (!event.isFromPagination) {
          _posts.clear();
        }

        emit(SoundPostsDetailLoadedState(
          posts: List.from(_posts),
          hasMoreData: false,
          currentPage: _currentPage,
          soundId: event.soundId,
        ));
      }
    } catch (e) {
      emit(SoundPostsDetailErrorState(error: e.toString()));
    }
  }

  FutureOr<void> _refreshSoundPosts(
    RefreshSoundPostsDetailEvent event,
    Emitter<SoundPostsDetailState> emit,
  ) async {
    _currentPage = 1;
    _posts.clear();
    add(GetSoundPostsDetailEvent(soundId: event.soundId));
  }
}
