import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';
import 'package:ism_video_reel_player/utils/timeline_post_type_util.dart';

enum ProfilePostTypeFilter { media, text }

List<TimeLineData> filterProfilePostsByType(
  List<TimeLineData> posts,
  ProfilePostTypeFilter filter,
) =>
    switch (filter) {
      ProfilePostTypeFilter.media =>
        posts.where((post) => !post.isTextPost).toList(),
      ProfilePostTypeFilter.text =>
        posts.where((post) => post.isTextPost).toList(),
    };
