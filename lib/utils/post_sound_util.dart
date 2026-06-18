import 'dart:io';

import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_models.dart';
import 'package:ism_video_reel_player/utils/camera_gallery_sound_util.dart';
import 'package:ism_video_reel_player/utils/media_util.dart';
import 'package:ism_video_reel_player/utils/utility.dart';

/// Maps camera / library sounds into post + media-edit models and muxes video.
abstract final class PostSoundUtil {
  /// Seconds of sound used per image slide in carousel / image posts.
  static const int imageSoundSecondsPerSlide = 3;

  /// Legacy cap for image-only sound clips (prefer [imagePostSoundDurationSeconds]).
  static const int photoSoundClipMaxSeconds = 60;

  /// Total sound length for an image-only post: 3 seconds per image.
  static int imagePostSoundDurationSeconds(int imageCount) {
    final count = imageCount < 1 ? 1 : imageCount;
    return count * imageSoundSecondsPerSlide;
  }

  static int imageCountFromMediaData(Iterable<MediaData> media) => media
      .where(
        (m) =>
            m.mediaType == 'image' ||
            m.postType?.toString().toLowerCase() == 'image',
      )
      .length;

  static int imageCountFromEditItems(Iterable<MediaEditItem> items) => items
      .where((item) => item.mediaType == EditMediaType.image)
      .length;

  /// Library sounds from `/api/v1/sounds/*` — not temporary `dub_*` ids.
  static bool isLibrarySoundId(String? soundId) {
    final id = soundId?.trim() ?? '';
    if (id.isEmpty) return false;
    if (id.startsWith('dub_')) return false;
    return true;
  }

  static MediaEditSoundItem? soundItemFromCamera(CameraBloc cameraBloc) {
    if (!cameraBloc.hasMusicSelected) return null;
    final id = cameraBloc.selectedMusicId;
    if (id == null || id.isEmpty) return null;
    return MediaEditSoundItem(
      soundId: id,
      soundUrl: cameraBloc.selectedMusicPreviewUrl,
      soundImage: cameraBloc.selectedMusicThumbnailUrl,
      soundArtist: cameraBloc.selectedMusicArtist,
      soundDuration: cameraBloc.selectedMusicDurationSeconds?.toString(),
      soundMetadata: {
        'title': cameraBloc.selectedMusicName,
      },
    );
  }

  /// Maps the post-detail `sound` field into the sound library [SoundTrack]
  /// used by the camera + sound-picker UI.
  static SoundTrack soundTrackFromPostSound(PostSoundInfo sound) {
    final seconds = sound.durationSeconds ?? 0;
    final duration = Duration(
      milliseconds: (seconds * 1000).round().clamp(0, 86400000),
    );
    return SoundTrack(
      id: sound.id,
      thumbnailUrl: sound.thumbnailUrl ?? '',
      trackUrl: sound.previewUrl ?? '',
      title: sound.title?.trim().isNotEmpty == true ? sound.title!.trim() : 'Untitled',
      author: sound.artist?.trim().isNotEmpty == true
          ? sound.artist!.trim()
          : 'Unknown artist',
      duration: duration,
    );
  }

  /// Build a [MediaEditSoundItem] from a post's sound attribution so the
  /// create-post flow can preselect / attribute the audio.
  static MediaEditSoundItem? soundItemFromPostSound(PostSoundInfo? sound) {
    if (sound == null || !sound.hasId) return null;
    return MediaEditSoundItem(
      soundId: sound.id,
      soundUrl: sound.previewUrl,
      soundImage: sound.thumbnailUrl,
      soundArtist: sound.artist,
      soundAlbum: sound.album,
      soundDuration: sound.durationSeconds?.round().toString(),
      soundMetadata: {
        if (sound.title != null) 'title': sound.title,
      },
    );
  }

  static MediaEditSoundItem soundItemFromTrack(SoundTrack track) =>
      MediaEditSoundItem(
        soundId: track.id,
        soundUrl: track.trackUrl,
        soundImage: track.thumbnailUrl,
        soundArtist: track.author,
        soundDuration: track.duration.inSeconds.toString(),
        soundMetadata: {
          'title': track.title,
          if (track.originalStatus != null && track.originalStatus!.isNotEmpty)
            'original_status': track.originalStatus,
        },
      );

  /// Builds `sound_snapshot` for POST `/api/v1/posts` (see API docs / stories).
  ///
  /// Timing fields describe the **sound clip** used on the post, not the full
  /// uploaded video length. Values are capped to a typical reel length (60s).
  static Map<String, dynamic> buildSoundSnapshot({
    required MediaEditSoundItem sound,
    int? videoDurationSeconds,
    int maxClipSec = 60,
  }) {
    const defaultSegmentSec = 30;

    final meta = sound.soundMetadata ?? {};
    final soundSec = int.tryParse(sound.soundDuration ?? '') ??
        _readInt(meta['duration_seconds']) ??
        0;
    final videoSec = videoDurationSeconds ?? 0;

    var startTime = _readInt(meta['start_time']) ?? 0;
    if (startTime < 0) startTime = 0;

    var segmentDuration = _readInt(meta['segment_duration']) ??
        (soundSec > 0 ? soundSec : defaultSegmentSec);
    if (segmentDuration > maxClipSec) segmentDuration = maxClipSec;
    if (videoSec > 0 && segmentDuration > videoSec) {
      segmentDuration = videoSec > maxClipSec ? maxClipSec : videoSec;
    }
    if (segmentDuration <= 0) segmentDuration = defaultSegmentSec;

    var endTime = _readInt(meta['end_time']) ?? startTime + segmentDuration;
    if (endTime <= startTime) endTime = startTime + segmentDuration;
    if (soundSec > 0 && endTime > soundSec) {
      endTime = soundSec;
      segmentDuration = (endTime - startTime).clamp(1, segmentDuration);
    }

    final snapshot = <String, dynamic>{
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'segment_duration': segmentDuration,
      'volume': 1,
      'fade_in': 0,
      'fade_out': 0,
      'loop': false,
    };

    final originalStatus = meta['original_status'] as String?;
    if (originalStatus != null && originalStatus.trim().isNotEmpty) {
      snapshot['original_status'] = originalStatus.trim();
    }

    final title = (meta['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) {
      snapshot['title'] = title;
    }
    final artist = sound.soundArtist?.trim();
    if (artist != null && artist.isNotEmpty) {
      snapshot['artist'] = artist;
    }

    return snapshot;
  }

  /// Merges `sound_id` + `sound_snapshot` into POST `/api/v1/posts` body.
  static void mergeSoundIntoCreatePostJson({
    required Map<String, dynamic> body,
    required MediaEditSoundItem? sound,
    required List<MediaData> media,
  }) {
    if (sound == null || !isLibrarySoundId(sound.soundId)) return;

    final hasVideo = media.any((m) => _isVideoMedia(m));
    final isImageOnly = media.isNotEmpty && !hasVideo;
    final imageCount = imageCountFromMediaData(media);
    final videoDuration = media
        .where(_isVideoMedia)
        .map((m) => m.duration?.toInt())
        .whereType<int>()
        .firstOrNull;
    final imageClipSec = imagePostSoundDurationSeconds(imageCount);

    body['sound_id'] = sound.soundId!.trim();
    body['sound_snapshot'] = buildSoundSnapshot(
      sound: sound,
      videoDurationSeconds: isImageOnly ? imageClipSec : videoDuration,
      maxClipSec: isImageOnly ? imageClipSec : 60,
    );
  }

  static bool _isVideoMedia(MediaData m) =>
      m.mediaType == 'video' ||
      m.postType?.toString().toLowerCase().contains('video') == true;

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Replaces video audio with the selected sound URL/path.
  static Future<String> muxVideoWithSound({
    required String videoPath,
    required MediaEditSoundItem sound,
    bool showLoader = true,
  }) async {
    final musicUrl = sound.soundUrl?.trim() ?? '';
    if (musicUrl.isEmpty) return videoPath;

    if (showLoader) await Utility.showLoader();
    try {
      final videoDurationSec = await MediaUtil.videoDurationSeconds(videoPath);
      final muxed = await MediaUtil.muxVideoWithMusicFromUrl(
        videoPath: videoPath,
        musicUrlOrPath: musicUrl,
        maxDurationSeconds:
            videoDurationSec > 0 ? videoDurationSec : null,
      );
      if (muxed != null &&
          muxed != videoPath &&
          await File(muxed).exists() &&
          await File(muxed).length() > 64) {
        return muxed;
      }
      return videoPath;
    } finally {
      if (showLoader) Utility.closeProgressDialog();
    }
  }

  static Future<String> applySoundToVideoWithCameraBloc({
    required CameraBloc cameraBloc,
    required String videoPath,
  }) async {
    final result = await CameraGallerySoundUtil.applySelectedSoundToVideo(
      cameraBloc: cameraBloc,
      videoPath: videoPath,
    );
    return result.videoPath;
  }
}
