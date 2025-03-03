part of 'landing_bloc.dart';

abstract class LandingState {}

class LandingInitialState extends LandingState {
  LandingInitialState({
    this.isNeedToShowLoader = false,
    this.isLoggedIn,
  });

  final bool? isNeedToShowLoader;
  final bool? isLoggedIn;
}
