import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class TabDataModel {
  factory TabDataModel.fromJson(Map<String, dynamic> json) => TabDataModel(
        title: json['title'] as String? ?? '',
        reelsDataList: (json['reelsDataList'] as List<dynamic>? ?? [])
            .map((e) => TimeLineData.fromMap(e as Map<String, dynamic>? ?? {}))
            .toList(),
        startingPostIndex: json['startingPostIndex'] as int? ?? 0,
        postSectionType: PostSectionType.values.firstWhere(
          (e) => e.name == json['postSectionType'],
          orElse: () => PostSectionType.trending,
        ),
        userId: json['userId'] as String?,
        postId: json['postId'] as String?,
        tagValue: json['tagValue'] as String?,
        tagType: json['tagType'] != null
            ? TagType.values.firstWhere(
                (e) => e.name == json['tagType'],
                orElse: () => TagType.product,
              )
            : null,
      );
  TabDataModel({
    required this.title,
    required this.reelsDataList,
    this.startingPostIndex = 0,
    required this.postSectionType,
    this.userId,
    this.postId,
    this.tagValue,
    this.tagType,
  });

  final String title;
  List<TimeLineData> reelsDataList;
  final int? startingPostIndex;
  final PostSectionType postSectionType;
  String? userId;
  String? postId;
  String? tagValue;
  TagType? tagType;

  TabDataModel copyWith({
    String? title,
    List<TimeLineData>? reelsDataList,
    int? startingPostIndex,
    PostSectionType? postSectionType,
    String? userId,
    String? postId,
    String? tagValue,
    TagType? tagType,
  }) =>
      TabDataModel(
        title: title ?? this.title,
        reelsDataList: reelsDataList ?? this.reelsDataList,
        startingPostIndex: startingPostIndex ?? this.startingPostIndex,
        postSectionType: postSectionType ?? this.postSectionType,
        userId: userId ?? this.userId,
        postId: postId ?? this.postId,
        tagValue: tagValue ?? this.tagValue,
        tagType: tagType ?? this.tagType,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'reelsDataList': reelsDataList.map((e) => e.toMap()).toList(),
        'startingPostIndex': startingPostIndex,
        'postSectionType': postSectionType.name,
        'userId': userId,
        'postId': postId,
        'tagValue': tagValue,
        'tagType': tagType?.name,
      };
}
