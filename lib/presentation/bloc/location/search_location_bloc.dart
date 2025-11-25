import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'search_location_events.dart';
part 'search_location_state.dart';

class SearchLocationBloc
    extends Bloc<SearchLocationEvent, SearchLocationState> {
  SearchLocationBloc(
    this._localDataUseCase,
    this._getPlaceDetailsUseCase,
    this._getNearByPlacesUseCase,
    this._locationManager,
    this._geocodeSearchAddressUseCase,
  ) : super(SearchLocationLoadingState(isLoading: false)) {
    on<SearchAddressEvent>(_searchAddress);
    on<GetPlaceDetails>(_getPlaceDetails);
    on<GetNearByPlacesEvent>(_getNearByPlaces);
    on<GetCurrentLocationEvent>(_getCurrentLocation);
  }

  final IsmLocalDataUseCase _localDataUseCase;
  final GetPlaceDetailsUseCase _getPlaceDetailsUseCase;
  final GetNearByPlacesUseCase _getNearByPlacesUseCase;
  final GeocodeSearchAddressUseCase _geocodeSearchAddressUseCase;
  final LocationManager _locationManager;
  final DeBouncer _deBouncer =
      DeBouncer(duration: const Duration(milliseconds: 900));

  FutureOr<void> _getNearByPlaces(
      GetNearByPlacesEvent event, Emitter<SearchLocationState> emit) async {
    try {
      final apiResult = await _getNearByPlacesUseCase.executeGetNearByPlaces(
        isLoading: true,
        placeType: PlaceType.address.apiString,
      );

      if (apiResult.isSuccess) {
        final response = apiResult.data;
        final results = response?.results ?? [];

        // Convert to unified location items
        final unifiedItems = <UnifiedLocationItem>[];

        for (final result in results) {
          try {
            // Check if prediction has the structure of a nearby place (with name, vicinity)
            if (result.toJson().containsKey('name') &&
                result.toJson().containsKey('vicinity')) {
              // This is a nearby place response
              unifiedItems
                  .add(UnifiedLocationItem.fromNearbyPlace(result.toJson()));
            } else {
              // This is an autocomplete prediction
              unifiedItems
                  .add(UnifiedLocationItem.fromNearbyPlace(result.toJson()));
            }
          } catch (e) {
            debugPrint('Error converting prediction to unified item: $e');
          }
        }

        emit(NearbyPlacesState(locations: unifiedItems));
      } else {
        emit(NearbyPlacesState(locations: []));
      }
    } catch (e) {
      emit(NearbyPlacesState(locations: []));
    }
  }

  FutureOr<void> _searchAddress(
      SearchAddressEvent event, Emitter<SearchLocationState> emit) async {
    _deBouncer.run(() {
      _getGeocodeAddress(event, emit);
    });
  }

  FutureOr<void> _getGeocodeAddress(
      SearchAddressEvent event, Emitter<SearchLocationState> emit) async {
    final apiResult = await _geocodeSearchAddressUseCase.executeGeocodeSearch(
      isLoading: false,
      searchText: event.searchText,
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      if (event.onComplete != null) {
        event.onComplete?.call(response?.results ?? []);
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

  FutureOr<void> _getCurrentLocation(
      GetCurrentLocationEvent event, Emitter<SearchLocationState> emit) async {
    try {
      emit(SearchLocationLoadingState(isLoading: true));

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(SearchLocationErrorState(error: 'Location services are disabled'));
        return;
      }

      // Check permission status
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(SearchLocationErrorState(error: 'Location permission denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(SearchLocationErrorState(
            error: 'Location permission permanently denied'));
        return;
      }

      // Check if we have valid saved location data
      var savedLatitude = await _localDataUseCase.getLatitude();
      var savedLongitude = await _localDataUseCase.getLongitude();

      final hasValidSavedLocation = savedLatitude != 0.0 &&
          savedLongitude != 0.0 &&
          savedLatitude.isFinite &&
          savedLongitude.isFinite;

      if (hasValidSavedLocation) {
        // We have valid saved location, emit it without getting new location
        debugPrint('Using saved location: $savedLatitude, $savedLongitude');
        emit(SearchLocationSuccessState(
          latitude: savedLatitude,
          longitude: savedLongitude,
          accuracy: null,
          timestamp: null,
          isLastKnownPosition: false,
        ));

        // Get nearby places after location is confirmed
        add(GetNearByPlacesEvent());
        return;
      }

      // No valid saved location, get current position
      debugPrint('No valid saved location found, getting current location...');

      await _locationManager.getCurrentLocation();

      savedLatitude = await _localDataUseCase.getLatitude();
      savedLongitude = await _localDataUseCase.getLongitude();

      emit(SearchLocationSuccessState(
        latitude: savedLatitude,
        longitude: savedLongitude,
        accuracy: 0,
        timestamp: DateTime.now(),
      ));

      // Get nearby places after location is obtained
      add(GetNearByPlacesEvent());
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Try to get last known position as fallback
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          // Save last known location
          _localDataUseCase.saveLatitude(lastPosition.latitude);
          _localDataUseCase.saveLongitude(lastPosition.longitude);

          debugPrint(
              'Using last known location: ${lastPosition.latitude}, ${lastPosition.longitude}');

          emit(SearchLocationSuccessState(
            latitude: lastPosition.latitude,
            longitude: lastPosition.longitude,
            accuracy: lastPosition.accuracy,
            timestamp: lastPosition.timestamp,
            isLastKnownPosition: true,
          ));

          // Get nearby places after fallback location is obtained
          add(GetNearByPlacesEvent());
        } else {
          emit(SearchLocationErrorState(
              error: 'Failed to get current location: $e'));
        }
      } catch (fallbackError) {
        emit(SearchLocationErrorState(
            error: 'Failed to get location: $fallbackError'));
      }
    }
  }
}
