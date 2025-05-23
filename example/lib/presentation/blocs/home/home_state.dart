part of 'home_bloc.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {
  HomeInitial();
}

class HomeLoading extends HomeState {
  HomeLoading({this.isLoading = false});

  final bool? isLoading;
}

class HomeLoaded extends HomeState {
  HomeLoaded({
    required this.followingPosts,
    required this.trendingPosts,
  });

  final List<isr.PostDataModel>? followingPosts;
  final List<isr.PostDataModel>? trendingPosts;
}

class HomeError extends HomeState {
  HomeError(this.message);

  final String message;
}
