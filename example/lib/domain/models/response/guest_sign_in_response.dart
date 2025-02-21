// To parse this JSON data, do
//
//     final guestLoginResponse = guestLoginResponseFromJson(jsonString);

import 'dart:convert';

GuestSignInResponse guestSignInResponseFromJson(String str) =>
    GuestSignInResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String guestSignInResponseToJson(GuestSignInResponse data) =>
    json.encode(data.toJson());

class GuestSignInResponse {
  GuestSignInResponse({
    this.message,
    this.data,
  });

  factory GuestSignInResponse.fromJson(Map<String, dynamic> json) =>
      GuestSignInResponse(
        message: json['message'] as String? ?? '',
        data: json['data'] == null
            ? GuestSignInData()
            : GuestSignInData.fromJson(json['data'] as Map<String, dynamic>),
      );
  String? message;
  GuestSignInData? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'data': data!.toJson(),
      };
}

class GuestSignInData {
  GuestSignInData({
    this.sid,
    this.type,
    this.ip,
    this.city,
    this.region,
    this.country,
    this.loc,
    this.postal,
    this.timezone,
    this.location,
    this.token,
  });

  factory GuestSignInData.fromJson(Map<String, dynamic> json) =>
      GuestSignInData(
        sid: json['sid'] as String? ?? '',
        type: json['type'] as String? ?? '',
        ip: json['ip'] as String? ?? '',
        city: json['city'] as String? ?? '',
        region: json['region'] as String? ?? '',
        country: json['country'] as String? ?? '',
        loc: json['loc'] as String? ?? '',
        postal: json['postal'] as String? ?? '',
        timezone: json['timezone'] as String? ?? '',
        location: json['location'] == null
            ? Location()
            : Location.fromJson(json['location'] as Map<String, dynamic>),
        token: json['token'] == null
            ? Token()
            : Token.fromJson(json['token'] as Map<String, dynamic>),
      );
  String? sid;
  String? type;
  String? ip;
  String? city;
  String? region;
  String? country;
  String? loc;
  String? postal;
  String? timezone;
  Location? location;
  Token? token;

  Map<String, dynamic> toJson() => {
        'sid': sid,
        'type': type,
        'ip': ip,
        'city': city,
        'region': region,
        'country': country,
        'loc': loc,
        'postal': postal,
        'timezone': timezone,
        'location': location!.toJson(),
        'token': token!.toJson(),
      };
}

class Location {
  Location({
    this.lat,
    this.long,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        lat: json['lat'] as String? ?? '',
        long: json['long'] as String? ?? '',
      );
  String? lat;
  String? long;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'long': long,
      };
}

class Token {
  Token({
    this.accessExpireAt,
    this.accessToken,
    this.refreshToken,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        accessExpireAt: json['accessExpireAt'] as int? ?? 0,
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
      );
  int? accessExpireAt;
  String? accessToken;
  String? refreshToken;

  Map<String, dynamic> toJson() => {
        'accessExpireAt': accessExpireAt,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}
