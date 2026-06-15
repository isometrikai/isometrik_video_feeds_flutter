import 'package:ism_video_reel_player/domain/models/response/response.dart';
import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';
import 'package:ism_video_reel_player/utils/enums.dart';

class ReelDubAudioUtil {
  ReelDubAudioUtil._();

  static String? _firstNonEmpty(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  static bool _isVideoMedia(MediaData media) =>
      media.postType == PostType.video ||
      (media.mediaType?.toLowerCase().contains('video') ?? false);

  static String? reelVideoUrlForDub(TimeLineData post) {
    final media = post.media;
    if (media == null || media.isEmpty) return null;

    for (final item in media) {
      if (!_isVideoMedia(item)) continue;
      return _firstNonEmpty(item.url) ??
          _firstNonEmpty(item.localPath) ??
          _firstNonEmpty(item.previewUrl);
    }
    return null;
  }

  static int reelVideoDurationSecondsForDub(
    TimeLineData post, {
    int fallback = 60,
  }) {
    final media = post.media;
    if (media == null || media.isEmpty) return fallback;

    var maxSeconds = 0;
    for (final item in media) {
      if (!_isVideoMedia(item)) continue;
      final seconds = (item.duration ?? 0).toInt();
      if (seconds > maxSeconds) maxSeconds = seconds;
    }
    return maxSeconds > 0 ? maxSeconds : fallback;
  }

  static SoundTrack dubSoundTrackForPost({
    required String audioFilePath,
    required TimeLineData post,
    required int durationSeconds,
  }) {
    final username = post.user?.username?.trim();
    final author = username != null && username.isNotEmpty
        ? '@$username'
        : 'Original audio';

    final firstMedia = post.media?.isNotEmpty == true ? post.media!.first : null;
    final thumbnailUrl = _firstNonEmpty(firstMedia?.previewUrl) ??
        _firstNonEmpty(firstMedia?.url) ??
        '';

    final postSound = post.sound;
    final librarySoundId = _firstNonEmpty(postSound?.id) ??
        _firstNonEmpty(post.soundId);

    return SoundTrack(
      id: librarySoundId ?? 'dub_${post.id ?? audioFilePath.hashCode}',
      thumbnailUrl: _firstNonEmpty(postSound?.thumbnailUrl) ?? thumbnailUrl,
      trackUrl: audioFilePath,
      title: _firstNonEmpty(postSound?.title) ?? 'Original audio',
      author: _firstNonEmpty(postSound?.artist) ?? author,
      duration: Duration(seconds: durationSeconds.clamp(1, 3600)),
      originalStatus: postSound?.snapshot?['original_status'] as String?,
    );
  }
}
