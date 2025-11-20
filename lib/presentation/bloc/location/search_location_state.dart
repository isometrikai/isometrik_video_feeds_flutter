part of 'search_location_bloc.dart';

abstract class SearchLocationState {}

class SearchLocationLoadingState extends SearchLocationState {
  SearchLocationLoadingState({required this.isLoading});

  final bool isLoading;
}

class SearchAddressResultState extends SearchLocationState {
  SearchAddressResultState({this.addressPlacesAutocompleteResponse});

  final AddressPlacesAutocompleteResponse? addressPlacesAutocompleteResponse;
}

class NearbyPlacesState extends SearchLocationState {
  NearbyPlacesState({this.locations});

  final List<UnifiedLocationItem>? locations;
}

class SearchLocationSuccessState extends SearchLocationState {
  SearchLocationSuccessState({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
    this.isLastKnownPosition = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;
  final bool isLastKnownPosition;
}

class SearchLocationErrorState extends SearchLocationState {
  SearchLocationErrorState({required this.error});

  final String error;
}
