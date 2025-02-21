part of 'home_bloc.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {
  HomeInitial();
}

class HomeLoading extends HomeState {
  HomeLoading();
}

class HomeLoaded extends HomeState {
  HomeLoaded();
}

class HomeError extends HomeState {
  HomeError(this.message);
  final String message;
}
