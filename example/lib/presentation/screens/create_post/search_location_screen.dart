import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/main.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

// Full screen location picker
class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({
    Key? key,
    this.currentLocation,
  }) : super(key: key);
  final TaggedPlace? currentLocation;

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Prediction> _searchResults = [];
  final List<TaggedPlace> _taggedPlaces = [];
  TaggedPlace? _taggedPlace;
  bool _isSearching = false;
  final _searchLocationBloc = InjectionUtils.getBloc<SearchLocationBloc>();

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _taggedPlace = widget.currentLocation;
    // Auto-focus and show keyboard when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
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
          _setResult(locationList);
        },
      ),
    );
  }

  void _setResult(List<Prediction> locationList) {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _searchResults.addAll(locationList);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    _focusNode.requestFocus();
  }

  void _selectLocation(Prediction prediction) {
    HapticFeedback.lightImpact();
    final completer = Completer<void>();
    _searchLocationBloc.add(GetPlaceDetails(
        placeId: prediction.placeId ?? '',
        onComplete: (placeDetails) {
          completer.complete();
          _setLocation(placeDetails);
        }));
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
    _taggedPlaces.add(location);
    Navigator.pop(context, _taggedPlaces);
  }

  void _removeLocation() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          backgroundColor: Colors.white,
          titleText: 'Tag Location',
          centerTitle: true,
          showActions: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: TapHandler(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _performSearch,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[500],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Current location option (if available)
            if (_taggedPlace != null) ...[
              Container(
                color: Colors.grey[50],
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                  ),
                  title: Text(
                    _taggedPlace?.placeName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Current location',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: GestureDetector(
                    onTap: _removeLocation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  onTap: _removeLocation,
                ),
              ),
              Container(
                height: 8,
                color: Colors.grey[100],
              ),
            ],

            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : _searchResults.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No locations found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching with different keywords',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _searchController.text.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Search for a location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start typing to find places',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey[200],
                                indent: 56,
                              ),
                              itemBuilder: (context, index) {
                                final location = _searchResults[index];
                                final isSelected =
                                    _taggedPlace?.placeId == location.placeId;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    location.structuredFormatting?.mainText ??
                                        location.description ??
                                        '',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      location.structuredFormatting
                                              ?.secondaryText ??
                                          '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Colors.blue[600],
                                          size: 24,
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                  onTap: () => _selectLocation(location),
                                );
                              },
                            ),
            ),
          ],
        ),
      );
}
