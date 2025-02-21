part of 'splash_bloc.dart';

abstract class SplashState {}

class SplashInitial extends SplashState {
  SplashInitial();
}

class SplashCompleted extends SplashState {
  SplashCompleted({required this.isLoggedIn});
  final bool isLoggedIn;
}

class SplashError extends SplashState {
  SplashError(this.message);

  final String message;
}
