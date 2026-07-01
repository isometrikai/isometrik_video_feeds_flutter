import 'package:flutter/cupertino.dart';
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
        feedLayoutType: FeedLayoutType.values.firstWhere(
          (e) => e.name == json['feedLayoutType'],
          orElse: () => FeedLayoutType.reels,
        ),
        userId: json['userId'] as String?,
        postId: json['postId'] as String?,
        initialCommentId: json['initialCommentId'] as String?,
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
    this.feedLayoutType = FeedLayoutType.reels,
    this.userId,
    this.postId,
    this.initialCommentId,
    this.tagValue,
    this.tagType,
    this.lockSeededPostList = false,
  });

  final String title;
  List<TimeLineData> reelsDataList;
  final int? startingPostIndex;
  final PostSectionType postSectionType;

  /// When true, overlay players keep [reelsDataList] as passed in and ignore
  /// stale [SocialPostLoadedState] merges for the same [postSectionType].
  final bool lockSeededPostList;

  /// Per-tab layout: full-screen reels or scrollable post cards.
  final FeedLayoutType feedLayoutType;

  String? userId;
  String? postId;
  String? initialCommentId;
  String? tagValue;
  TagType? tagType;

  TabDataModel copyWith({
    String? title,
    List<TimeLineData>? reelsDataList,
    int? startingPostIndex,
    PostSectionType? postSectionType,
    FeedLayoutType? feedLayoutType,
    String? userId,
    String? postId,
    String? initialCommentId,
    String? tagValue,
    TagType? tagType,
    bool? lockSeededPostList,
  }) =>
      TabDataModel(
        title: title ?? this.title,
        reelsDataList: reelsDataList ?? this.reelsDataList,
        startingPostIndex: startingPostIndex ?? this.startingPostIndex,
        postSectionType: postSectionType ?? this.postSectionType,
        feedLayoutType: feedLayoutType ?? this.feedLayoutType,
        userId: userId ?? this.userId,
        postId: postId ?? this.postId,
        initialCommentId: initialCommentId ?? this.initialCommentId,
        tagValue: tagValue ?? this.tagValue,
        tagType: tagType ?? this.tagType,
        lockSeededPostList: lockSeededPostList ?? this.lockSeededPostList,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'reelsDataList': reelsDataList.map((e) => e.toMap()).toList(),
        'startingPostIndex': startingPostIndex,
        'postSectionType': postSectionType.name,
        'feedLayoutType': feedLayoutType.name,
        'userId': userId,
        'postId': postId,
        'initialCommentId': initialCommentId,
        'tagValue': tagValue,
        'tagType': tagType?.name,
      };
}

class TabStateModel {

  TabStateModel({
    required this.tabDataModel,
    bool isLoading = false,
    this.isVisible = true,
  }) {
    _isLoading = ValueNotifier<bool>(isLoading && tabDataModel.reelsDataList.isEmpty);
  }

  set isLoading(bool value) {
    _isLoading.value = value && tabDataModel.reelsDataList.isEmpty;
  }

  bool get isLoading => _isLoading.value;
  bool isVisible;

  ValueNotifier<bool> get loadingNotifier => _isLoading;

  final TabDataModel tabDataModel;
  late ValueNotifier<bool> _isLoading;
}
