import 'dart:convert';

GoogleAddressResponse googleAddressResponseFromJson(String str) =>
    GoogleAddressResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String googleAddressResponseToJson(GoogleAddressResponse data) => json.encode(data.toJson());

AddressPlacesAutocompleteResponse addressPlacesAutocompleteResponseFromJson(String str) =>
    AddressPlacesAutocompleteResponse.fromJson(json.decode(str) as Map<String, dynamic>);

PlaceDetails placeDetailsFromJson(String str) =>
    PlaceDetails.fromJson(json.decode(str) as Map<String, dynamic>);

class GoogleAddressResponse {
  GoogleAddressResponse({
    this.results,
    this.status,
  });

  factory GoogleAddressResponse.fromJson(Map<String, dynamic> json) => GoogleAddressResponse(
        results: json['results'] == null
            ? []
            : List<Result>.from((json['results'] as List<dynamic>)
                .map((x) => Result.fromJson(x as Map<String, dynamic>))),
        status: json['status'] as String? ?? '',
      );

  List<Result>? results;
  String? status;

  Map<String, dynamic> toJson() => {
        'results': results == null ? [] : List<dynamic>.from(results!.map((x) => x.toJson())),
        'status': status,
      };
}

class Result {
  Result({
    this.addressComponents,
    this.formattedAddress,
    this.geometry,
    this.placeId,
    this.name,
    this.postcodeLocalities,
    this.types,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        addressComponents: json['address_components'] == null
            ? []
            : List<AddressComponent>.from((json['address_components'] as List<dynamic>)
                .map((x) => AddressComponent.fromJson(x as Map<String, dynamic>))),
        formattedAddress: json['formatted_address'] as String? ?? '',
        geometry: json['geometry'] == null
            ? null
            : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
        placeId: json['place_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        postcodeLocalities: json['postcode_localities'] == null
            ? []
            : List<String>.from(
                (json['postcode_localities'] as List<dynamic>).map((x) => x as String)),
        types: json['types'] == null
            ? []
            : List<String>.from((json['types'] as List<dynamic>).map((x) => x as String)),
      );

  List<AddressComponent>? addressComponents;
  String? formattedAddress;
  Geometry? geometry;
  String? placeId;
  String? name;
  List<String>? postcodeLocalities;
  List<String>? types;

  Map<String, dynamic> toJson() => {
        'address_components': addressComponents == null
            ? []
            : List<dynamic>.from(addressComponents!.map((x) => x.toJson())),
        'formatted_address': formattedAddress,
        'geometry': geometry?.toJson(),
        'place_id': placeId,
        'name': name,
        'postcode_localities':
            postcodeLocalities == null ? [] : List<dynamic>.from(postcodeLocalities!.map((x) => x)),
        'types': types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
      };
}

class AddressComponent {
  AddressComponent({
    this.longName,
    this.shortName,
    this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) => AddressComponent(
        longName: json['long_name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        types: json['types'] == null
            ? []
            : List<String>.from((json['types'] as List<dynamic>).map((x) => x as String)),
      );

  String? longName;
  String? shortName;
  List<String>? types;

  Map<String, dynamic> toJson() => {
        'long_name': longName,
        'short_name': shortName,
        'types': types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
      };
}

class Geometry {
  Geometry({
    this.bounds,
    this.location,
    this.locationType,
    this.viewport,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
        bounds:
            json['bounds'] == null ? null : Bounds.fromJson(json['bounds'] as Map<String, dynamic>),
        location: json['location'] == null
            ? null
            : LocationClass.fromJson(json['location'] as Map<String, dynamic>),
        locationType: json['location_type'] as String? ?? '',
        viewport: json['viewport'] == null
            ? null
            : Bounds.fromJson(json['viewport'] as Map<String, dynamic>),
      );

  Bounds? bounds;
  LocationClass? location;
  String? locationType;
  Bounds? viewport;

  Map<String, dynamic> toJson() => {
        'bounds': bounds?.toJson(),
        'location': location?.toJson(),
        'location_type': locationType,
        'viewport': viewport?.toJson(),
      };
}

class Bounds {
  Bounds({
    this.northeast,
    this.southwest,
  });

  factory Bounds.fromJson(Map<String, dynamic> json) => Bounds(
        northeast: json['northeast'] == null
            ? null
            : LocationClass.fromJson(json['northeast'] as Map<String, dynamic>),
        southwest: json['southwest'] == null
            ? null
            : LocationClass.fromJson(json['southwest'] as Map<String, dynamic>),
      );

  LocationClass? northeast;
  LocationClass? southwest;

  Map<String, dynamic> toJson() => {
        'northeast': northeast?.toJson(),
        'southwest': southwest?.toJson(),
      };
}

class LocationClass {
  LocationClass({
    this.lat,
    this.lng,
  });

  factory LocationClass.fromJson(Map<String, dynamic> json) => LocationClass(
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      );

  double? lat;
  double? lng;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };
}

class AddressPlacesAutocompleteResponse {
  AddressPlacesAutocompleteResponse({this.predictions, this.status});

  AddressPlacesAutocompleteResponse.fromJson(Map<String, dynamic> json) {
    if (json['predictions'] != null) {
      predictions = [];
      for (var v in json['predictions'] as List<dynamic>) {
        predictions!.add(Prediction.fromJson(v as Map<String, dynamic>));
      }
    }
    status = json['status'] as String?;
  }

  List<Prediction>? predictions;
  String? status;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (predictions != null) {
      data['predictions'] = predictions!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    return data;
  }
}

class Prediction {
  Prediction({
    this.description,
    this.id,
    this.matchedSubstrings,
    this.placeId,
    this.reference,
    this.structuredFormatting,
    this.terms,
    this.types,
    this.lat,
    this.lng,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        description: json['description'] as String?,
        id: json['id'] as String?,
        matchedSubstrings: json['matched_substrings'] == null
            ? []
            : List<MatchedSubstrings>.from((json['matched_substrings'] as List<dynamic>)
                .map((v) => MatchedSubstrings.fromJson(v as Map<String, dynamic>))),
        placeId: json['place_id'] as String?,
        reference: json['reference'] as String?,
        structuredFormatting: json['structured_formatting'] == null
            ? null
            : StructuredFormatting.fromJson(json['structured_formatting'] as Map<String, dynamic>),
        terms: json['terms'] == null
            ? []
            : List<Terms>.from((json['terms'] as List<dynamic>)
                .map((v) => Terms.fromJson(v as Map<String, dynamic>))),
        types: json['types'] == null
            ? []
            : List<String>.from((json['types'] as List<dynamic>).map((x) => x as String)),
        lat: json['lat'] as String?,
        lng: json['lng'] as String?,
      );

  String? description;
  String? id;
  List<MatchedSubstrings>? matchedSubstrings;
  String? placeId;
  String? reference;
  StructuredFormatting? structuredFormatting;
  List<Terms>? terms;
  List<String>? types;
  String? lat;
  String? lng;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['description'] = description;
    data['id'] = id;
    if (matchedSubstrings != null) {
      data['matched_substrings'] = matchedSubstrings!.map((v) => v.toJson()).toList();
    }
    data['place_id'] = placeId;
    data['reference'] = reference;
    if (structuredFormatting != null) {
      data['structured_formatting'] = structuredFormatting!.toJson();
    }
    if (terms != null) {
      data['terms'] = terms!.map((v) => v.toJson()).toList();
    }
    data['types'] = types;
    data['lat'] = lat;
    data['lng'] = lng;

    return data;
  }
}

class MatchedSubstrings {
  MatchedSubstrings({this.length, this.offset});

  factory MatchedSubstrings.fromJson(Map<String, dynamic> json) => MatchedSubstrings(
        length: json['length'] as int?,
        offset: json['offset'] as int?,
      );

  int? length;
  int? offset;

  Map<String, dynamic> toJson() => {
        'length': length,
        'offset': offset,
      };
}

class StructuredFormatting {
  StructuredFormatting({this.mainText, this.secondaryText});

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) => StructuredFormatting(
        mainText: json['main_text'] as String?,
        secondaryText: json['secondary_text'] as String?,
      );

  String? mainText;
  String? secondaryText;

  Map<String, dynamic> toJson() => {
        'main_text': mainText,
        'secondary_text': secondaryText,
      };
}

class Terms {
  Terms({this.offset, this.value});

  factory Terms.fromJson(Map<String, dynamic> json) => Terms(
        offset: json['offset'] as int?,
        value: json['value'] as String?,
      );

  int? offset;
  String? value;

  Map<String, dynamic> toJson() => {
        'offset': offset,
        'value': value,
      };
}

/// PlaceDetails model to represent the details of a place from Google Places API
class PlaceDetails {
  PlaceDetails({this.result, this.status});

  PlaceDetails.fromJson(Map<String, dynamic> json) {
    result =
        json['result'] != null ? Result.fromJson(json['result'] as Map<String, dynamic>) : null;
    status = json['status'] as String? ?? '';
  }

  Result? result;
  String? status;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (result != null) {
      data['result'] = result!.toJson();
    }
    data['status'] = status;
    return data;
  }
}

class PlaceDetailResult {
  PlaceDetailResult(
      {this.addressComponents,
      this.adrAddress,
      this.formattedAddress,
      this.geometry,
      this.icon,
      this.name,
      this.placeId,
      this.reference,
      this.scope,
      this.types,
      this.url,
      this.utcOffset,
      this.vicinity,
      this.website});

  PlaceDetailResult.fromJson(Map<String, dynamic> response) {
    final json = response['result'] as Map<String, dynamic>;
    if (json['address_components'] != null) {
      addressComponents = [];
      json['address_components'].forEach((v) {
        addressComponents!.add(AddressComponents.fromJson(v as Map<String, dynamic>));
      });
    }
    adrAddress = json['adr_address'] as String?;
    formattedAddress = json['formatted_address'] as String?;
    geometry = json['geometry'] != null
        ? Geometry.fromJson(json['geometry'] as Map<String, dynamic>)
        : null;
    icon = json['icon'] as String?;
    name = json['name'] as String?;

    placeId = json['place_id'] as String?;
    reference = json['reference'] as String?;
    scope = json['scope'] as String?;
    types = json['types'] == null ? null : List<String>.from(json['types'] as List<dynamic>);
    url = json['url'] as String?;
    utcOffset = json['utc_offset'] as int?;
    vicinity = json['vicinity'] as String?;
    website = json['website'] as String?;
  }

  List<AddressComponents>? addressComponents;
  String? adrAddress;
  String? formattedAddress;
  Geometry? geometry;
  String? icon;
  String? name;
  String? placeId;
  String? reference;
  String? scope;
  List<String>? types;
  String? url;
  int? utcOffset;
  String? vicinity;
  String? website;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (addressComponents != null) {
      data['address_components'] = addressComponents!.map((v) => v.toJson()).toList();
    }
    data['adr_address'] = adrAddress;
    data['formatted_address'] = formattedAddress;
    if (geometry != null) {
      data['geometry'] = geometry!.toJson();
    }
    data['icon'] = icon;
    data['name'] = name;
    data['place_id'] = placeId;
    data['reference'] = reference;
    data['scope'] = scope;
    data['types'] = types;
    data['url'] = url;
    data['utc_offset'] = utcOffset;
    data['vicinity'] = vicinity;
    data['website'] = website;
    return data;
  }
}

class AddressComponents {
  AddressComponents({this.longName, this.shortName, this.types});

  AddressComponents.fromJson(Map<String, dynamic> json) {
    longName = json['long_name'] as String?;
    shortName = json['short_name'] as String?;
    types = json['types'] == null ? null : List<String>.from(json['types'] as List<dynamic>);
  }

  String? longName;
  String? shortName;
  List<String>? types;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['long_name'] = longName;
    data['short_name'] = shortName;
    data['types'] = types;
    return data;
  }
}

class PlaceDetailGeometry {
  PlaceDetailGeometry({
    this.location,
  });

  PlaceDetailGeometry.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? PlaceDetailLocation.fromJson(json['location'] as Map<String, dynamic>)
        : null;
  }

  PlaceDetailLocation? location;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (location != null) {
      data['location'] = location!.toJson();
    }
    return data;
  }
}

class PlaceDetailLocation {
  PlaceDetailLocation({this.lat, this.lng});

  PlaceDetailLocation.fromJson(Map<String, dynamic> json) {
    if (json['lat'] != null) {
      lat = double.parse(json['lat'].toString());
    }
    if (json['lng'] != null) {
      lng = double.parse(json['lng'].toString());
    }
  }

  double? lat;
  double? lng;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}
