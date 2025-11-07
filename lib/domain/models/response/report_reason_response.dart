// To parse this JSON data, do
//
//     final reportReasonResponse = reportReasonResponseFromJson(jsonString);

import 'dart:convert';

ReportReasonResponse reportReasonResponseFromJson(String str) =>
    ReportReasonResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String reportReasonResponseToJson(ReportReasonResponse data) =>
    json.encode(data.toJson());

class ReportReasonResponse {
  ReportReasonResponse({
    this.message,
    this.data,
  });

  factory ReportReasonResponse.fromJson(Map<String, dynamic> json) =>
      ReportReasonResponse(
        message: json['message'] as String? ?? '',
          data: json['data'] == null
              ? []
              : List<ReportReason>.from(
            (json['data'] as List).map((x) => ReportReason.fromJson(x as Map<String, dynamic>)),
          ),
      );
  String? message;
  List<ReportReason>? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'data': data == null ? [] : data!.map((x) => x.toJson()).toList(),
  };
}

class ReportReason {
  ReportReason({
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.type,
  });

  factory ReportReason.fromJson(Map<String, dynamic> json) => ReportReason(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      type: json['type'] as String);
  String? id;
  String? name;
  String? description;
  String? createdAt;
  String? type;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'created_at': createdAt,
        'type': type,
      };
}
