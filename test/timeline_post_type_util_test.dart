import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';
import 'package:ism_video_reel_player/utils/timeline_post_type_util.dart';

void main() {
  group('TimelinePostTypeUtil', () {
    test('media-only post types exclude text', () {
      expect(TimelinePostTypeUtil.mediaOnlyPostTypes.contains('text'), isFalse);
      expect(TimelinePostTypeUtil.feedPostTypes.contains('text'), isTrue);
    });

    test('shouldShowTextPosts is true only for feeds tab', () {
      expect(TimelinePostTypeUtil.shouldShowTextPosts(PostSectionType.feeds),
          isTrue);
      expect(TimelinePostTypeUtil.shouldShowTextPosts(PostSectionType.forYou),
          isFalse);
      expect(
          TimelinePostTypeUtil.shouldShowTextPosts(PostSectionType.trending),
          isFalse);
      expect(
          TimelinePostTypeUtil.shouldShowTextPosts(PostSectionType.following),
          isFalse);
    });

    test('withoutTextPosts filters text type posts', () {
      final posts = [
        TimeLineData.fromMap(const {'id': '1', 'type': 'video'}),
        TimeLineData.fromMap(const {'id': '2', 'type': 'text'}),
        TimeLineData.fromMap(const {'id': '3', 'type': 'reel'}),
      ];

      final filtered = TimelinePostTypeUtil.withoutTextPosts(posts);

      expect(filtered.map((p) => p.id).toList(), ['1', '3']);
    });
  });
}
