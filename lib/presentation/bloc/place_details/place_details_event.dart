part of 'place_details_bloc.dart';

abstract class PlaceDetailsEvent {
  const PlaceDetailsEvent();
}

class GetPlacePostsEvent extends PlaceDetailsEvent {
  const GetPlacePostsEvent({
    required this.placeId,
    this.latitude,
    this.longitude,
    this.isFromPagination = false,
  });

  final String placeId;
  final double? latitude;
  final double? longitude;
  final bool isFromPagination;
}

class RefreshPlacePostsEvent extends PlaceDetailsEvent {
  const RefreshPlacePostsEvent({
    required this.placeId,
    this.latitude,
    this.longitude,
  });

  final String placeId;
  final double? latitude;
  final double? longitude;
}
