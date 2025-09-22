import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/debouncer.dart';

part 'search_location_events.dart';
part 'search_location_state.dart';

class SearchLocationBloc
    extends Bloc<SearchLocationEvent, SearchLocationState> {
  SearchLocationBloc(
    this._geocodeSearchAddressUseCase,
    this._getPlaceDetailsUseCase,
  ) : super(SearchLocationLoadingState(isLoading: false)) {
    on<SearchAddressEvent>(_searchAddress);
    on<GetPlaceDetails>(_getPlaceDetails);
  }

  final GeocodeSearchAddressUseCase _geocodeSearchAddressUseCase;
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final DeBouncer _deBouncer = DeBouncer();

  FutureOr<void> _searchAddress(
      SearchAddressEvent event, Emitter<SearchLocationState> emit) async {
    _deBouncer.run(() {
      _getAddressByAutoCompleteSearch(event, emit);
    });
  }

  FutureOr<void> _getAddressByAutoCompleteSearch(
      SearchAddressEvent event, Emitter<SearchLocationState> emit) async {
    final apiResult = await _geocodeSearchAddressUseCase
        .executeGetAddressByAutoCompleteSearch(
      searchText: event.searchText,
      countries: ['us', 'in'],
      placeType: event.placeType,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      if (event.onComplete != null) {
        event.onComplete?.call(response?.predictions ?? []);
      }
    }
  }

  FutureOr<void> _getPlaceDetails(
      GetPlaceDetails event, Emitter<SearchLocationState> emit) async {
    final apiResult = await _getPlaceDetailsUseCase.executeGetPlaceDetail(
      placeId: event.placeId,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      if (event.onComplete != null && response != null) {
        event.onComplete?.call(response);
      }
    }
  }
}
