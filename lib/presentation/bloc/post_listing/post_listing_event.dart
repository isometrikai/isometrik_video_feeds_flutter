part of 'post_listing_bloc.dart';

abstract class PostListingEvent {}

class GetHashTagPostEvent extends PostListingEvent {
  GetHashTagPostEvent({
    required this.tagValue,
    required this.tagType,
    required this.isLoading,
    this.isFromPagination = false,
  });

  final String tagValue;
  final TagType tagType;
  final bool isLoading;
  final bool isFromPagination;
}

class GetSearchResultsEvent extends PostListingEvent {
  GetSearchResultsEvent({
    required this.searchQuery,
    required this.tabType,
    required this.isLoading,
    this.isFromPagination = false,
  });

  final String searchQuery;
  final SearchTabType tabType;
  final bool isLoading;
  final bool isFromPagination;
}

class GetPlaceDetailsEvent extends PostListingEvent {
  GetPlaceDetailsEvent({
    required this.placeId,
    this.onComplete,
  });

  final String placeId;
  final Function(PlaceDetails)? onComplete;
}

class FollowSocialUserEvent extends PostListingEvent {
  FollowSocialUserEvent({
    required this.followingId,
    required this.onComplete,
    required this.followAction,
  });

  final String followingId;
  final Function(bool) onComplete;
  final FollowAction followAction;
}

class GetUserPostListEvent extends PostListingEvent {
  GetUserPostListEvent({
    this.page = 1,
    this.pageSize = 30,
    this.isLoading = false,
    this.scheduledOnly = false,
    this.onComplete,
  });

  final bool isLoading;
  final bool scheduledOnly;
  final int page;
  final int pageSize;
  final void Function(List<TimeLineData> posts)? onComplete;
}

class DeleteUserPostEvent extends PostListingEvent {
  DeleteUserPostEvent({
    required this.onComplete,
    required this.postId,
  });

  final Function(bool) onComplete;
  final String postId;
}

class ModifyPostScheduleEvent extends PostListingEvent {
  ModifyPostScheduleEvent({
    this.onComplete,
    required this.postId,
    required this.scheduleTime,
  });

  final String postId;
  final String scheduleTime;
  final void Function(bool)? onComplete;
}