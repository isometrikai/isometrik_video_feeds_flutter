part of 'place_details_bloc.dart';

abstract class PlaceDetailsState {
  const PlaceDetailsState();
}

class PlaceDetailsInitialState extends PlaceDetailsState {}

class PlaceDetailsLoadingState extends PlaceDetailsState {
  const PlaceDetailsLoadingState({
    required this.isLoading,
  });

  final bool isLoading;
}

class PlacePostsLoadedState extends PlaceDetailsState {
  const PlacePostsLoadedState({
    required this.posts,
    required this.hasMoreData,
    required this.currentPage,
  });

  final List<TimeLineData> posts;
  final bool hasMoreData;
  final int currentPage;
}

class PlaceDetailsErrorState extends PlaceDetailsState {
  const PlaceDetailsErrorState({
    required this.error,
  });

  final String error;
}
