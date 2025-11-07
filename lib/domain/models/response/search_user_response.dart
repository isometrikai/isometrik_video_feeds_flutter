import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

SearchUserResponse searchUserResponseFromJson(String str) =>
    SearchUserResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String searchUserResponseToJson(SearchUserResponse data) => json.encode(data.toJson());

class SearchUserResponse {
  SearchUserResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
    this.total,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  factory SearchUserResponse.fromJson(Map<String, dynamic> json) => SearchUserResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: json['statusCode'] as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? []
            : List<SocialUserData>.from((json['data'] as List)
                .map((x) => SocialUserData.fromMap(x as Map<String, dynamic>))),
        total: json['total'] as num? ?? 0,
        page: json['page'] as num? ?? 0,
        pageSize: json['page_size'] as num? ?? 0,
        totalPages: json['total_pages'] as num? ?? 0,
      );
  final String? status;
  final String? message;
  final num? statusCode;
  final String? code;
  final List<SocialUserData>? data;
  final num? total;
  final num? page;
  final num? pageSize;
  final num? totalPages;

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'statusCode': statusCode,
        'code': code,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
      };
}
