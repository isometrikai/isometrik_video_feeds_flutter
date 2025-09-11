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
  final Function(List<Prediction>)? onComplete;
}

class GetPlaceDetails extends SearchLocationEvent {
  GetPlaceDetails({
    required this.placeId,
    this.onComplete,
  });
  final String placeId;
  final Function(PlaceDetails)? onComplete;
}
