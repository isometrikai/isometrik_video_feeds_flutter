import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

class PostInfoClass {
  factory PostInfoClass.fromJson(Map<String, dynamic> json) => PostInfoClass(
        accessToken: json['accessToken'] as String?,
        userInformation: json['userInformation'] == null
            ? null
            : UserInfoClass.fromJson(
                json['userInformation'] as Map<String, dynamic>),
      );

  PostInfoClass({
    this.accessToken,
    this.userInformation,
  });

  final String? accessToken;
  final UserInfoClass? userInformation;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'userInformation': userInformation,
      };

  @override
  String toString() => jsonEncode(toJson());
}
