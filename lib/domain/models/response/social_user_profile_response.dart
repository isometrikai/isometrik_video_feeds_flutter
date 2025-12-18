import 'dart:convert';

SocialUserProfileResponse socialUserProfileResponseFromJson(String str) =>
    SocialUserProfileResponse.fromJson(
        json.decode(str) as Map<String, dynamic>);

String socialUserProfileResponseToJson(SocialUserProfileResponse data) =>
    json.encode(data.toJson());

class SocialUserProfileResponse {
  SocialUserProfileResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.data,
  });

  factory SocialUserProfileResponse.fromJson(Map<String, dynamic> json) =>
      SocialUserProfileResponse(
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
        statusCode: json['statusCode'] as num? ?? 0,
        code: json['code'] as String? ?? '',
        data: json['data'] == null
            ? null
            : SocialUserProfileData.fromJson(
                json['data'] as Map<String, dynamic>),
      );

  final String? status;
  final String? message;
  final num? statusCode;
  final String? code;
  final SocialUserProfileData? data;

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'statusCode': statusCode,
        'code': code,
        'data': data?.toJson(),
      };
}

class SocialUserProfileData {
  SocialUserProfileData({
    this.fullName,
    this.avatarUrl,
    this.followersCount,
    this.userMetadata,
    this.displayName,
    this.lastActivity,
    this.loginTime,
    this.isOnline,
    this.username,
    this.id,
    this.followingCount,
    this.isFollowing,
    this.postsCount,
  });

  factory SocialUserProfileData.fromJson(Map<String, dynamic> json) =>
      SocialUserProfileData(
        fullName: json['full_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        followersCount: json['followers_count'] as num? ?? 0,
        userMetadata: json['user_metadata'] as Map<String, dynamic>?,
        displayName: json['display_name'] as String? ?? '',
        lastActivity: json['last_activity'] as String? ?? '',
        loginTime: json['login_time'] as String? ?? '',
        isOnline: json['is_online'] as bool? ?? false,
        username: json['username'] as String? ?? '',
        id: json['id'] as String? ?? '',
        followingCount: json['following_count'] as num? ?? 0,
        isFollowing: json['is_following'] as bool? ?? false,
        postsCount: json['posts_count'] as num? ?? 0,
      );

  final String? fullName;
  final String? avatarUrl;
  final num? followersCount;
  final Map<String, dynamic>? userMetadata;
  final String? displayName;
  final String? lastActivity;
  final String? loginTime;
  final bool? isOnline;
  final String? username;
  final String? id;
  final num? followingCount;
  final bool? isFollowing;
  final num? postsCount;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'followers_count': followersCount,
        'user_metadata': userMetadata,
        'display_name': displayName,
        'last_activity': lastActivity,
        'login_time': loginTime,
        'is_online': isOnline,
        'username': username,
        'id': id,
        'following_count': followingCount,
        'is_following': isFollowing,
        'posts_count': postsCount,
      };
}
