import 'dart:convert';

FollowUnfollowResponseModel getFollowUnfollowResponseModelFromJson(
        String str) =>
    FollowUnfollowResponseModel.fromMap(
        json.decode(str) as Map<String, dynamic>);

String getFollowUnfollowResponseModelToJson(FollowUnfollowResponseModel data) =>
    json.encode(data.toJson());

class FollowUnfollowResponseModel {
  FollowUnfollowResponseModel({
    this.message,
    this.userId,
    this.isPrivate,
    this.followStatus,
    this.isAllFollow,
    this.isRequested,
  });

  factory FollowUnfollowResponseModel.fromMap(Map<String, dynamic> map) =>
      FollowUnfollowResponseModel(
        message: map['message'] as String? ?? '',
        userId: (map['userId'] ?? map['user_id']) as String? ?? '',
        isPrivate: (map['isPrivate'] as num?)?.toInt() ??
            (map['is_private'] as num?)?.toInt() ??
            0,
        followStatus: (map['followStatus'] as num?)?.toInt() ??
            (map['follow_status'] as num?)?.toInt() ??
            0,
        isAllFollow: map['isAllFollow'] as bool? ?? false,
        isRequested: FollowUnfollowResponseModel._readRequested(map),
      );

  factory FollowUnfollowResponseModel.fromJson(String source) =>
      FollowUnfollowResponseModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  static bool? _readRequested(Map<String, dynamic> map) {
    final v = map['is_requested'] ?? map['isRequested'];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return null;
  }

  String? message;
  String? userId;
  num? isPrivate;
  num? followStatus;
  bool? isAllFollow;
  bool? isRequested;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'message': message,
        'userId': userId,
        'isPrivate': isPrivate?.toInt(),
        'followStatus': followStatus?.toInt(),
        'isAllFollow': isAllFollow,
        'is_requested': isRequested,
      };

  String toJson() => json.encode(toMap());
}
