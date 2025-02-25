// To parse this JSON data, do
//
//     final reportReasonResponse = reportReasonResponseFromJson(jsonString);

import 'dart:convert';

ReportReasonResponse reportReasonResponseFromJson(String str) =>
    ReportReasonResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String reportReasonResponseToJson(ReportReasonResponse data) => json.encode(data.toJson());

class ReportReasonResponse {
  ReportReasonResponse({
    this.message,
    this.data,
  });

  factory ReportReasonResponse.fromJson(Map<String, dynamic> json) => ReportReasonResponse(
        message: json['message'] as String? ?? '',
        data: json['data'] == null ? [] : List<String>.from((json['data'] as List).map((x) => x)),
      );
  String? message;
  List<String>? data;

  Map<String, dynamic> toJson() => {
        'message': message,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x)),
      };
}
