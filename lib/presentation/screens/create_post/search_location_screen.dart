import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';

// Full screen location picker
class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({
    Key? key,
    this.taggedPlaceList,
  }) : super(key: key);
  final List<TaggedPlace>? taggedPlaceList;

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UnifiedLocationItem> _searchResults = [];
  List<TaggedPlace> _taggedPlaces = [];
  List<UnifiedLocationItem> _selectedLocations = [];
  bool _isSearching = false;
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  bool _isCheckingLocation = false;
  SearchLocationBloc get _searchLocationBloc => context.getOrCreateBloc();

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _taggedPlaces = widget.taggedPlaceList ?? [];
    _selectedLocations = _convertTaggedPlacesToUnified(_taggedPlaces);
    _checkLocationServiceAndPermission();
    // Auto-focus and show keyboard when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  /// Convert TaggedPlace list to UnifiedLocationItem list
  List<UnifiedLocationItem> _convertTaggedPlacesToUnified(
          List<TaggedPlace> taggedPlaces) =>
      taggedPlaces
          .map((taggedPlace) => UnifiedLocationItem(
                placeId: taggedPlace.placeId ?? '',
                title: taggedPlace.placeName ?? 'Unknown Location',
                subtitle: taggedPlace.address,
                description: taggedPlace.address,
                vicinity: taggedPlace.address,
                isFromNearbyPlaces: false,
              ))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Check location permission status
  Future<void> _checkLocationServiceAndPermission() async {
    try {
      setState(() {
        _isCheckingLocation = true;
      });

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Check permission status
      final permission = await Geolocator.checkPermission();
      final permissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      setState(() {
        _isLocationServiceEnabled = serviceEnabled;
        _isLocationPermissionGranted = permissionGranted;
        _isCheckingLocation = false;
      });

      // If both location service and permission are enabled, get current location (which will auto-trigger nearby places)
      if (serviceEnabled && permissionGranted) {
        _searchLocationBloc.add(GetCurrentLocationEvent());
      }
    } catch (e) {
      setState(() {
        _isCheckingLocation = false;
      });
      debugPrint('Error checking location permission: $e');
    }
  }

  /// Request location permission and enable services
  Future<void> _requestLocationServices() async {
    try {
      setState(() {
        _isCheckingLocation = true;
      });

      // First check if location services are enabled
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Request user to enable location services
        await Geolocator.openLocationSettings();
        // Re-check after user returns
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _isCheckingLocation = false;
          });
          return;
        }
      }

      // Request location permission
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Permission denied, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission is required to find nearby places'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Permission denied forever, open app settings
        await openAppSettings();
      }

      // Re-check permission status
      await _checkLocationServiceAndPermission();
    } catch (e) {
      setState(() {
        _isCheckingLocation = false;
      });
      debugPrint('Error requesting location services: $e');
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      _searchLocationBloc.add(GetNearByPlacesEvent());
      return;
    }
    if (query.length < 3) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    final completer = Completer<void>();
    _searchLocationBloc.add(
      SearchAddressEvent(
        searchText: query,
        placeType: PlaceType.geocode.apiString,
        onComplete: (locationList) {
          completer.complete();
          _setResultFromPredictions(locationList);
        },
      ),
    );
  }

  void _setResult(List<UnifiedLocationItem> locationList) {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _searchResults.addAll(locationList);
      });
    }
  }

  // Convert predictions to unified location items
  void _setResultFromPredictions(List<Result> locationList) {
    final unifiedItems =
        locationList.map(UnifiedLocationItem.fromLocationResult).toList();
    _setResult(unifiedItems);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    _focusNode.requestFocus();
  }

  void _selectLocation(UnifiedLocationItem item) {
    HapticFeedback.lightImpact();

    // Check if already selected
    final isAlreadySelected =
        _selectedLocations.any((place) => place.placeId == item.placeId);

    if (isAlreadySelected) {
      // Deselect - remove from selected locations
      _deselectLocation(item);
    } else {
      // Clear previous selections (single selection only)
      _selectedLocations.clear();
      _taggedPlaces.clear();

      // Select - get place details and add
      final completer = Completer<void>();
      _searchLocationBloc.add(GetPlaceDetails(
          placeId: item.placeId,
          onComplete: (placeDetails) {
            completer.complete();
            _setLocation(placeDetails);
          }));
    }
  }

  void _deselectLocation(UnifiedLocationItem item) {
    setState(() {
      _selectedLocations.removeWhere((place) => place.placeId == item.placeId);
      _taggedPlaces.removeWhere((place) => place.placeId == item.placeId);
    });
  }

  void _setLocation(PlaceDetails placeDetails) {
    final result = placeDetails.result;
    final addressComponents = result?.addressComponents ?? [];

    // Extract city
    var city = '';
    var state = '';
    var country = '';
    var postalCode = '';

    for (var component in addressComponents) {
      final types = component.types;
      if (types?.contains('locality') == true) {
        city = component.longName ?? '';
      }
      if (types?.contains('administrative_area_level_1') == true) {
        state = component.longName ?? '';
      }
      if (types?.contains('country') == true) {
        country = component.longName ?? '';
      }
      if (types?.contains('postal_code') == true) {
        postalCode = component.longName ?? '';
      }
    }
    final location = TaggedPlace(
      address: result?.formattedAddress,
      city: city,
      state: state,
      country: country,
      coordinates: [
        result?.geometry?.location?.lat?.toDouble() ?? 0,
        result?.geometry?.location?.lng?.toDouble() ?? 0
      ],
      placeData: PlaceData(description: ''),
      placeId: result?.placeId,
      placeName: result?.name,
      placeType: result?.types?.first ?? '',
      postalCode: postalCode,
    );

    setState(() {
      _taggedPlaces.add(location);
      // Also add to selected locations for UI display
      _selectedLocations.add(UnifiedLocationItem(
        placeId: location.placeId ?? '',
        title: location.placeName ?? 'Unknown Location',
        subtitle: location.address,
        description: location.address,
        vicinity: location.address,
        isFromNearbyPlaces: false,
      ));
    });

    Navigator.pop(context, _taggedPlaces);
  }

  /// Build selected location display (single selection)
  Widget _buildSelectedLocations() => Container(
        margin: IsrDimens.edgeInsetsSymmetric(
            horizontal: 16.responsiveDimension,
            vertical: 8.responsiveDimension),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Location',
              style:
                  IsrStyles.primaryText14.copyWith(fontWeight: FontWeight.w600),
            ),
            8.verticalSpace,
            Row(
              children:
                  _selectedLocations.map(_buildSelectedLocationChip).toList(),
            ),
          ],
        ),
      );

  /// Build individual selected location chip
  Widget _buildSelectedLocationChip(UnifiedLocationItem location) => Container(
        padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: 12.responsiveDimension,
            vertical: 8.responsiveDimension),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1976D2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              location.isFromNearbyPlaces ? Icons.near_me : Icons.location_on,
              size: 16.responsiveDimension,
              color: const Color(0xFF1976D2),
            ),
            6.horizontalSpace,
            Flexible(
              child: Text(
                location.title,
                style: IsrStyles.primaryText14.copyWith(
                    fontWeight: FontWeight.w500, color: '1976D2'.toColor()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            6.horizontalSpace,
            GestureDetector(
              onTap: () => _deselectLocation(location),
              child: Container(
                padding: IsrDimens.edgeInsetsAll(2.responsiveDimension),
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14.responsiveDimension,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => BlocProvider<SearchLocationBloc>(
        create: (_) => _searchLocationBloc,
        child: BlocConsumer<SearchLocationBloc, SearchLocationState>(
          bloc: _searchLocationBloc,
          listener: (context, state) {
            if (state is NearbyPlacesState) {
              _setResult(state.locations ?? []);
            }
          },
          builder: (context, state) => Scaffold(
            backgroundColor: Colors.white,
            appBar: const IsmCustomAppBarWidget(
              backgroundColor: Colors.white,
              isCrossIcon: true,
              titleText: IsrTranslationFile.selectALocation,
              centerTitle: true,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                if (_isLocationServiceEnabled &&
                    _isLocationPermissionGranted) ...[
                  Container(
                    margin: IsrDimens.edgeInsets(
                        left: 16.responsiveDimension,
                        top: 16.responsiveDimension,
                        right: 16.responsiveDimension),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _performSearch,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: IsrStyles.primaryText16,
                      decoration: InputDecoration(
                        hintText: IsrTranslationFile.searchForALocation,
                        hintStyle: IsrStyles.primaryText16
                            .copyWith(color: '999999'.toColor()),
                        prefixIcon: Icon(
                          Icons.search,
                          color: '999999'.toColor(),
                          size: 20.responsiveDimension,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: _clearSearch,
                                child: Container(
                                  padding: IsrDimens.edgeInsetsAll(
                                      8.responsiveDimension),
                                  child: Container(
                                    width: 20.responsiveDimension,
                                    height: 20.responsiveDimension,
                                    decoration: BoxDecoration(
                                      color: '999999'.toColor(),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: IsrDimens.edgeInsetsSymmetric(
                            vertical: 16.responsiveDimension),
                      ),
                    ),
                  ),

                  // Selected locations display
                  if (_selectedLocations.isNotEmpty) _buildSelectedLocations(),
                ],

                // Search results or location permission UI
                Expanded(
                  child: _isSearching
                      ? const SizedBox.shrink()
                      : _searchResults.isNotEmpty
                          ? ListView.builder(
                              padding: IsrDimens.edgeInsets(
                                  top: 16.responsiveDimension),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final location = _searchResults[index];
                                final isSelected = _selectedLocations.any(
                                    (place) =>
                                        place.placeId == location.placeId);

                                return InkWell(
                                  onTap: () => _selectLocation(location),
                                  child: Container(
                                    padding: IsrDimens.edgeInsetsSymmetric(
                                      horizontal: 16.responsiveDimension,
                                      vertical: 12.responsiveDimension,
                                    ),
                                    child: Row(
                                      children: [
                                        // Location icon
                                        Container(
                                          width: 40.responsiveDimension,
                                          height: 40.responsiveDimension,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF5F5F5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            location.isFromNearbyPlaces
                                                ? Icons.near_me
                                                : Icons.location_on_outlined,
                                            color: const Color(0xFF666666),
                                            size: 20,
                                          ),
                                        ),
                                        12.horizontalSpace,
                                        // Location info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                location.title,
                                                style: IsrStyles.primaryText16
                                                    .copyWith(
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (location
                                                      .subtitle?.isNotEmpty ==
                                                  true) ...[
                                                2.verticalSpace,
                                                Text(
                                                  location.subtitle!,
                                                  style: IsrStyles.primaryText14
                                                      .copyWith(
                                                          color: '666666'
                                                              .toColor()),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildEmptyState(),
                ),
              ],
            ),
          ),
        ),
      );

  /// Build empty state - shows location permission UI only if location services are disabled or permission not granted
  Widget _buildEmptyState() {
    // Show location permission UI if location services are disabled OR permission not granted
    if (!_isLocationServiceEnabled || !_isLocationPermissionGranted) {
      return _buildLocationPermissionUI();
    }

    // If location services are enabled, show regular empty search state
    return Center(
      child: Padding(
        padding:
            IsrDimens.edgeInsetsSymmetric(horizontal: 32.responsiveDimension),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64.responsiveDimension,
              color: Colors.grey[300],
            ),
            24.verticalSpace,
            Text(
              IsrTranslationFile.searchLocation,
              style:
                  IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w600),
            ),
            8.verticalSpace,
            Text(
              IsrTranslationFile.startTypingToFindPlaces,
              style:
                  IsrStyles.primaryText14.copyWith(color: '666666'.toColor()),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the location permission UI (matches the design)
  Widget _buildLocationPermissionUI() => Center(
        child: Padding(
          padding:
              IsrDimens.edgeInsetsSymmetric(horizontal: 32.responsiveDimension),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location icon
              const AppImage.svg(AssetConstants.icNearbyPlace),
              32.verticalSpace,

              // Title
              Text(
                IsrTranslationFile.seePlacesNearYou,
                style: IsrStyles.primaryText20
                    .copyWith(fontWeight: FontWeight.w600),
              ),

              12.verticalSpace,

              // Subtitle
              Text(
                _getLocationSubtitle(),
                textAlign: TextAlign.center,
                style: IsrStyles.primaryText16
                    .copyWith(color: '666666'.toColor(), height: 1.4),
              ),

              40.verticalSpace,

              // Turn On Location Services button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isCheckingLocation ? null : _requestLocationServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: IsrDimens.edgeInsetsSymmetric(
                        vertical: 16.responsiveDimension),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isCheckingLocation
                      ? SizedBox(
                          height: 20.responsiveDimension,
                          width: 20.responsiveDimension,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _getLocationButtonText(),
                          style: IsrStyles.primaryText16.copyWith(
                              fontWeight: FontWeight.w600,
                              color: IsrColors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Get appropriate subtitle text based on location status
  String _getLocationSubtitle() {
    if (!_isLocationServiceEnabled) {
      return 'To include nearby places, turn on location services';
    } else if (!_isLocationPermissionGranted) {
      return 'To include nearby places, allow location permission';
    }
    return 'To include nearby places, turn on location services';
  }

  /// Get appropriate button text based on location status
  String _getLocationButtonText() {
    if (!_isLocationServiceEnabled) {
      return 'Turn On Location Services';
    } else if (!_isLocationPermissionGranted) {
      return 'Allow Location Permission';
    }
    return 'Turn On Location Services';
  }
}
