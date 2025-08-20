import 'dart:convert';

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
