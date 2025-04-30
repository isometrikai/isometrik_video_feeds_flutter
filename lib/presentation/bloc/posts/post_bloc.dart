import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc(
    this._localDataUseCase,
  ) : super(PostInitial(isLoading: true)) {
    on<StartPost>(_onStartPost);
    on<PostsLoadedEvent>(_loadFollowingPosts);
  }

  final IsmLocalDataUseCase _localDataUseCase;

  var reelsPageFollowingController = PageController();
  UserInfoClass? _userInfoClass;
  var reelsPageTrendingController = PageController();
  TextEditingController? descriptionController;

  void _onStartPost(StartPost event, Emitter<PostState> emit) async {
    final userInfoString = await _localDataUseCase.getUserInfo();
    _userInfoClass = UserInfoClass.fromJson(jsonDecode(userInfoString) as Map<String, dynamic>);
    final userId = await _localDataUseCase.getUserId();
    emit(UserInformationLoaded(
      userInfoClass: _userInfoClass,
      userId: userId,
    ));
  }

  FutureOr<void> _loadFollowingPosts(PostsLoadedEvent event, Emitter<PostState> emit) async {
    emit(PostsLoadedState(postsList: event.postsList));
  }
}
