import 'dart:convert';

import 'package:ism_video_reel_player/domain/models/response/follow_requests_list_response.dart';

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

  factory FollowUnfollowResponseModel.fromMap(Map<String, dynamic> map) {
    final flat = FollowUnfollowResponseModel._flattenFollowPayload(map);
    final mergedStatus = FollowRelationshipStatus.parseFromApiFields(
      followStatus: flat['followStatus'] ?? flat['follow_status'],
      followRelationship:
          flat['follow_relationship'] ?? flat['followRelationship'],
    );
    return FollowUnfollowResponseModel(
      message: flat['message'] as String? ?? map['message'] as String? ?? '',
      userId: (flat['userId'] ??
              flat['user_id'] ??
              flat['following_id'] ??
              flat['followingId']) as String? ??
          '',
      isPrivate: (flat['isPrivate'] as num?)?.toInt() ??
          (flat['is_private'] as num?)?.toInt() ??
          0,
      followStatus: mergedStatus ?? 0,
      isAllFollow: flat['isAllFollow'] as bool? ?? false,
      isRequested: FollowUnfollowResponseModel._readRequested(flat),
    );
  }

  factory FollowUnfollowResponseModel.fromJson(String source) =>
      FollowUnfollowResponseModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  /// Merges nested [`data`], [`data.user`], [`user`] so POST follow bodies parse correctly.
  static Map<String, dynamic> _flattenFollowPayload(Map<String, dynamic> map) {
    final flat = Map<String, dynamic>.from(map);
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      flat.addAll(data);
      final u = data['user'];
      if (u is Map<String, dynamic>) {
        flat.addAll(u);
      }
    }
    final rootUser = map['user'];
    if (rootUser is Map<String, dynamic>) {
      flat.addAll(rootUser);
    }
    return flat;
  }

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
