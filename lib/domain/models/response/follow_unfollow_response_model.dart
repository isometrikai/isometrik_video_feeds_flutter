import 'dart:convert';

FollowUnfollowResponseModel getFollowUnfollowResponseModelFromJson(String str) =>
    FollowUnfollowResponseModel.fromMap(json.decode(str) as Map<String, dynamic>);

String getFollowUnfollowResponseModelToJson(FollowUnfollowResponseModel data) =>
    json.encode(data.toJson()); 

class FollowUnfollowResponseModel {
  FollowUnfollowResponseModel({
    this.message,
    this.userId,
    this.isPrivate,
    this.followStatus,
    this.isAllFollow,
  });

  factory FollowUnfollowResponseModel.fromMap(Map<String, dynamic> map) =>
      FollowUnfollowResponseModel(
        message: map['message'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        isPrivate: (map['isPrivate'] as num?)?.toInt() ?? 0,
        followStatus: (map['followStatus'] as num?)?.toInt() ?? 0,
        isAllFollow: map['isAllFollow'] as bool? ?? false,
      );

  factory FollowUnfollowResponseModel.fromJson(String source) =>
      FollowUnfollowResponseModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  String? message;
  String? userId;
  num? isPrivate;
  num? followStatus;
  bool? isAllFollow;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'message': message,
        'userId': userId,
        'isPrivate': isPrivate?.toInt(),
        'followStatus': followStatus?.toInt(),
        'isAllFollow': isAllFollow,
      };

  String toJson() => json.encode(toMap());
}
