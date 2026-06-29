import 'dart:io';
import 'dart:math' as math;

import 'package:easy_video_editor/easy_video_editor.dart' as eve;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class MediaUtil {
  /// Headroom applied on top of source/floor bitrate to offset generation loss
  /// when re-encoding (each export is a lossy pass).
  static const double _exportBitrateHeadroom = 1.25;

  /// Resolves export bitrate that preserves quality across re-encodes.
  ///
  /// iOS reports bitrate as an average derived from file size, which drops
  /// after prior transcodes and maps to lower AVAssetExportSession presets.
  static int? resolveVideoExportBitrate({
    int? metadataBitrate,
    Size? resolution,
  }) {
    final floor = _minimumBitrateForResolution(resolution);
    final int? target;
    if (metadataBitrate != null && metadataBitrate > 0) {
      target = math.max(metadataBitrate, floor);
    } else if (floor > 0) {
      target = floor;
    } else {
      return null;
    }
    return (target * _exportBitrateHeadroom).round();
  }

  static int _minimumBitrateForResolution(Size? resolution) {
    if (resolution == null ||
        resolution.width <= 0 ||
        resolution.height <= 0) {
      return 8000000;
    }
    final pixels = resolution.width * resolution.height;
    if (pixels >= 3840 * 2160) return 35000000;
    if (pixels >= 1920 * 1080) return 16000000;
    if (pixels >= 1280 * 720) return 5000000;
    if (pixels >= 854 * 480) return 2500000;
    return 1000000;
  }

  static Future<int?> _exportBitrateForVideoPath(String videoPath) async {
    try {
      final video = EditorVideo.file(File(videoPath));
      await video.safeFilePath();
      final meta = await ProVideoEditor.instance.getMetadata(video);
      return resolveVideoExportBitrate(
        metadataBitrate: meta.bitrate,
        resolution: meta.resolution,
      );
    } catch (e, st) {
      AppLog.error('_exportBitrateForVideoPath: $e\n$st');
      return null;
    }
  }

  static Future<void> _deleteIfExists(File? f) async {
    if (f == null || !await f.exists()) return;
    try {
      await f.delete();
    } catch (_) {}
  }

  static Future<String?> _renderVideoToFile(
    String outputPath,
    VideoRenderData renderData,
  ) async {
    try {
      final result = await ProVideoEditor.instance.renderVideoToFile(
        outputPath,
        renderData,
      );
      final out = File(result);
      if (await out.exists() && await out.length() > 64) {
        return result;
      }
      AppLog.error('renderVideoToFile: output missing or too small');
      await _deleteIfExists(out);
      return null;
    } catch (e, st) {
      AppLog.error('renderVideoToFile: $e\n$st');
      await _deleteIfExists(File(outputPath));
      return null;
    }
  }

  static Future<String?> _muxVideoWithAudioPath({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    int? maxDurationSeconds,
  }) async {
    final bitrate = await _exportBitrateForVideoPath(videoPath);
    final renderData = VideoRenderData(
      id: 'mux_${const Uuid().v4()}',
      videoSegments: [
        VideoSegment(video: EditorVideo.file(File(videoPath))),
      ],
      enableAudio: false,
      audioTracks: [
        VideoAudioTrack(path: audioPath, loop: true),
      ],
      outputFormat: VideoOutputFormat.mp4,
      bitrate: bitrate,
      shouldOptimizeForNetworkUse: true,
    );
    final muxed = await _renderVideoToFile(outputPath, renderData);
    if (muxed == null) return null;
    if (maxDurationSeconds != null && maxDurationSeconds > 0) {
      final durationSec = await videoDurationSeconds(muxed);
      if (durationSec > maxDurationSeconds) {
        return trimVideoSegment(
          inputPath: muxed,
          start: Duration.zero,
          end: Duration(seconds: maxDurationSeconds),
        );
      }
    }
    return muxed;
  }

  /// Replaces video audio with [musicUrlOrPath] (URL or file). Temp download
  /// cleaned on success.
  ///
  /// When [maxDurationSeconds] is set, output is trimmed to that length so audio
  /// cannot outlast the video.
  static Future<String?> muxVideoWithMusicFromUrl({
    required String videoPath,
    required String musicUrlOrPath,
    int? maxDurationSeconds,
  }) async {
    File? downloaded;
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        AppLog.error('muxVideoWithMusicFromUrl: video missing at $videoPath');
        return null;
      }
      if (musicUrlOrPath.isEmpty) return videoPath;

      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'video_with_sound_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      String audioPath;
      if (musicUrlOrPath.startsWith('http://') ||
          musicUrlOrPath.startsWith('https://')) {
        final uri = Uri.tryParse(musicUrlOrPath);
        if (uri == null) return null;
        final ext = path.extension(uri.path);
        final suffix = (ext.isNotEmpty && ext.length <= 6) ? ext : '.audio';
        downloaded = File(
          path.join(tempDir.path, 'mux_audio_${const Uuid().v4()}$suffix'),
        );
        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          AppLog.error(
            'muxVideoWithMusicFromUrl: download failed ${response.statusCode}',
          );
          return null;
        }
        await downloaded.writeAsBytes(response.bodyBytes);
        if (await downloaded.length() < 32) {
          AppLog.error('muxVideoWithMusicFromUrl: downloaded audio too small');
          await _deleteIfExists(downloaded);
          return null;
        }
        audioPath = downloaded.path;
      } else {
        final f = File(musicUrlOrPath);
        if (!await f.exists()) return null;
        audioPath = f.path;
      }

      final muxed = await _muxVideoWithAudioPath(
        videoPath: videoPath,
        audioPath: audioPath,
        outputPath: outputPath,
        maxDurationSeconds: maxDurationSeconds,
      );
      if (muxed != null) {
        await _deleteIfExists(downloaded);
        return muxed;
      }

      await _deleteIfExists(File(outputPath));
      await _deleteIfExists(downloaded);
      return null;
    } catch (e, st) {
      AppLog.error('muxVideoWithMusicFromUrl: $e\n$st');
      return null;
    } finally {
      await _deleteIfExists(downloaded);
    }
  }

  /// Merges [videoPaths] into one file (easy_video_editor, then pro_video_editor).
  static Future<String?> mergeVideoSegments(List<String> videoPaths,
      {Function(int progress)? onProgress}) async {
    if (videoPaths.isEmpty) {
      return null;
    }
    if (videoPaths.length == 1) {
      return videoPaths.first;
    }

    for (final p in videoPaths) {
      if (!await File(p).exists()) {
        AppLog.error('mergeVideoSegments: file missing: $p');
        return null;
      }
    }

    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final easyOut = path.join(tempDir.path, 'merged_easy_$ts.mp4');

    try {
      final other = videoPaths.sublist(1);
      final editor = eve.VideoEditorBuilder(videoPath: videoPaths.first)
          .merge(otherVideoPaths: other);
      var progress = 0;
      final result = await editor.export(
        outputPath: easyOut,
        onProgress: (progressValue) {
          final mProgressPercent = (progressValue * 100).toInt();
          if (mProgressPercent != progress) {
            progress = mProgressPercent;
            onProgress?.call(progress);
          }
        },
      );
      if (result != null) {
        final f = File(result);
        if (await f.exists() && await f.length() > 64) {
          return result;
        }
      }
      AppLog.error(
          'mergeVideoSegments: easy_video_editor returned no usable file');
    } on PlatformException catch (e) {
      AppLog.error(
        'mergeVideoSegments: easy_video_editor PlatformException ${e.code} ${e.message}',
      );
    } catch (e, st) {
      AppLog.error('mergeVideoSegments: easy_video_editor failed: $e\n$st');
    }

    await _deleteIfExists(File(easyOut));

    final proOut = path.join(tempDir.path, 'merged_pro_$ts.mp4');
    return _mergeSegmentsWithProVideoEditor(videoPaths, proOut);
  }

  static Future<String?> _mergeSegmentsWithProVideoEditor(
    List<String> videoPaths,
    String outputPath,
  ) async {
    try {
      final bitrate = await _exportBitrateForVideoPath(videoPaths.first);
      final segments = videoPaths
          .map((p) => VideoSegment(video: EditorVideo.file(File(p))))
          .toList();
      final renderData = VideoRenderData(
        id: 'merge_${const Uuid().v4()}',
        videoSegments: segments,
        outputFormat: VideoOutputFormat.mp4,
        bitrate: bitrate,
        shouldOptimizeForNetworkUse: true,
      );
      return _renderVideoToFile(outputPath, renderData);
    } catch (e, st) {
      AppLog.error('mergeVideoSegments: pro_video_editor exception: $e\n$st');
      await _deleteIfExists(File(outputPath));
      return null;
    }
  }

  static Future<File> flipImage(
    File file,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return file;

      final flipped = img.flipHorizontal(image);

      final newPath = path.join(
        file.parent.path,
        'fixed_${path.basename(file.path)}',
      );

      final fixedFile = File(newPath)..writeAsBytesSync(img.encodeJpg(flipped));

      return fixedFile;
    } catch (e) {
      AppLog.error('Error mirroring image: $e');
      return file;
    }
  }

  static Future<File> mirrorMedia(File file,
      {Function(int progress)? onProgress}) async {
    final mediaType = Utility.getMediaType(file);

    if (mediaType == MediaType.photo) {
      return flipImage(file);
    } else {
      return flipVideo(file, onProgress: onProgress);
    }
  }

  static Future<File> flipVideo(File file,
      {Function(int progress)? onProgress}) async {
    try {
      // Create output file path
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(tempDir.path, 'merged_video_$timestamp.mp4');
      var progress = 0;
      final editor = eve.VideoEditorBuilder(videoPath: file.path)
          .flip(flipDirection: eve.FlipDirection.horizontal);

      final result = await editor.export(
          outputPath: outputPath,
          onProgress: (progressValue) {
            final mProgressPercent = (progressValue * 100).toInt();
            if (mProgressPercent != progress) {
              progress = mProgressPercent;
              onProgress?.call(progress);
            }
          });

      if (result != null) {
        final outputFile = File(result);
        if (await outputFile.exists()) {
          return outputFile;
        } else {
          AppLog.error('ERROR: Merged file does not exist at: $result');
        }
      } else {
        AppLog.error('ERROR: Native method returned null');
      }
      return file;
    } catch (e) {
      AppLog.error('Error mirroring image: $e');
      return file;
    }
  }

  static const Duration _extractAudioTimeout = Duration(seconds: 90);
  static const int _maxReelDownloadBytes = 80 * 1024 * 1024;

  static Future<String?> _extractAudioWithEasyEditor(
    String inputPath,
    String outPath,
  ) async {
    try {
      final result = await eve.VideoEditorBuilder(videoPath: inputPath)
          .extractAudio(outputPath: outPath);
      final out = File(result ?? '');
      if (result == null ||
          !await out.exists() ||
          await out.length() < 32) {
        await _deleteIfExists(out);
        return null;
      }
      return result;
    } catch (e, st) {
      AppLog.error('extractAudio easy_video_editor: $e\n$st');
      await _deleteIfExists(File(outPath));
      return null;
    }
  }

  static Future<String?> _extractAudioWithProVideoEditor(
    String inputPath,
    String outPath,
  ) async {
    try {
      final config = AudioExtractConfigs(
        video: EditorVideo.file(File(inputPath)),
        format: AudioFormat.m4a,
      );
      final result = await ProVideoEditor.instance.extractAudioToFile(
        outPath,
        config,
      );
      final out = File(result);
      if (!await out.exists() || await out.length() < 32) {
        await _deleteIfExists(out);
        return null;
      }
      return result;
    } catch (e, st) {
      AppLog.error('extractAudio pro_video_editor: $e\n$st');
      await _deleteIfExists(File(outPath));
      return null;
    }
  }

  static Future<String?> _extractAudioFromInput(
    String inputPath,
    String outPath,
  ) async {
    try {
      return await () async {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final fromEasy =
              await _extractAudioWithEasyEditor(inputPath, outPath);
          if (fromEasy != null) return fromEasy;
          await _deleteIfExists(File(outPath));
        }
        return _extractAudioWithProVideoEditor(inputPath, outPath);
      }()
          .timeout(_extractAudioTimeout, onTimeout: () {
        AppLog.error('extractAudioFromVideoToM4a: extraction timed out');
        return null;
      });
    } catch (e, st) {
      AppLog.error('extractAudioFromVideoToM4a: $e\n$st');
      await _deleteIfExists(File(outPath));
      return null;
    }
  }

  static Future<File?> _downloadReelVideoForAudioExtract(Uri uri) async {
    final tempDir = await getTemporaryDirectory();
    final downloaded = File(
      path.join(tempDir.path, 'download_vid_${const Uuid().v4()}.mp4'),
    );
    try {
      final request = http.Request('GET', uri);
      final response =
          await http.Client().send(request).timeout(_extractAudioTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLog.error(
          'extractAudioFromVideoToM4a: download ${response.statusCode}',
        );
        return null;
      }

      final sink = downloaded.openWrite();
      var total = 0;
      await for (final chunk in response.stream) {
        total += chunk.length;
        if (total > _maxReelDownloadBytes) {
          AppLog.error('extractAudioFromVideoToM4a: video exceeds size cap');
          await sink.close();
          await _deleteIfExists(downloaded);
          return null;
        }
        sink.add(chunk);
      }
      await sink.close();

      if (await downloaded.length() < 64) {
        await _deleteIfExists(downloaded);
        return null;
      }
      return downloaded;
    } catch (e, st) {
      AppLog.error('extractAudioFromVideoToM4a download: $e\n$st');
      await _deleteIfExists(downloaded);
      return null;
    }
  }

  /// Extracts the audio stream from a remote or local MP4/video into AAC/M4A.
  ///
  /// Remote URLs are downloaded first, then processed with native editors.
  static Future<String?> extractAudioFromVideoToM4a(
      String videoPathOrUrl) async {
    File? downloaded;
    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = path.join(
        tempDir.path,
        'extracted_reel_audio_${const Uuid().v4()}.m4a',
      );

      final isRemote = videoPathOrUrl.startsWith('http://') ||
          videoPathOrUrl.startsWith('https://');

      if (isRemote) {
        final uri = Uri.tryParse(videoPathOrUrl);
        if (uri == null) return null;
        downloaded = await _downloadReelVideoForAudioExtract(uri);
        if (downloaded == null) return null;

        final fromFile =
            await _extractAudioFromInput(downloaded.path, outPath);
        await _deleteIfExists(downloaded);
        downloaded = null;
        return fromFile;
      }

      final f = File(videoPathOrUrl);
      if (!await f.exists()) return null;
      return _extractAudioFromInput(f.path, outPath);
    } catch (e, st) {
      AppLog.error('extractAudioFromVideoToM4a: $e\n$st');
      await _deleteIfExists(downloaded);
      return null;
    }
  }

  static Future<String?> pickBestVideoThumbnailPath({
    required String videoPath,
    String? thumbnailPath,
    int quality = 75,
  }) async {
    final videoFile = File(videoPath);
    if (!await videoFile.exists()) return null;

    final durationMs = await _videoDurationMs(videoPath);
    final outputDir = thumbnailPath ??
        path.join(
          (await getApplicationDocumentsDirectory()).path,
          'media',
          'thumbs',
        );
    await Directory(outputDir).create(recursive: true);

    final timesMs = _thumbnailCandidateTimesMs(durationMs);
    String? bestPath;
    var bestScore = -1.0;

    for (final timeMs in timesMs) {
      try {
        final thumb = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: outputDir,
          quality: quality,
          timeMs: timeMs,
        );
        final score = await _thumbnailLuminanceScore(thumb.path);
        if (score > bestScore) {
          bestScore = score;
          bestPath = thumb.path;
        }
      } catch (e) {
        AppLog.error('pickBestVideoThumbnailPath @$timeMs ms: $e');
      }
    }
    return bestPath;
  }

  /// Decodes URL-escaped segments (e.g. `%20`) in iOS local media paths.
  static String normalizeLocalMediaPath(String raw) {
    var p = raw.trim();
    if (p.isEmpty) return p;
    if (!p.contains('%')) return p;
    try {
      return Uri.decodeFull(p);
    } catch (_) {
      return p;
    }
  }

  /// Resolves a readable on-disk file when the path may be URL-encoded.
  static Future<File?> openReadableMediaFile(String raw) async {
    final candidates = <String>{
      raw.trim(),
      normalizeLocalMediaPath(raw),
    };
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final file = File(candidate);
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    }
    return null;
  }

  /// Copies a generated thumbnail into app documents with a stable `.jpg` path.
  static Future<String?> persistVideoThumbnailForUpload(String thumbPath) async {
    final src = await openReadableMediaFile(thumbPath);
    if (src == null) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(docs.path, 'media', 'story_previews'));
    await dir.create(recursive: true);
    final dest = File(
      path.join(
        dir.path,
        'story_preview_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    try {
      await src.copy(dest.path);
    } catch (_) {
      try {
        await dest.writeAsBytes(await src.readAsBytes(), flush: true);
      } catch (e, st) {
        AppLog.error('persistVideoThumbnailForUpload: $e\n$st');
        return null;
      }
    }

    if (await dest.exists() && await dest.length() > 0) {
      return dest.path;
    }
    return null;
  }

  /// Like [pickBestVideoThumbnailPath] but copies long iOS picker paths to a short
  /// temp file when generation fails (common for story videos).
  static Future<String?> safePickBestVideoThumbnailPath({
    required String videoPath,
    int quality = 75,
  }) async {
    final normalizedVideoPath = normalizeLocalMediaPath(videoPath);
    final videoFile = await openReadableMediaFile(normalizedVideoPath);
    if (videoFile == null) return null;
    final resolvedVideoPath = videoFile.path;

    Future<String?> generateFrom(String path) async {
      final tempDir = await getTemporaryDirectory();
      return pickBestVideoThumbnailPath(
        videoPath: path,
        thumbnailPath: tempDir.path,
        quality: quality,
      );
    }

    try {
      final direct = await generateFrom(resolvedVideoPath);
      if (direct != null && direct.trim().isNotEmpty) {
        return persistVideoThumbnailForUpload(direct);
      }
    } catch (e, st) {
      AppLog.error('safePickBestVideoThumbnailPath direct: $e\n$st');
    }

    File? tempVideo;
    try {
      final tempDir = await getTemporaryDirectory();
      final ext = path.extension(resolvedVideoPath);
      final shortVideoPath = path.join(
        tempDir.path,
        'story_vid_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      tempVideo = await videoFile.copy(shortVideoPath);

      final fromCopy = await generateFrom(tempVideo.path);
      if (fromCopy != null && fromCopy.trim().isNotEmpty) {
        return persistVideoThumbnailForUpload(fromCopy);
      }

      final thumb = await VideoThumbnail.thumbnailFile(
        video: tempVideo.path,
        thumbnailPath: tempDir.path,
        quality: quality,
        timeMs: 1000,
      );
      final rawThumb = thumb.path.trim();
      if (rawThumb.isEmpty) return null;
      return persistVideoThumbnailForUpload(rawThumb);
    } catch (e, st) {
      AppLog.error('safePickBestVideoThumbnailPath fallback: $e\n$st');
      return null;
    } finally {
      if (tempVideo != null) {
        try {
          if (await tempVideo.exists()) await tempVideo.delete();
        } catch (_) {}
      }
    }
  }

  static Future<int> videoDurationSeconds(String videoPath) async {
    final ms = await _videoDurationMs(videoPath);
    if (ms <= 0) return 0;
    return (ms / 1000).round();
  }

  static Future<int> _videoDurationMs(String videoPath) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoPath);
      return (info.duration ?? 0).round();
    } catch (_) {
      return 0;
    }
  }

  static List<int> _thumbnailCandidateTimesMs(int durationMs) {
    const minMs = 1500;
    if (durationMs <= 0) {
      return const [minMs, 2500, 3500, 5000];
    }
    if (durationMs <= minMs + 400) {
      final mid = (durationMs * 0.5).round();
      return [mid.clamp(0, durationMs)];
    }

    final maxMs = math.max(minMs, durationMs - 400);
    final times = <int>{
      minMs,
      2500,
      3500,
      (durationMs * 0.2).round(),
      (durationMs * 0.35).round(),
      (durationMs * 0.5).round(),
      (durationMs * 0.65).round(),
    };
    return times.where((t) => t >= minMs && t <= maxMs).toList()..sort();
  }

  static Future<double> _thumbnailLuminanceScore(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      if (bytes.length < 64) return 0;
      final image = img.decodeImage(bytes);
      if (image == null) return 0;

      var sum = 0.0;
      var count = 0;
      final stepX = math.max(1, image.width ~/ 20);
      final stepY = math.max(1, image.height ~/ 20);
      for (var y = 0; y < image.height; y += stepY) {
        for (var x = 0; x < image.width; x += stepX) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          sum += 0.299 * r + 0.587 * g + 0.114 * b;
          count++;
        }
      }
      return count > 0 ? sum / count : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Trims [inputPath] to [start, end] without re-encoding when possible.
  static Future<String?> trimVideoSegment({
    required String inputPath,
    required Duration start,
    required Duration end,
  }) async {
    if (end <= start) return null;

    final input = await openReadableMediaFile(inputPath);
    if (input == null) {
      AppLog.error('trimVideoSegment: input missing at $inputPath');
      return null;
    }

    final dir = await getTemporaryDirectory();
    final outputPath = path.join(
      dir.path,
      'trim_${const Uuid().v4()}.mp4',
    );

    const slack = Duration(milliseconds: 250);
    final durationMs = await _videoDurationMs(input.path);
    if (durationMs > 0 &&
        start <= Duration.zero &&
        end >= Duration(milliseconds: durationMs) - slack) {
      return input.path;
    }

    try {
      final bitrate = await _exportBitrateForVideoPath(input.path);
      final renderData = VideoRenderData(
        id: 'trim_${const Uuid().v4()}',
        videoSegments: [
          VideoSegment(video: EditorVideo.file(input)),
        ],
        startTime: start,
        endTime: end,
        outputFormat: VideoOutputFormat.mp4,
        bitrate: bitrate,
        shouldOptimizeForNetworkUse: true,
      );
      return _renderVideoToFile(outputPath, renderData);
    } catch (e, st) {
      AppLog.error('trimVideoSegment: $e\n$st');
      await _deleteIfExists(File(outputPath));
      return null;
    }
  }
}
