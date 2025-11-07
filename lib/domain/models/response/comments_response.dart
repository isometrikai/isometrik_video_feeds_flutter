import 'dart:convert';

import 'package:ism_video_reel_player/utils/extensions.dart';

CommentsResponse commentsResponseFromJson(String str) =>
    CommentsResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String commentsResponseToJson(CommentsResponse data) => json.encode(data.toJson());

class CommentsResponse {
  CommentsResponse({
    this.message,
    this.data,
    this.totalComments,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) => CommentsResponse(
        message: json['message'] as String? ?? '',
        data: json['data'] == null
            ? []
            : List<CommentDataItem>.from((json['data'] as List)
                .map((x) => CommentDataItem.fromJson(x as Map<String, dynamic>))),
        totalComments: json['totalComments'] as num? ?? 0,
      );
  String? message;
  List<CommentDataItem>? data;
  num? totalComments;

  Map<String, dynamic> toJson() => {
        'message': message,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
        'totalComments': totalComments,
      };
}

class CommentDataItem {
  CommentDataItem({
    this.id,
    this.commentedBy,
    this.postId,
    this.commentedOn,
    this.timeStamp,
    this.userType,
    this.userTypeText,
    this.comment,
    this.hashtags,
    this.mentionedUsers,
    this.ip,
    this.city,
    this.country,
    this.status,
    this.childCommentCount,
    this.childComments,
    this.likesData,
    this.commentLikeList,
    this.type,
    this.commentedByUserId,
    this.commentUserType,
    this.commentUserTypeText,
    this.profilePic,
    this.starRequest,
    this.fullName,
    this.isStar,
    this.isLiked,
    this.likeCount,
    this.parentCommentId,
    this.tags,
  });

  factory CommentDataItem.fromJson(Map<String, dynamic> json) {
    final commenter = (json['user'] as Map<String, dynamic>?) ?? {};
    return CommentDataItem(
      id: json['id'] as String? ?? '',
      commentedBy: commenter['username'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      commentedOn: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      timeStamp: json['timeStamp'] as num? ?? 0,
      userType: json['userType'] as num? ?? 0,
      userTypeText: json['userTypeText'] as String? ?? '',
      comment: json['content'] as String? ?? '',
      hashtags: json['hashtags'] == null
          ? []
          : List<dynamic>.from((json['hashtags'] as List).map((x) => x)),
      mentionedUsers: json['mentionedUsers'] == null
          ? []
          : List<dynamic>.from((json['mentionedUsers'] as List).map((x) => x)),
      ip: json['ip'],
      city: json['city'],
      country: json['country'],
      status: json['status'] as String? ?? '',
      childCommentCount: json['reply_count'] as num? ?? 0,
      childComments: json['childComments'] == null
          ? []
          : List<CommentDataItem>.from((json['childComments'] as List)
              .map((x) => CommentDataItem.fromJson(x as Map<String, dynamic>))),
      likesData: json['likesData'] == null
          ? []
          : List<dynamic>.from((json['likesData'] as List).map((x) => x)),
      commentLikeList: json['commentLikeList'] == null
          ? []
          : List<CommentLikeList>.from((json['commentLikeList'] as List)
              .map((x) => CommentLikeList.fromJson(x as Map<String, dynamic>))),
      type: json['type'] == null ? null : Type.fromMap(json['type'] as Map<String, dynamic>),
      commentedByUserId: commenter['id'] as String? ?? '',
      commentUserType: json['commentUserType'] as num? ?? 0,
      commentUserTypeText: json['commentUserTypeText'] as String? ?? '',
      profilePic: commenter['avatar_url'] as String? ?? '',
      starRequest: json['starRequest'] == null ? null : StarRequest.fromJson(),
      fullName: commenter['full_name'] as String? ?? '',
      isStar: json['isStar'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      likeCount: json['like_count'] as num? ?? 0,
      parentCommentId: json['parent_id'] as String? ?? '',
      tags: json.objectOrNull('tags', CommentTags.fromJson),
    );
  }
  String? id;
  String? commentedBy;
  String? postId;
  DateTime? commentedOn;
  num? timeStamp;
  num? userType;
  String? userTypeText;
  String? comment;
  List<dynamic>? hashtags;
  List<dynamic>? mentionedUsers;
  dynamic ip;
  dynamic city;
  dynamic country;
  String? status;
  num? childCommentCount;
  List<CommentDataItem>? childComments;
  List<dynamic>? likesData;
  List<CommentLikeList>? commentLikeList;
  Type? type;
  String? commentedByUserId;
  num? commentUserType;
  String? commentUserTypeText;
  String? profilePic;
  StarRequest? starRequest;
  String? fullName;
  bool? isStar;
  bool? isLiked;
  num? likeCount;
  String? parentCommentId;
  bool showReply = false;
  CommentTags? tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': {
          'username': commentedBy,
          'id': commentedByUserId,
          'avatar_url': profilePic,
          'full_name': fullName,
        },
        'post_id': postId,
        'created_at': commentedOn?.toIso8601String(),
        'timeStamp': timeStamp,
        'userType': userType,
        'userTypeText': userTypeText,
        'content': comment,
        'hashtags': hashtags == null ? [] : List<dynamic>.from(hashtags!.map((x) => x)),
        'mentionedUsers':
            mentionedUsers == null ? [] : List<dynamic>.from(mentionedUsers!.map((x) => x)),
        'ip': ip,
        'city': city,
        'country': country,
        'status': status,
        'reply_count': childCommentCount,
        'childComments':
            childComments == null ? [] : List<dynamic>.from(childComments!.map((x) => x.toJson())),
        'likesData': likesData == null ? [] : List<dynamic>.from(likesData!.map((x) => x)),
        'commentLikeList': commentLikeList == null
            ? []
            : List<dynamic>.from(commentLikeList!.map((x) => x.toJson())),
        'type': type?.toMap(),
        'commentUserType': commentUserType,
        'commentUserTypeText': commentUserTypeText,
        'starRequest': starRequest?.toJson(),
        'isStar': isStar,
        'is_liked': isLiked,
        'like_count': likeCount,
        'parent_id': parentCommentId,
        'tags': tags?.toJson(),
      };
}

class CommentLikeList {
  CommentLikeList({
    this.id,
    this.commentId,
    this.likedBy,
    this.timestamp,
  });

  factory CommentLikeList.fromJson(Map<String, dynamic> json) => CommentLikeList(
        id: json['_id'] as String? ?? '',
        commentId: json['commentId'] as String? ?? '',
        likedBy: json['likedBy'] as String? ?? '',
        timestamp: json['timestamp'] as num? ?? 0,
      );
  String? id;
  String? commentId;
  String? likedBy;
  num? timestamp;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'commentId': commentId,
        'likedBy': likedBy,
        'timestamp': timestamp,
      };
}

class CommentTags {
  CommentTags({
    required this.hashtags,
    required this.mentions,
  });

  factory CommentTags.fromJson(Map<String, dynamic> json) => CommentTags(
        hashtags: (json['hashtags'] as List<dynamic>?)
                ?.map((e) => (e is Map<String, dynamic>) ? CommentMentionData.fromJson(e) : null)
                .nonNulls
                .toList() ??
            [],
        mentions: (json['mentions'] as List<dynamic>?)
                ?.map((e) => (e is Map<String, dynamic>) ? CommentMentionData.fromJson(e) : null)
                .nonNulls
                .toList() ??
            [],
      );
  List<CommentMentionData>? hashtags;
  List<CommentMentionData>? mentions;

  Map<String, dynamic> toJson() => {
        'hashtags': hashtags?.map((_) => _.toJson()).toList(),
        'mentions': mentions?.map((_) => _.toJson()).toList(),
      };
}

class CommentMentionData {
  CommentMentionData({
    this.userId,
    this.username,
    this.textPosition,
    this.tag,
    this.avatarUrl,
    this.name,
  });

  factory CommentMentionData.fromJson(Map<String, dynamic> json) => CommentMentionData(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        textPosition: json['text_position'] == null
            ? null
            : CommentTaggedPosition.fromJson(json['text_position'] as Map<String, dynamic>),
        avatarUrl: json['avatar_url'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
  String? userId;
  String? username;
  String? tag;
  CommentTaggedPosition? textPosition;
  String? avatarUrl;
  String? name;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'tag': tag,
        'text_position': textPosition?.toJson(),
        'avatar_url': avatarUrl,
        'name': name,
      }.removeEmptyValues();
}

class CommentTaggedPosition {
  CommentTaggedPosition({
    required this.start,
    required this.end,
  });

  factory CommentTaggedPosition.fromJson(Map<String, dynamic> json) => CommentTaggedPosition(
        start: json['start'] as num? ?? 0,
        end: json['end'] as num? ?? 0,
      );
  num? start;
  num? end;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
      };
}

class Type {
  Type({
    this.status,
    this.message,
  });

  factory Type.fromMap(Map<String, dynamic> map) => Type(
        status: map['status'] as int? ?? 0,
        message: map['message'] as String? ?? '',
      );

  int? status;
  String? message;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'status': status,
        'message': message,
      };
}

class StarRequest {
  StarRequest();

  factory StarRequest.fromJson() => StarRequest();

  Map<String, dynamic> toJson() => {};
}
