part of 'search_location_bloc.dart';

abstract class SearchLocationEvent {}

class SearchAddressEvent extends SearchLocationEvent {
  SearchAddressEvent({
    required this.searchText,
    required this.placeType,
    this.onComplete,
  });

  final String searchText;
  final String placeType;
  final Function(List<Result>)? onComplete;
}

class GetNearByPlacesEvent extends SearchLocationEvent {}

class GetCurrentLocationEvent extends SearchLocationEvent {}

class GetPlaceDetails extends SearchLocationEvent {
  GetPlaceDetails({
    required this.placeId,
    this.onComplete,
  });

  final String placeId;
  final Function(PlaceDetails)? onComplete;
}
