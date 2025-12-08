import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

NearByPlaceResponse nearByPlaceResponseFromJson(String str) =>
    NearByPlaceResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String nearByPlaceResponseToJson(NearByPlaceResponse data) =>
    json.encode(data.toJson());

class NearByPlaceResponse {
  NearByPlaceResponse({
    this.htmlAttributions,
    this.nextPageToken,
    this.results,
    this.status,
  });

  factory NearByPlaceResponse.fromJson(Map<String, dynamic> json) =>
      NearByPlaceResponse(
        htmlAttributions: json['html_attributions'] == null
            ? []
            : List<dynamic>.from(
                (json['html_attributions'] as List).map((x) => x)),
        nextPageToken: json['next_page_token'] as String?,
        results: json['results'] == null
            ? []
            : List<NearByPlaceResult>.from((json['results'] as List).map(
                (x) => NearByPlaceResult.fromJson(x as Map<String, dynamic>))),
        status: json['status'] as String?,
      );
  final List<dynamic>? htmlAttributions;
  final String? nextPageToken;
  final List<NearByPlaceResult>? results;
  final String? status;

  Map<String, dynamic> toJson() => {
        'html_attributions': htmlAttributions == null
            ? []
            : List<dynamic>.from(htmlAttributions!.map((x) => x)),
        'next_page_token': nextPageToken,
        'results': results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
        'status': status,
      };
}

class NearByPlaceResult {
  NearByPlaceResult({
    this.geometry,
    this.icon,
    this.iconBackgroundColor,
    this.iconMaskBaseUri,
    this.name,
    this.photos,
    this.placeId,
    this.reference,
    this.scope,
    this.types,
    this.vicinity,
    this.businessStatus,
    this.openingHours,
    this.plusCode,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
  });

  factory NearByPlaceResult.fromJson(Map<String, dynamic> json) =>
      NearByPlaceResult(
        geometry: json['geometry'] == null
            ? null
            : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
        icon: json['icon'] as String?,
        iconBackgroundColor: json['icon_background_color'] as String? ?? '',
        iconMaskBaseUri: json['icon_mask_base_uri'] as String?,
        name: json['name'] as String?,
        photos: json['photos'] == null
            ? []
            : List<Photo>.from((json['photos'] as List)
                .map((x) => Photo.fromJson(x as Map<String, dynamic>))),
        placeId: json['place_id'] as String?,
        reference: json['reference'] as String?,
        scope: json['scope'] as String? ?? '',
        types: json['types'] == null
            ? []
            : List<String>.from(
                (json['types'] as List).map((x) => x as String)),
        vicinity: json['vicinity'] as String?,
        businessStatus:
            businessStatusValues.map[json['business_status'] as String?],
        openingHours: json['opening_hours'] == null
            ? null
            : OpeningHours.fromJson(
                json['opening_hours'] as Map<String, dynamic>),
        plusCode: json['plus_code'] == null
            ? null
            : PlusCode.fromJson(json['plus_code'] as Map<String, dynamic>),
        rating: (json['rating'] as num?)?.toDouble(),
        userRatingsTotal: json['user_ratings_total'] as int?,
        priceLevel: json['price_level'] as int?,
      );
  final Geometry? geometry;
  final String? icon;
  final String? iconBackgroundColor;
  final String? iconMaskBaseUri;
  final String? name;
  final List<Photo>? photos;
  final String? placeId;
  final String? reference;
  final String? scope;
  final List<String>? types;
  final String? vicinity;
  final BusinessStatus? businessStatus;
  final OpeningHours? openingHours;
  final PlusCode? plusCode;
  final double? rating;
  final int? userRatingsTotal;
  final int? priceLevel;

  Map<String, dynamic> toJson() => {
        'geometry': geometry?.toJson(),
        'icon': icon,
        'icon_background_color': iconBackgroundColor,
        'icon_mask_base_uri': iconMaskBaseUri,
        'name': name,
        'photos': photos == null
            ? []
            : List<dynamic>.from(photos!.map((x) => x.toJson())),
        'place_id': placeId,
        'reference': reference,
        'scope': scope,
        'types': types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
        'vicinity': vicinity,
        'business_status': businessStatusValues.reverse[businessStatus],
        'opening_hours': openingHours?.toJson(),
        'plus_code': plusCode?.toJson(),
        'rating': rating,
        'user_ratings_total': userRatingsTotal,
        'price_level': priceLevel,
      };
}

enum BusinessStatus { operational }

final businessStatusValues =
    EnumValues({'OPERATIONAL': BusinessStatus.operational});

class Viewport {
  Viewport({
    this.northeast,
    this.southwest,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) => Viewport(
        northeast: json['northeast'] == null
            ? null
            : Location.fromJson(json['northeast'] as Map<String, dynamic>),
        southwest: json['southwest'] == null
            ? null
            : Location.fromJson(json['southwest'] as Map<String, dynamic>),
      );
  final Location? northeast;
  final Location? southwest;

  Map<String, dynamic> toJson() => {
        'northeast': northeast?.toJson(),
        'southwest': southwest?.toJson(),
      };
}

class OpeningHours {
  OpeningHours({
    this.openNow,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) => OpeningHours(
        openNow: json['open_now'] as bool?,
      );
  final bool? openNow;

  Map<String, dynamic> toJson() => {
        'open_now': openNow,
      };
}

class Photo {
  Photo({
    this.height,
    this.htmlAttributions,
    this.photoReference,
    this.width,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        height: json['height'] as int?,
        htmlAttributions: json['html_attributions'] == null
            ? []
            : List<String>.from(
                (json['html_attributions'] as List).map((x) => x as String)),
        photoReference: json['photo_reference'] as String?,
        width: json['width'] as int?,
      );
  final int? height;
  final List<String>? htmlAttributions;
  final String? photoReference;
  final int? width;

  Map<String, dynamic> toJson() => {
        'height': height,
        'html_attributions': htmlAttributions == null
            ? []
            : List<dynamic>.from(htmlAttributions!.map((x) => x)),
        'photo_reference': photoReference,
        'width': width,
      };
}

class PlusCode {
  PlusCode({
    this.compoundCode,
    this.globalCode,
  });

  factory PlusCode.fromJson(Map<String, dynamic> json) => PlusCode(
        compoundCode: json['compound_code'] as String?,
        globalCode: json['global_code'] as String?,
      );
  final String? compoundCode;
  final String? globalCode;

  Map<String, dynamic> toJson() => {
        'compound_code': compoundCode,
        'global_code': globalCode,
      };
}

class EnumValues<T> {
  EnumValues(this.map);

  Map<String, T> map;
  late Map<T, String> reverseMap;

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
