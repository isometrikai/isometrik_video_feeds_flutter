import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_video_editor/easy_video_editor.dart' as eve;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_thumbnail_video/index.dart' show ImageFormat;
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:ism_video_reel_player/domain/models/reel_download_config.dart';
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
    if (resolution == null || resolution.width <= 0 || resolution.height <= 0) {
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
    return _renderVideoToFile(outputPath, renderData);
  }

  /// Replaces video audio with [musicUrlOrPath] (URL or file). Temp download
  /// cleaned on success.
  static Future<String?> muxVideoWithMusicFromUrl({
    required String videoPath,
    required String musicUrlOrPath,
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
      if (result == null || !await out.exists() || await out.length() < 32) {
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

        final fromFile = await _extractAudioFromInput(downloaded.path, outPath);
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

  /// Generates a video thumbnail, trying every available SDK until one succeeds:
  /// 1) `get_thumbnail_video` (VideoThumbnail)
  /// 2) `easy_video_editor` — local files only
  /// 3) `video_compress` — local files only
  /// 4) `pro_video_editor`
  static Future<String?> generateThumbnail({
    required String video,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    if (video.trim().isEmpty) return null;

    final fromGetThumbnail = await _thumbnailWithGetThumbnailVideo(
      video: video,
      headers: headers,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
    if (fromGetThumbnail != null) return fromGetThumbnail;

    final fromEasy = await _thumbnailWithEasyVideoEditor(
      video: video,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
    if (fromEasy != null) return fromEasy;

    final fromCompress = await _thumbnailWithVideoCompress(
      video: video,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      timeMs: timeMs,
      quality: quality,
    );
    if (fromCompress != null) return fromCompress;

    return _thumbnailWithProVideoEditor(
      video: video,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      quality: quality,
    );
  }

  static Future<String?> _thumbnailWithGetThumbnailVideo({
    required String video,
    Map<String, String>? headers,
    String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: video,
        headers: headers,
        thumbnailPath: thumbnailPath,
        imageFormat: imageFormat,
        maxHeight: maxHeight,
        maxWidth: maxWidth,
        timeMs: timeMs,
        quality: quality,
      );
      return _validatedThumbnailPath(thumb.path);
    } catch (e, st) {
      AppLog.error('generateThumbnail get_thumbnail_video: $e\n$st');
      return null;
    }
  }

  static Future<String?> _thumbnailWithEasyVideoEditor({
    required String video,
    String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
    if (_isRemoteVideo(video) || kIsWeb) return null;
    if (!await File(video).exists()) return null;
    if (!Platform.isAndroid && !Platform.isIOS) return null;

    try {
      final outputPath = await _resolveThumbnailOutputPath(
        thumbnailPath,
        imageFormat,
      );
      final result =
          await eve.VideoEditorBuilder(videoPath: video).generateThumbnail(
        positionMs: timeMs,
        quality: quality.clamp(0, 100),
        height: maxHeight > 0 ? maxHeight : null,
        width: maxWidth > 0 ? maxWidth : null,
        outputPath: outputPath,
      );
      return _validatedThumbnailPath(result);
    } catch (e, st) {
      AppLog.error('generateThumbnail easy_video_editor: $e\n$st');
      return null;
    }
  }

  static Future<String?> _thumbnailWithVideoCompress({
    required String video,
    String? thumbnailPath,
    required ImageFormat imageFormat,
    required int timeMs,
    required int quality,
  }) async {
    if (_isRemoteVideo(video) || kIsWeb) return null;
    if (!await File(video).exists()) return null;

    try {
      final clampedQuality = quality.clamp(1, 100);
      final file = await VideoCompress.getFileThumbnail(
        video,
        quality: clampedQuality,
        position: timeMs,
      );
      final validated = await _validatedThumbnailPath(file.path);
      if (validated == null) return null;

      if (thumbnailPath == null || thumbnailPath.isEmpty) {
        return validated;
      }

      final outputPath = await _resolveThumbnailOutputPath(
        thumbnailPath,
        imageFormat,
      );
      await File(validated).copy(outputPath);
      return _validatedThumbnailPath(outputPath);
    } catch (e, st) {
      AppLog.error('generateThumbnail video_compress: $e\n$st');
      try {
        final bytes = await VideoCompress.getByteThumbnail(
          video,
          quality: quality.clamp(1, 100),
          position: timeMs,
        );
        if (bytes == null || bytes.length < 64) return null;
        return _writeThumbnailBytes(bytes, thumbnailPath, imageFormat);
      } catch (e2, st2) {
        AppLog.error('generateThumbnail video_compress bytes: $e2\n$st2');
        return null;
      }
    }
  }

  static Future<String?> _thumbnailWithProVideoEditor({
    required String video,
    String? thumbnailPath,
    required ImageFormat imageFormat,
    required int maxHeight,
    required int maxWidth,
    required int timeMs,
    required int quality,
  }) async {
    try {
      final editorVideo = _isRemoteVideo(video)
          ? EditorVideo.network(video)
          : EditorVideo.file(File(video));
      await editorVideo.safeFilePath();

      var outputWidth = maxWidth > 0 ? maxWidth.toDouble() : 720.0;
      var outputHeight = maxHeight > 0 ? maxHeight.toDouble() : 1280.0;
      try {
        final meta = await ProVideoEditor.instance.getMetadata(editorVideo);
        final res = meta.resolution;
        if (res.width > 0 && res.height > 0) {
          outputWidth = res.width;
          outputHeight = res.height;
          if (maxWidth > 0 && outputWidth > maxWidth) {
            outputHeight = outputHeight * maxWidth / outputWidth;
            outputWidth = maxWidth.toDouble();
          }
          if (maxHeight > 0 && outputHeight > maxHeight) {
            outputWidth = outputWidth * maxHeight / outputHeight;
            outputHeight = maxHeight.toDouble();
          }
        }
      } catch (_) {}

      final thumbs = await ProVideoEditor.instance.getThumbnails(
        ThumbnailConfigs(
          video: editorVideo,
          outputSize: Size(outputWidth, outputHeight),
          timestamps: [Duration(milliseconds: math.max(0, timeMs))],
          outputFormat: _toProThumbnailFormat(imageFormat),
          jpegQuality: quality.clamp(0, 100),
          boxFit: ThumbnailBoxFit.contain,
        ),
      );
      if (thumbs.isEmpty || thumbs.first.length < 64) return null;
      return _writeThumbnailBytes(thumbs.first, thumbnailPath, imageFormat);
    } catch (e, st) {
      AppLog.error('generateThumbnail pro_video_editor: $e\n$st');
      return null;
    }
  }

  static bool _isRemoteVideo(String video) =>
      video.startsWith('http://') || video.startsWith('https://');

  static ThumbnailFormat _toProThumbnailFormat(ImageFormat format) {
    switch (format) {
      case ImageFormat.JPEG:
        return ThumbnailFormat.jpeg;
      case ImageFormat.WEBP:
        return ThumbnailFormat.webp;
      case ImageFormat.PNG:
        return ThumbnailFormat.png;
    }
  }

  static String _thumbnailExtension(ImageFormat format) {
    switch (format) {
      case ImageFormat.JPEG:
        return '.jpg';
      case ImageFormat.WEBP:
        return '.webp';
      case ImageFormat.PNG:
        return '.png';
    }
  }

  static Future<String> _resolveThumbnailOutputPath(
    String? thumbnailPath,
    ImageFormat imageFormat,
  ) async {
    final ext = _thumbnailExtension(imageFormat);
    final fileName = 'thumb_${const Uuid().v4()}$ext';

    if (thumbnailPath == null || thumbnailPath.trim().isEmpty) {
      final tempDir = await getTemporaryDirectory();
      return path.join(tempDir.path, fileName);
    }

    final looksLikeFile = path.extension(thumbnailPath).isNotEmpty;
    if (looksLikeFile) {
      await Directory(path.dirname(thumbnailPath)).create(recursive: true);
      return thumbnailPath;
    }

    await Directory(thumbnailPath).create(recursive: true);
    return path.join(thumbnailPath, fileName);
  }

  static Future<String?> _writeThumbnailBytes(
    Uint8List bytes,
    String? thumbnailPath,
    ImageFormat imageFormat,
  ) async {
    try {
      final outputPath = await _resolveThumbnailOutputPath(
        thumbnailPath,
        imageFormat,
      );
      final out = File(outputPath);
      await out.writeAsBytes(bytes, flush: true);
      return _validatedThumbnailPath(outputPath);
    } catch (e, st) {
      AppLog.error('generateThumbnail write bytes: $e\n$st');
      return null;
    }
  }

  static Future<String?> _validatedThumbnailPath(String? thumbPath) async {
    if (thumbPath == null || thumbPath.trim().isEmpty) return null;
    final file = File(thumbPath);
    if (await file.exists() && await file.length() > 64) {
      return thumbPath;
    }
    return null;
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
        final thumbPath = await generateThumbnail(
          video: videoPath,
          thumbnailPath: outputDir,
          imageFormat: ImageFormat.JPEG,
          quality: quality,
          timeMs: timeMs,
        );
        if (thumbPath == null) continue;
        final score = await _thumbnailLuminanceScore(thumbPath);
        if (score > bestScore) {
          bestScore = score;
          bestPath = thumbPath;
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
  static Future<String?> persistVideoThumbnailForUpload(
      String thumbPath) async {
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

      final rawThumb = await generateThumbnail(
        video: tempVideo.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        quality: quality,
        timeMs: 1000,
      );
      if (rawThumb == null || rawThumb.trim().isEmpty) return null;
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

  /// Loads watermark bytes for gallery downloads.
  ///
  /// Accepts SVG, PNG, or JPG from an HTTPS URL, local file path, or asset
  /// path. SVG sources are rasterized to PNG; raster images are returned as-is.
  static Future<Uint8List?> loadWatermarkBytes(String pathOrUrl) async {
    final source = pathOrUrl.trim();
    if (source.isEmpty) return null;

    try {
      final raw = await _readWatermarkSourceBytes(source);
      if (raw == null || raw.isEmpty) return null;

      if (_looksLikeSvg(source, raw)) {
        final png = await _rasterizeSvgBytesToPng(raw);
        if (png == null) {
          AppLog.error('loadWatermarkBytes: SVG rasterize failed for "$source"');
        }
        return png;
      }

      // PNG / JPG / other rasters — validate they decode so callers fail early.
      if (img.decodeImage(raw) == null) {
        AppLog.error(
          'loadWatermarkBytes: unsupported watermark image for "$source"',
        );
        return null;
      }
      return raw;
    } catch (e, st) {
      AppLog.error('loadWatermarkBytes failed for "$pathOrUrl": $e\n$st');
      return null;
    }
  }

  static Future<Uint8List?> _readWatermarkSourceBytes(String source) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      final uri = Uri.tryParse(source);
      if (uri == null) return null;
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return Uint8List.fromList(response.bodyBytes);
    }

    final file = File(source);
    if (await file.exists()) {
      return file.readAsBytes();
    }

    final data = await rootBundle.load(source);
    return data.buffer.asUint8List();
  }

  static bool _looksLikeSvg(String source, Uint8List bytes) {
    final urlPath =
        Uri.tryParse(source)?.path.toLowerCase() ?? source.toLowerCase();
    if (urlPath.endsWith('.svg') || source.toLowerCase().contains('.svg?')) {
      return true;
    }

    final head = utf8.decode(
      bytes.length > 256 ? bytes.sublist(0, 256) : bytes,
      allowMalformed: true,
    ).trimLeft().toLowerCase();
    return head.startsWith('<svg') ||
        (head.startsWith('<?xml') && head.contains('<svg'));
  }

  /// Rasterizes SVG XML bytes to a PNG suitable for image/video overlays.
  static Future<Uint8List?> _rasterizeSvgBytesToPng(Uint8List svgBytes) async {
    final svgString = utf8.decode(svgBytes);
    final pictureInfo = await vg.loadPicture(
      SvgStringLoader(svgString),
      null,
    );
    try {
      final srcW = pictureInfo.size.width;
      final srcH = pictureInfo.size.height;
      if (srcW <= 0 || srcH <= 0) return null;

      // Upscale tiny viewBoxes so later media-relative scaling stays sharp.
      const minEdge = 512.0;
      const maxEdge = 2048.0;
      var outW = srcW;
      var outH = srcH;
      final longest = math.max(srcW, srcH);
      if (longest < minEdge) {
        final scale = minEdge / longest;
        outW = srcW * scale;
        outH = srcH * scale;
      } else if (longest > maxEdge) {
        final scale = maxEdge / longest;
        outW = srcW * scale;
        outH = srcH * scale;
      }

      final width = outW.round().clamp(1, 4096);
      final height = outH.round().clamp(1, 4096);
      final image = await pictureInfo.picture.toImage(width, height);
      try {
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return null;
        return byteData.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }

  static Future<Uint8List?> applyWatermarkToImageBytes({
    required Uint8List imageBytes,
    required Uint8List watermarkBytes,
    required ReelDownloadWatermarkConfig config,
  }) async {
    try {
      final base = img.decodeImage(imageBytes);
      final watermark = img.decodeImage(watermarkBytes);
      if (base == null || watermark == null) return null;

      final prepared = _prepareWatermarkForCanvas(
        watermarkSource: watermark,
        canvasWidth: base.width,
        canvasHeight: base.height,
        config: config,
      );
      if (prepared == null) return null;

      final coords = _watermarkCoordinates(
        mediaWidth: base.width,
        mediaHeight: base.height,
        watermarkWidth: prepared.watermark.width,
        watermarkHeight: prepared.watermark.height,
        padding: prepared.padding,
        position: config.position,
      );

      img.compositeImage(
        base,
        prepared.watermark,
        dstX: coords.$1,
        dstY: coords.$2,
        blend: img.BlendMode.alpha,
      );
      return Uint8List.fromList(img.encodeJpg(base, quality: 92));
    } catch (e, st) {
      AppLog.error('applyWatermarkToImageBytes failed: $e\n$st');
      return null;
    }
  }

  static ({img.Image watermark, int padding})? _prepareWatermarkForCanvas({
    required img.Image watermarkSource,
    required int canvasWidth,
    required int canvasHeight,
    required ReelDownloadWatermarkConfig config,
  }) {
    final resized = _prepareScaledWatermarkImage(
      watermark: watermarkSource,
      mediaWidth: canvasWidth,
      config: config,
    );
    if (resized == null) return null;

    final padding = config.padding
        .round()
        .clamp(0, math.max(canvasWidth, canvasHeight))
        .toInt();
    return (watermark: resized, padding: padding);
  }

  static img.Image? _prepareScaledWatermarkImage({
    required img.Image watermark,
    required int mediaWidth,
    required ReelDownloadWatermarkConfig config,
  }) {
    final scale = config.scale.clamp(0.05, 1.0);
    final targetWidth = (mediaWidth * scale).round().clamp(1, mediaWidth);
    var resized = img.copyResize(
      watermark,
      width: targetWidth,
      interpolation: img.Interpolation.linear,
    );

    final opacity = config.opacity.clamp(0.0, 1.0);
    if (opacity < 1.0) {
      resized = img.Image.from(resized);
      for (final pixel in resized) {
        pixel.a = (pixel.a * opacity).round().clamp(0, 255);
      }
    }
    return resized;
  }

  /// Resolves display (rotation-corrected) video dimensions for watermark layout.
  static Future<({int displayWidth, int displayHeight})?>
      _probeVideoCanvasLayout(String videoPath) async {
    try {
      final video = EditorVideo.file(File(videoPath));
      await video.safeFilePath();
      final meta = await ProVideoEditor.instance.getMetadata(video);
      final width = meta.resolution.width.round();
      final height = meta.resolution.height.round();
      if (width > 0 && height > 0) {
        return (displayWidth: width, displayHeight: height);
      }
    } catch (e, st) {
      AppLog.error('_probeVideoCanvasLayout pro_video_editor failed: $e\n$st');
    }

    try {
      final info = await VideoCompress.getMediaInfo(videoPath);
      var width = info.width ?? 0;
      var height = info.height ?? 0;
      final orientation = info.orientation ?? 0;
      if (orientation % 180 != 0) {
        final swapped = width;
        width = height;
        height = swapped;
      }
      if (width > 0 && height > 0) {
        return (displayWidth: width, displayHeight: height);
      }
    } catch (e, st) {
      AppLog.error('_probeVideoCanvasLayout media info failed: $e\n$st');
    }

    return null;
  }

  /// Overlays watermark bytes onto [videoFile] via pro_video_editor.
  static Future<File?> applyWatermarkToVideoFile({
    required File videoFile,
    required Uint8List watermarkBytes,
    required ReelDownloadWatermarkConfig config,
  }) async {
    try {
      final decoded = img.decodeImage(watermarkBytes);
      if (decoded == null) return null;

      final canvas = await _probeVideoCanvasLayout(videoFile.path);
      if (canvas == null) {
        AppLog.error(
            'applyWatermarkToVideoFile: could not read video dimensions');
        return null;
      }

      final prepared = _prepareWatermarkForCanvas(
        watermarkSource: decoded,
        canvasWidth: canvas.displayWidth,
        canvasHeight: canvas.displayHeight,
        config: config,
      );
      if (prepared == null) return null;

      final coords = _watermarkCoordinates(
        mediaWidth: canvas.displayWidth,
        mediaHeight: canvas.displayHeight,
        watermarkWidth: prepared.watermark.width,
        watermarkHeight: prepared.watermark.height,
        padding: prepared.padding,
        position: config.position,
      );

      final watermarkPng =
          Uint8List.fromList(img.encodePng(prepared.watermark));
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          path.join(tempDir.path, 'reel_wm_vid_${const Uuid().v4()}.mp4');
      final bitrate = await _exportBitrateForVideoPath(videoFile.path);

      final renderData = VideoRenderData(
        id: 'wm_${const Uuid().v4()}',
        videoSegments: [
          VideoSegment(video: EditorVideo.file(videoFile)),
        ],
        enableAudio: true,
        imageLayers: [
          ImageLayer(
            image: EditorLayerImage.memory(watermarkPng),
            offset: Offset(coords.$1.toDouble(), coords.$2.toDouble()),
            size: Size(
              prepared.watermark.width.toDouble(),
              prepared.watermark.height.toDouble(),
            ),
          ),
        ],
        outputFormat: VideoOutputFormat.mp4,
        bitrate: bitrate,
        shouldOptimizeForNetworkUse: true,
      );

      final result = await _renderVideoToFile(outputPath, renderData);
      if (result == null) return null;

      final out = File(result);
      if (await out.exists() && await out.length() > 64) {
        return out;
      }
      await _deleteIfExists(out);
      return null;
    } catch (e, st) {
      AppLog.error('applyWatermarkToVideoFile failed: $e\n$st');
      return null;
    }
  }

  static (int, int) _watermarkCoordinates({
    required int mediaWidth,
    required int mediaHeight,
    required int watermarkWidth,
    required int watermarkHeight,
    required int padding,
    required ReelDownloadWatermarkPosition position,
  }) {
    switch (position) {
      case ReelDownloadWatermarkPosition.topLeft:
        return (padding, padding);
      case ReelDownloadWatermarkPosition.topRight:
        return (mediaWidth - watermarkWidth - padding, padding);
      case ReelDownloadWatermarkPosition.bottomLeft:
        return (padding, mediaHeight - watermarkHeight - padding);
      case ReelDownloadWatermarkPosition.bottomRight:
        return (
          mediaWidth - watermarkWidth - padding,
          mediaHeight - watermarkHeight - padding,
        );
    }
  }
}
