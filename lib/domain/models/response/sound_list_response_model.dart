import 'dart:convert';

import 'package:ism_video_reel_player/domain/models/response/response.dart';

SoundListResponseModel soundListResponseModelFromJson(String str) =>
    SoundListResponseModel.fromJson(
      json.decode(str) as Map<String, dynamic>,
    );

class SoundListResponseModel {

  factory SoundListResponseModel.fromJson(Map<String, dynamic> json) =>
      SoundListResponseModel(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: json['statusCode'] as int? ?? 0,
        code: json['code'] as String? ?? '',
        data: (json['data'] as List<dynamic>?)
            ?.map(
              (e) => SoundData.fromJson(
            e as Map<String, dynamic>,
          ),
        )
            .toList() ??
            [],
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 0,
        pageSize: json['page_size'] as int? ?? 0,
        totalPages: json['total_pages'] as int? ?? 0,
      );
  SoundListResponseModel({
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

  final String? status;
  final String? message;
  final int? statusCode;
  final String? code;
  final List<SoundData>? data;
  final int? total;
  final int? page;
  final int? pageSize;
  final int? totalPages;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'statusCode': statusCode,
    'code': code,
    'data': data?.map((e) => e.toJson()).toList(),
    'total': total,
    'page': page,
    'page_size': pageSize,
    'total_pages': totalPages,
  };
}
