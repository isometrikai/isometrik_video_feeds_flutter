import 'dart:convert';

HashTagResponse hashTagResponseFromJson(String str) =>
    HashTagResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String hashTagResponseToJson(HashTagResponse data) => json.encode(data.toJson());

class HashTagResponse {
  HashTagResponse({
    this.code,
    this.data,
    this.message,
    this.page,
    this.pageSize,
    this.status,
    this.statusCode,
    this.total,
    this.totalPages,
  });

  factory HashTagResponse.fromJson(Map<String, dynamic> json) => HashTagResponse(
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? []
            : List<HashTagData>.from(
                (json['data'] as List).map((x) => HashTagData.fromJson(x as Map<String, dynamic>))),
        message: json['message'] as String? ?? '',
        page: json['page'] as num? ?? 0,
        pageSize: json['page_size'] as num? ?? 0,
        status: json['status'] as String? ?? '',
        statusCode: json['statusCode'] as num? ?? 0,
        total: json['total'] as num? ?? 0,
        totalPages: json['total_pages'] as num? ?? 0,
      );
  final String? code;
  final List<HashTagData>? data;
  final String? message;
  final num? page;
  final num? pageSize;
  final String? status;
  final num? statusCode;
  final num? total;
  final num? totalPages;

  Map<String, dynamic> toJson() => {
        'code': code,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
        'message': message,
        'page': page,
        'page_size': pageSize,
        'status': status,
        'statusCode': statusCode,
        'total': total,
        'total_pages': totalPages,
      };
}

class HashTagData {
  HashTagData({
    this.hashtag,
    this.id,
    this.slug,
    this.usageCount,
  });

  factory HashTagData.fromJson(Map<String, dynamic> json) => HashTagData(
        hashtag: json['hashtag'] as String? ?? '',
        id: json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        usageCount: json['usage_count'] as num? ?? 0,
      );
  final String? hashtag;
  final String? id;
  final String? slug;
  final num? usageCount;

  Map<String, dynamic> toJson() => {
        'hashtag': hashtag,
        'id': id,
        'slug': slug,
        'usage_count': usageCount,
      };
}
