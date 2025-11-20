// To parse this JSON data, do
//
//     final commentRequest = commentRequestFromJson(jsonString);

import 'dart:convert';

import 'package:ism_video_reel_player/utils/utils.dart';

CommentRequest commentRequestFromJson(String str) =>
    CommentRequest.fromJson(json.decode(str) as Map<String, dynamic>);

String commentRequestToJson(CommentRequest data) => json.encode(data.toJson());

class CommentRequest {
  factory CommentRequest.fromJson(Map<String, dynamic> json) => CommentRequest(
        userType: json['userType'] as num? ?? 0,
        hashTags: json['hashTags'] as String? ?? '',
        postId: json['post_id'] as String? ?? '',
        commentId: json['commentId'] as String? ?? '',
        postedBy: json['postedBy'] as String? ?? '',
        comment: json['content'] as String? ?? '',
        isNewLike: json['isNewLike'] as bool?,
        commentAction:
            json['commentAction'] as CommentAction? ?? CommentAction.like,
        userTags: json['userTags'] == null
            ? []
            : List<dynamic>.from((json['userTags'] as List).map((x) => x)),
        tags: json['tags'] == null
            ? null
            : Map<String, dynamic>.from(json['tags'] as Map),
      );

  CommentRequest({
    this.userType,
    this.hashTags,
    this.postId,
    this.postedBy,
    this.comment,
    this.userTags,
    this.commentId,
    this.commentAction,
    this.isNewLike,
    this.parentCommentId,
    this.reason,
    this.message,
    this.commentIds,
    this.tags,
  });

  num? userType;
  String? hashTags;
  String? postId;
  String? commentId;
  CommentAction? commentAction;
  String? postedBy;
  String? comment;
  List<dynamic>? userTags;
  bool? isNewLike;
  String? parentCommentId;
  String? reason;
  String? message;
  List<String>? commentIds;
  Map<String, dynamic>? tags;

  Map<String, dynamic> toJson() => {
        'userType': userType,
        'hashTags': hashTags,
        'post_id': postId,
        'commentId': commentId,
        'postedBy': postedBy,
        'content': comment,
        'commentAction': commentAction,
        'isNewLike': isNewLike,
        'userTags':
            userTags == null ? [] : List<dynamic>.from(userTags!.map((x) => x)),
        'parent_id': parentCommentId,
        'reason': reason,
        'message': message,
        'commentIds': commentIds,
        'tags': tags,
      };
}
