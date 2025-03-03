import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._localDataUseCase) : super(ProfileInitial()) {
    on<InitializeProfileEvent>(_onInitializeProfile);
    on<LogoutEvent>(_onLogout);
  }

  final LocalDataUseCase _localDataUseCase;

  Future<void> _onInitializeProfile(
    InitializeProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoaded());
  }

  FutureOr<void> _onLogout(LogoutEvent event, Emitter<ProfileState> emit) async {
    await _localDataUseCase.clearLocalData().then((_) => {
          InjectionUtils.getRouteManagement().goToLoginScreen(),
        });
  }
}
