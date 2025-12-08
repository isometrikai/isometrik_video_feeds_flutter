import 'dart:convert';

CollectionListResponse collectionListResponseFromJson(String str) =>
    CollectionListResponse.fromMap(json.decode(str) as Map<String, dynamic>);

String collectionListResponseToMap(CollectionListResponse data) =>
    json.encode(data.toMap());

class CollectionListResponse {
  CollectionListResponse({
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

  factory CollectionListResponse.fromMap(Map<String, dynamic> json) =>
      CollectionListResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: json['statusCode'] as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? []
            : List<CollectionData>.from((json['data'] as List)
                .map((x) => CollectionData.fromMap(x as Map<String, dynamic>))),
        total: json['total'] as num? ?? 0,
        page: json['page'] as num? ?? 0,
        pageSize: json['page_size'] as num? ?? 0,
        totalPages: json['total_pages'] as num? ?? 0,
      );

  String? status;
  String? message;
  num? statusCode;
  String? code;
  List<CollectionData>? data;
  num? total;
  num? page;
  num? pageSize;
  num? totalPages;

  Map<String, dynamic> toMap() => {
        'status': status,
        'message': message,
        'statusCode': statusCode,
        'code': code,
        'data':
            data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
      };
}

class CollectionData {
  CollectionData({
    this.id,
    this.name,
    this.userId,
    this.postCount,
    this.coverImage,
    this.createdAt,
    this.updatedAt,
  });

  factory CollectionData.fromMap(Map<String, dynamic> json) => CollectionData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        postCount: json['post_count'] as num? ?? 0,
        coverImage: json['cover_image'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  String? id;
  String? name;
  String? userId;
  num? postCount;
  String? coverImage;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'user_id': userId,
        'post_count': postCount,
        'cover_image': coverImage,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
