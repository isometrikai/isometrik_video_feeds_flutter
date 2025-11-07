part of 'tag_details_bloc.dart';

abstract class TagDetailsState {
  const TagDetailsState();
}

class TagDetailsInitialState extends TagDetailsState {}

class TagDetailsLoadingState extends TagDetailsState {
  const TagDetailsLoadingState({
    required this.isLoading,
  });

  final bool isLoading;
}

class TagDetailsLoadedState extends TagDetailsState {
  const TagDetailsLoadedState({
    required this.posts,
    required this.hasMoreData,
    required this.currentPage,
    required this.tagValue,
    required this.tagType,
  });

  final List<TimeLineData> posts;
  final bool hasMoreData;
  final int currentPage;
  final String tagValue;
  final TagType tagType;
}

class TagDetailsErrorState extends TagDetailsState {
  const TagDetailsErrorState({
    required this.error,
  });

  final String error;
}
