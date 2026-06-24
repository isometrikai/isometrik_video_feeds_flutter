import 'package:ism_video_reel_player/domain/domain.dart';

/// Helpers for timeline post `type` handling (Feed vs Following).
abstract final class TimelinePostTypeUtil {
  TimelinePostTypeUtil._();

  static bool isTextPost(TimeLineData post) =>
      (post.type ?? '').trim().toLowerCase() == 'text';

  /// Text post without card background (Threads / X style plain text).
  static bool isPlainTextPost(TimeLineData post) {
    if (!isTextPost(post)) return false;
    final raw = post.textFormatting;
    if (raw is! Map) return true;
    final background = raw['background'];
    if (background is! Map) return true;
    final type = (background['type'] as String?)?.trim() ?? '';
    return type.isEmpty;
  }

  static List<TimeLineData> withoutTextPosts(Iterable<TimeLineData> posts) =>
      posts.where((p) => !isTextPost(p)).toList();

  /// Timeline API `post_types` for the Feed tab (media + text).
  static const feedPostTypes = 'image,video,carousel,reel,text';

  /// Timeline API `post_types` for Following (media + text).
  static const followingPostTypes = 'image,video,carousel,reel,text';
}

extension TimeLineDataTextPostX on TimeLineData {
  bool get isTextPost => TimelinePostTypeUtil.isTextPost(this);

  /// Text post with no attached image/video media.
  bool get isTextOnlyPost =>
      isTextPost && (media == null || media!.isEmpty);

  bool get isPlainTextPost => TimelinePostTypeUtil.isPlainTextPost(this);
}
