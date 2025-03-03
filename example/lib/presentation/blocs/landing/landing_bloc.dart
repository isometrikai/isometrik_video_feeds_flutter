import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/blocs/blocs.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

part 'landing_events.dart';
part 'landing_state.dart';

class LandingBloc extends Bloc<LandingEvents, LandingState> {
  LandingBloc(this._localDataUseCase) : super(LandingInitialState(isNeedToShowLoader: false)) {
    on<LandingStartEvent>(_onStartLanding);
    on<LandingNavigationEvent>(_navigateToNextScreen);
  }

  final LocalDataUseCase _localDataUseCase;

  FutureOr<void> _onStartLanding(LandingStartEvent event, Emitter<LandingState> emit) async {
    final isLoggedIn = await _localDataUseCase.isLoggedIn();
    emit(LandingInitialState(isNeedToShowLoader: false, isLoggedIn: isLoggedIn));
  }

  FutureOr<void> _navigateToNextScreen(LandingNavigationEvent event, Emitter<LandingState> emit) async {
    if (event.navbarType == NavbarType.account) {
      var isLoggedIn = await _localDataUseCase.isLoggedIn();

      if (!isLoggedIn) {
        await InjectionUtils.getRouteManagement().goToLoginScreen();
        isLoggedIn = await _localDataUseCase.isLoggedIn();
        if (!isLoggedIn) return;
        InjectionUtils.getCubit<NavItemCubit>().onTap(event.navbarType);
      } else {
        InjectionUtils.getCubit<NavItemCubit>().onTap(event.navbarType);
      }
    } else {
      // Handle navigation for both logged in and other navbar types
      InjectionUtils.getCubit<NavItemCubit>().onTap(event.navbarType);
    }
  }
}
