// Response envelope for `GET /api/v1/posts/sound`.

import 'dart:convert';

import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';

PostsBySoundResponse postsBySoundResponseFromJson(String str) =>
    PostsBySoundResponse.fromMap(json.decode(str) as Map<String, dynamic>);

String postsBySoundResponseToJson(PostsBySoundResponse data) =>
    json.encode(data.toMap());

/// Lists published posts that use a sound (`SoundsUnderPost` in API docs).
class PostsBySoundResponse {
  PostsBySoundResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
    this.total,
    this.page,
    this.pageSize,
    this.totalPages,
    this.hasNext,
    this.hasPrevious,
  });

  factory PostsBySoundResponse.fromMap(Map<String, dynamic> json) =>
      PostsBySoundResponse(
        status: json['status'] as String?,
        message: json['message'] as String?,
        statusCode: _readNum(json['status_code'] ?? json['statusCode']),
        code: json['code'] as String?,
        data: json['data'] == null
            ? []
            : List<TimeLineData>.from(
                (json['data'] as List).map(
                  (x) => TimeLineData.fromMap(x as Map<String, dynamic>),
                ),
              ),
        total: _readNum(json['total']),
        page: _readNum(json['page']),
        pageSize: _readNum(json['page_size']),
        totalPages: _readNum(json['total_pages']),
        hasNext: json['has_next'] as bool?,
        hasPrevious: json['has_previous'] as bool?,
      );

  final String? status;
  final String? message;
  final num? statusCode;
  final String? code;
  final List<TimeLineData>? data;
  final num? total;
  final num? page;
  final num? pageSize;
  final num? totalPages;
  final bool? hasNext;
  final bool? hasPrevious;

  Map<String, dynamic> toMap() => {
        'status': status,
        'message': message,
        'status_code': statusCode,
        'code': code,
        'data': data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toMap())),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
        'has_next': hasNext,
        'has_previous': hasPrevious,
      };

  static num? _readNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
