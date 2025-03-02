import 'dart:convert';

CloudDetailsResponse cloudinaryResponseFromJson(String str) =>
    CloudDetailsResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String cloudinaryResponseToJson(CloudDetailsResponse data) => json.encode(data.toJson());

class CloudDetailsResponse {
  factory CloudDetailsResponse.fromJson(Map<String, dynamic> json) => CloudDetailsResponse(
        data: json['data'] == null ? null : CloudDetailsData.fromJson(json['data'] as Map<String, dynamic>),
      );

  CloudDetailsResponse({
    this.data,
  });

  CloudDetailsData? data;

  Map<String, dynamic> toJson() => {
        'data': data?.toJson(),
      };
}

class CloudDetailsData {
  CloudDetailsData({
    this.cloudName,
    this.apiKey,
    this.apiSecretKey,
    this.publicId,
    this.preset,
    this.timestamp,
    this.signature,
  });

  factory CloudDetailsData.fromJson(Map<String, dynamic> json) => CloudDetailsData(
        cloudName: json['cloudName'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        apiSecretKey: json['apiSecretKey'] as String? ?? '',
        publicId: json['publicId'] as String? ?? '',
        preset: json['preset'] as String? ?? '',
        timestamp: json['timestamp'] as num? ?? 0,
        signature: json['signature'] as String? ?? '',
      );
  String? cloudName;
  String? apiKey;
  String? apiSecretKey;
  String? publicId;
  String? preset;
  num? timestamp;
  String? signature;

  Map<String, dynamic> toJson() => {
        'cloudName': cloudName,
        'apiKey': apiKey,
        'apiSecretKey': apiSecretKey,
        'publicId': publicId,
        'preset': preset,
        'timestamp': timestamp,
        'signature': signature,
      };
}
