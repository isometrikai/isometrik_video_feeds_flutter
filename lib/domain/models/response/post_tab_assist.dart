import 'package:ism_video_reel_player/domain/models/models.dart';
import 'package:ism_video_reel_player/utils/enums.dart';

class PostTabAssistData {
  PostTabAssistData({
    required this.postSectionType,
    required this.postList,
    this.postId,
    this.userId,
    this.tagValue,
    this.tagType,
  });

  final PostSectionType postSectionType;
  final List<TimeLineData> postList;
  var currentPage = 1;
  var hasMoreData = true;
  var isLoadingMore = false;
  var pageSize = 20;
  String? postId;
  String? userId;
  String? tagValue;
  TagType? tagType;
}
