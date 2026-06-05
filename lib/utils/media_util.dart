import 'dart:io';
import 'dart:math' as math;

import 'package:easy_video_editor/easy_video_editor.dart' as eve;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class MediaUtil {
  static Future<void> _deleteIfExists(File? f) async {
    if (f == null || !await f.exists()) return;
    try {
      await f.delete();
    } catch (_) {}
  }

  static Future<bool> _muxVideoWithExternalAudio({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    required String videoMap,
    required String audioMap,
  }) async {
    try {
      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-i',
        videoPath,
        '-i',
        audioPath,
        '-map',
        videoMap,
        '-map',
        audioMap,
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        '-ar',
        '44100',
        '-ac',
        '2',
        '-b:a',
        '192k',
        '-movflags',
        '+faststart',
        '-shortest',
        outputPath,
      ]);
      final code = await session.getReturnCode();
      final out = File(outputPath);
      if (ReturnCode.isSuccess(code) &&
          await out.exists() &&
          await out.length() > 64) {
        return true;
      }
      AppLog.error(
        'mux attempt failed rc=${code?.getValue()} v=$videoMap a=$audioMap',
      );
      await _deleteIfExists(out);
      return false;
    } catch (e, st) {
      AppLog.error('mux attempt exception: $e\n$st');
      await _deleteIfExists(File(outputPath));
      return false;
    }
  }

  static Future<bool> _tryMuxVariants({
    required String videoPath,
    required String audioPath,
    required String outputPath,
  }) async {
    const variants = <List<String>>[
      ['0:v:0', '1:a:0'],
      ['0:v', '1:a:0'],
      ['0:v:0', '1:a'],
      ['0:v', '1:a'],
      ['0:v:0', '1:0'],
      ['0:v', '1:0'],
    ];
    for (final pair in variants) {
      final ok = await _muxVideoWithExternalAudio(
        videoPath: videoPath,
        audioPath: audioPath,
        outputPath: outputPath,
        videoMap: pair[0],
        audioMap: pair[1],
      );
      if (ok) return true;
    }
    return false;
  }

  /// Replaces video audio with [musicUrlOrPath] (URL or file). Mux, strip-then-mux,
  /// and several `-map` variants; temp download cleaned on success.
  static Future<String?> muxVideoWithMusicFromUrl({
    required String videoPath,
    required String musicUrlOrPath,
  }) async {
    File? strippedVideoFile;
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

      if (await _tryMuxVariants(
        videoPath: videoPath,
        audioPath: audioPath,
        outputPath: outputPath,
      )) {
        await _deleteIfExists(downloaded);
        return outputPath;
      }

      strippedVideoFile = File(
        path.join(tempDir.path, 'video_noaudio_${const Uuid().v4()}.mp4'),
      );
      var stripOk = false;
      for (final map in ['0:v:0', '0:v']) {
        final stripSession = await FFmpegKit.executeWithArguments([
          '-y',
          '-i',
          videoPath,
          '-map',
          map,
          '-c:v',
          'copy',
          '-an',
          strippedVideoFile.path,
        ]);
        final stripCode = await stripSession.getReturnCode();
        stripOk = ReturnCode.isSuccess(stripCode) &&
            await strippedVideoFile.exists() &&
            await strippedVideoFile.length() > 64;
        if (stripOk) break;
        await _deleteIfExists(strippedVideoFile);
      }
      if (!stripOk) {
        AppLog.error('muxVideoWithMusicFromUrl: strip audio failed');
        await _deleteIfExists(downloaded);
        return null;
      }

      if (await _tryMuxVariants(
        videoPath: strippedVideoFile.path,
        audioPath: audioPath,
        outputPath: outputPath,
      )) {
        await _deleteIfExists(strippedVideoFile);
        await _deleteIfExists(downloaded);
        return outputPath;
      }

      await _deleteIfExists(strippedVideoFile);
      await _deleteIfExists(File(outputPath));
      await _deleteIfExists(downloaded);
      return null;
    } catch (e, st) {
      AppLog.error('muxVideoWithMusicFromUrl: $e\n$st');
      return null;
    } finally {
      await _deleteIfExists(strippedVideoFile);
    }
  }

  /// Merges [videoPaths] into one file (easy_video_editor, then FFmpeg fallbacks).
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

    final concatCopyOut = path.join(tempDir.path, 'merged_concat_copy_$ts.mp4');
    final copy =
        await _mergeSegmentsFfmpegConcatCopy(videoPaths, concatCopyOut);
    if (copy != null) return copy;

    final filterOut = path.join(tempDir.path, 'merged_concat_filter_$ts.mp4');
    return _mergeSegmentsFfmpegFilterConcatVideoOnly(videoPaths, filterOut);
  }

  static String _escapePathForConcatList(String p) =>
      File(p).absolute.path.replaceAll("'", "'\\''");

  static Future<String?> _mergeSegmentsFfmpegConcatCopy(
    List<String> videoPaths,
    String outputPath,
  ) async {
    File? listFile;
    try {
      final tempDir = await getTemporaryDirectory();
      listFile = File(
        path.join(tempDir.path, 'concat_list_${const Uuid().v4()}.txt'),
      );
      final sb = StringBuffer();
      for (final p in videoPaths) {
        sb.writeln("file '${_escapePathForConcatList(p)}'");
      }
      await listFile.writeAsString(sb.toString());

      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        listFile.path,
        '-c',
        'copy',
        outputPath,
      ]);
      final code = await session.getReturnCode();
      final out = File(outputPath);
      if (ReturnCode.isSuccess(code) &&
          await out.exists() &&
          await out.length() > 64) {
        return outputPath;
      }
      AppLog.error(
        'mergeVideoSegments: concat copy failed rc=${code?.getValue()}',
      );
      await _deleteIfExists(out);
      return null;
    } catch (e, st) {
      AppLog.error('mergeVideoSegments: concat copy exception: $e\n$st');
      await _deleteIfExists(File(outputPath));
      return null;
    } finally {
      await _deleteIfExists(listFile);
    }
  }

  static Future<String?> _mergeSegmentsFfmpegFilterConcatVideoOnly(
    List<String> videoPaths,
    String outputPath,
  ) async {
    try {
      final args = <String>['-y'];
      for (final p in videoPaths) {
        args.addAll(['-i', p]);
      }
      final n = videoPaths.length;
      final ins = List.generate(n, (i) => '[$i:v:0]').join('');
      final filter = '${ins}concat=n=$n:v=1:a=0[outv]';
      args.addAll([
        '-filter_complex',
        filter,
        '-map',
        '[outv]',
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '23',
        '-movflags',
        '+faststart',
        outputPath,
      ]);
      final session = await FFmpegKit.executeWithArguments(args);
      final code = await session.getReturnCode();
      final out = File(outputPath);
      if (ReturnCode.isSuccess(code) &&
          await out.exists() &&
          await out.length() > 64) {
        return outputPath;
      }
      AppLog.error(
        'mergeVideoSegments: filter concat failed rc=${code?.getValue()}',
      );
      await _deleteIfExists(out);
      return null;
    } catch (e, st) {
      AppLog.error('mergeVideoSegments: filter concat exception: $e\n$st');
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

  static Future<String?> _extractAudioFromInput(
    String inputPathOrUrl,
    String outPath,
  ) async {
    try {
      return await () async {
        final session = await FFmpegKit.executeWithArguments([
          '-y',
          '-i',
          inputPathOrUrl,
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          '-movflags',
          '+faststart',
          outPath,
        ]);
        final code = await session.getReturnCode();
        final out = File(outPath);
        if (!ReturnCode.isSuccess(code) ||
            !await out.exists() ||
            await out.length() < 32) {
          await _deleteIfExists(out);
          return null;
        }
        return outPath;
      }()
          .timeout(_extractAudioTimeout, onTimeout: () {
        AppLog.error('extractAudioFromVideoToM4a: ffmpeg timed out');
        return null;
      });
    } catch (e, st) {
      AppLog.error('extractAudioFromVideoToM4a ffmpeg: $e\n$st');
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
  /// Remote URLs are processed via FFmpeg first (no full download). Falls back to
  /// a capped streaming download when direct read fails.
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
        final fromUrl = await _extractAudioFromInput(videoPathOrUrl, outPath);
        if (fromUrl != null) return fromUrl;
        await _deleteIfExists(File(outPath));

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
}
