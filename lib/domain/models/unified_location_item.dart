import 'package:ism_video_reel_player/domain/domain.dart';

/// Unified location item model to handle both NearbyPlaces and AutoComplete responses
class UnifiedLocationItem {
  const UnifiedLocationItem({
    required this.placeId,
    required this.title,
    this.subtitle,
    this.description,
    this.vicinity,
    this.types,
    this.icon,
    this.geometry,
    this.scope,
    this.structuredFormatting,
    this.isFromNearbyPlaces = false,
    this.country,
    this.state,
    this.city,
    this.postalCode,
  });

  /// Factory constructor for Geocode API response (Result)
  factory UnifiedLocationItem.fromLocationResult(Result result) {
    // Extract state and country from address components
    String? state;
    String? country;
    String? city;
    String? postalCode;

    final addressComponents = result.addressComponents ?? [];
    for (final component in addressComponents) {
      final types = component.types ?? [];
      if (types.contains('locality')) {
        city = component.longName ?? '';
      }
      if (types.contains('administrative_area_level_1')) {
        state = component.longName;
      }
      if (types.contains('country')) {
        country = component.longName;
      }

      if (types.contains('postal_code')) {
        postalCode = component.longName ?? '';
      }
    }

    // Build subtitle with state and country
    final subtitleParts = <String>[];
    if (state != null && state.isNotEmpty) {
      subtitleParts.add(state);
    }
    if (country != null && country.isNotEmpty) {
      subtitleParts.add(country);
    }
    final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(', ') : result.formattedAddress;

    return UnifiedLocationItem(
      placeId: result.placeId ?? '',
      title: result.formattedAddress ?? '',
      subtitle: subtitle,
      description: result.formattedAddress,
      types: result.types,
      geometry: result.geometry,
      isFromNearbyPlaces: false,
      country: country,
      state: state,
      city: city,
      postalCode: postalCode,
    );
  }

  /// Factory constructor for AutoComplete response (Prediction)
  factory UnifiedLocationItem.fromPrediction(Prediction prediction) => UnifiedLocationItem(
        placeId: prediction.placeId ?? '',
        title: prediction.structuredFormatting?.mainText ??
            prediction.description ??
            'Unknown Location',
        subtitle: prediction.structuredFormatting?.secondaryText,
        description: prediction.description,
        types: prediction.types,
        structuredFormatting: prediction.structuredFormatting,
        isFromNearbyPlaces: false,
      );

  /// Factory constructor for NearbyPlaces response
  factory UnifiedLocationItem.fromNearbyPlace(Map<String, dynamic> json) => UnifiedLocationItem(
        placeId: (json['place_id'] as String?) ?? '',
        title: (json['name'] as String?) ?? 'Unknown Location',
        subtitle: json['vicinity'] as String?,
        vicinity: json['vicinity'] as String?,
        types: json['types'] != null ? List<String>.from(json['types'] as List) : null,
        icon: json['icon'] as String?,
        geometry: json['geometry'],
        scope: json['scope'] as String?,
        isFromNearbyPlaces: true,
      );

  /// Unique identifier for the place
  final String placeId;

  /// Main title to display (name for nearby places, main text for autocomplete)
  final String title;

  /// Subtitle to display (vicinity for nearby places, secondary text for autocomplete)
  final String? subtitle;

  /// Full description (mainly used for autocomplete)
  final String? description;

  /// Vicinity information (mainly used for nearby places)
  final String? vicinity;

  /// Place types
  final List<String>? types;

  /// Icon URL (mainly used for nearby places)
  final String? icon;

  /// Geometry information (mainly used for nearby places)
  final dynamic geometry;

  /// Scope (mainly used for nearby places)
  final String? scope;

  /// Structured formatting (mainly used for autocomplete)
  final dynamic structuredFormatting;

  /// Flag to indicate if this item came from nearby places API
  final bool isFromNearbyPlaces;

  final String? country;
  final String? state;
  final String? city;
  final String? postalCode;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'vicinity': vicinity,
        'types': types,
        'icon': icon,
        'geometry': geometry,
        'scope': scope,
        'structured_formatting': structuredFormatting,
        'is_from_nearby_places': isFromNearbyPlaces,
      };

  /// Create a copy with modified fields
  UnifiedLocationItem copyWith({
    String? placeId,
    String? title,
    String? subtitle,
    String? description,
    String? vicinity,
    List<String>? types,
    String? icon,
    dynamic geometry,
    String? scope,
    dynamic structuredFormatting,
    bool? isFromNearbyPlaces,
  }) =>
      UnifiedLocationItem(
        placeId: placeId ?? this.placeId,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        description: description ?? this.description,
        vicinity: vicinity ?? this.vicinity,
        types: types ?? this.types,
        icon: icon ?? this.icon,
        geometry: geometry ?? this.geometry,
        scope: scope ?? this.scope,
        structuredFormatting: structuredFormatting ?? this.structuredFormatting,
        isFromNearbyPlaces: isFromNearbyPlaces ?? this.isFromNearbyPlaces,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedLocationItem && other.placeId == placeId;
  }

  @override
  int get hashCode => placeId.hashCode;

  @override
  String toString() =>
      'UnifiedLocationItem(placeId: $placeId, title: $title, isFromNearbyPlaces: $isFromNearbyPlaces)';
}
