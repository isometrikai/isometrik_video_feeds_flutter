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
