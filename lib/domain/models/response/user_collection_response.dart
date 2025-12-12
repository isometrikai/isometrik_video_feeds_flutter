import 'dart:convert';

CollectionResponseModel collectionResponseModelFromJson(String str) =>
    CollectionResponseModel.fromJson(json.decode(str) as Map<String, dynamic>);

class CollectionResponseModel {
  factory CollectionResponseModel.fromJson(Map<String, dynamic> json) => CollectionResponseModel(
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => CollectionData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        message: json['message'] as String? ?? '',
      );

  CollectionResponseModel({
    this.data,
    this.message,
  });

  final List<CollectionData>? data;
  final String? message;

  Map<String, dynamic> toMap() => {
        'data': data?.map((e) => e.toJson()).toList(),
        'message': message,
      };
}

class CollectionData {
  factory CollectionData.fromJson(Map<String, dynamic> json) => CollectionData(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        productIds: (json['productIds'] as List<dynamic>?)
                ?.map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        timestamp: json['timestamp'] as num? ?? 0,
        updatedTimeStamp: json['updatedTimeStamp'] as num? ?? 0,
        isPrivate: json['isPrivate'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        previewImages:
            (json['previewImages'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        postCount: json['postCount'] as int? ?? 0,
        productCount: json['productCount'] as int? ?? 0,
        likes: json['likes'] as int? ?? 0,
      );

  CollectionData({
    this.id,
    this.userId,
    this.name,
    this.image,
    this.productIds,
    this.timestamp,
    this.updatedTimeStamp,
    this.isPrivate,
    this.description,
    this.previewImages,
    this.postCount,
    this.productCount,
    this.likes,
  });

  final String? id;
  final String? userId;
  final String? name;
  final String? image;
  final List<CollectionItem>? productIds;
  final num? timestamp;
  final num? updatedTimeStamp;
  final bool? isPrivate;
  final String? description;
  final List<String>? previewImages;
  final int? postCount;
  final int? productCount;
  final int? likes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'image': image,
        'productIds': productIds?.map((e) => e.toJson()).toList(),
        'timestamp': timestamp,
        'updatedTimeStamp': updatedTimeStamp,
        'isPrivate': isPrivate,
        'description': description,
        'previewImages': previewImages,
        'postCount': postCount,
        'productCount': productCount,
        'likes': likes,
      };
}

class CollectionItem {
  factory CollectionItem.fromJson(Map<String, dynamic> json) => CollectionItem(
        id: json['_id'] as String? ?? '',
        timestamp: json['timestamp'] as num? ?? 0,
        type: json['type'] as String? ?? '',
      );

  CollectionItem({
    this.id,
    this.timestamp,
    this.type,
  });

  final String? id;
  final num? timestamp;
  final String? type;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'timestamp': timestamp,
        'type': type,
      };
}
