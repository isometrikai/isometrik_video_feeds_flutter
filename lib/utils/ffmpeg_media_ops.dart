import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_video/statistics.dart';
import 'package:ffmpeg_kit_flutter_new_video/stream_information.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Width, height, duration, and bitrate read from ffprobe.
class FfmpegMediaInfo {
  const FfmpegMediaInfo({
    required this.durationMs,
    required this.width,
    required this.height,
    required this.bitrate,
  });

  final int bitrate;
  final int durationMs;
  final int height;
  final int width;
}

/// Thumbnail, compress, concat, flip, audio, and trim helpers on FFmpeg.
class FfmpegMediaOps {
  FfmpegMediaOps._();

  static const String _evenScale = 'scale=trunc(iw/2)*2:trunc(ih/2)*2';
  static const String _compressScale =
      "scale='min(1280,iw)':-2,scale=trunc(iw/2)*2:trunc(ih/2)*2";

  /// Probes [videoPath]. Returns null when ffprobe cannot read the file.
  static Future<FfmpegMediaInfo?> probe(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final info = session.getMediaInformation();
      if (info == null) return null;
      final seconds = double.tryParse(info.getDuration() ?? '') ?? 0;
      final durationMs = seconds > 0 ? (seconds * 1000).round() : 0;

      var width = 0;
      var height = 0;
      var bitrate = int.tryParse(info.getBitrate() ?? '') ?? 0;
      for (final stream in info.getStreams()) {
        if (stream.getType() != 'video') continue;
        final rawWidth = stream.getWidth() ?? 0;
        final rawHeight = stream.getHeight() ?? 0;
        if (rawWidth <= 0 || rawHeight <= 0) continue;
        final rotation = _rotationDegrees(stream);
        final swap = rotation == 90 || rotation == 270;
        width = swap ? rawHeight : rawWidth;
        height = swap ? rawWidth : rawHeight;
        final streamBitrate = int.tryParse(stream.getBitrate() ?? '') ?? 0;
        if (streamBitrate > 0) bitrate = streamBitrate;
        break;
      }

      return FfmpegMediaInfo(
        durationMs: durationMs,
        width: width,
        height: height,
        bitrate: bitrate,
      );
    } catch (_) {
      return null;
    }
  }

  /// Duration in milliseconds, or 0 when the file cannot be probed.
  static Future<int> durationMilliseconds(String videoPath) async {
    final info = await probe(videoPath);
    return info?.durationMs ?? 0;
  }

  /// Writes one frame from [video] to [outputPath].
  static Future<String?> thumbnail({
    required String video,
    required String outputPath,
    Map<String, String>? headers,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 75,
  }) async {
    final args = <String>['-y'];
    final headerBlock = _headerBlock(headers);
    if (headerBlock != null && _isRemote(video)) {
      args
        ..add('-headers')
        ..add(headerBlock);
    }
    args
      ..add('-i')
      ..add(video);
    if (timeMs > 0) {
      args
        ..add('-ss')
        ..add((timeMs / 1000).toStringAsFixed(3));
    }
    args
      ..add('-frames:v')
      ..add('1');
    final scale = _thumbnailScale(maxWidth, maxHeight);
    if (scale != null) {
      args
        ..add('-vf')
        ..add(scale);
    }
    _addStillCodec(args, outputPath, quality);
    args.add(outputPath);

    final wrote = await _run(arguments: args, outputPath: outputPath);
    return wrote ? outputPath : null;
  }

  /// Evenly spaced JPEG frames for a trim filmstrip.
  static Future<List<Uint8List>> keyFrameBytes({
    required String videoPath,
    required int count,
    required Duration duration,
    required int side,
  }) async {
    if (count <= 0) return const [];
    final totalMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds
        : await durationMilliseconds(videoPath);
    if (totalMs <= 0) return const [];

    final dir = await getTemporaryDirectory();
    final frames = <Uint8List>[];
    for (var i = 0; i < count; i++) {
      final timeMs = (totalMs * (i + 0.5) / count).round().clamp(0, totalMs);
      final outputPath = path.join(
        dir.path,
        'kf_${DateTime.now().microsecondsSinceEpoch}_$i.jpg',
      );
      final written = await thumbnail(
        video: videoPath,
        outputPath: outputPath,
        maxWidth: side,
        maxHeight: side,
        timeMs: timeMs,
        quality: 70,
      );
      if (written == null) continue;
      try {
        frames.add(await File(written).readAsBytes());
      } catch (_) {
        // A single unreadable frame is skipped.
      } finally {
        await _delete(File(written));
      }
    }
    return frames;
  }

  /// Re-encodes [inputPath] toward a smaller 720p-class file.
  ///
  /// [onProgress] is 0–100.
  static Future<String?> compressVideo({
    required String inputPath,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final outputPath = path.join(
      dir.path,
      'compressed_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final length = Duration(milliseconds: await durationMilliseconds(inputPath));
    final ok = await _encodeWithFallback(
      arguments: (encoder) => _videoEncodeArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        encoder: encoder,
        videoFilter: _compressScale,
        bitrate: '2500k',
      ),
      outputPath: outputPath,
      progressLength: length,
      onProgress: onProgress == null
          ? null
          : (value) => onProgress((value * 100).clamp(0, 100).toDouble()),
    );
    if (ok) {
      onProgress?.call(100);
      return outputPath;
    }
    return null;
  }

  /// Joins [videoPaths] in order. [onProgress] is 0–100.
  static Future<String?> concat({
    required List<String> videoPaths,
    required String outputPath,
    void Function(int progress)? onProgress,
  }) async {
    if (videoPaths.isEmpty) return null;
    final listFile = File(
      path.join(
        (await getTemporaryDirectory()).path,
        'concat_${DateTime.now().microsecondsSinceEpoch}.txt',
      ),
    );
    try {
      final lines = videoPaths.map(_concatLine).join('\n');
      await listFile.writeAsString(lines);
      var totalMs = 0;
      for (final videoPath in videoPaths) {
        totalMs += await durationMilliseconds(videoPath);
      }
      final length = Duration(milliseconds: totalMs);
      final copied = await _run(
        arguments: [
          '-y',
          '-f',
          'concat',
          '-safe',
          '0',
          '-i',
          listFile.path,
          '-c',
          'copy',
          '-movflags',
          '+faststart',
          outputPath,
        ],
        outputPath: outputPath,
        progressLength: length,
        onProgress: onProgress == null
            ? null
            : (value) => onProgress((value * 100).round().clamp(0, 100)),
      );
      if (copied) return outputPath;

      final encoded = await _encodeWithFallback(
        arguments: (encoder) => [
          '-y',
          '-f',
          'concat',
          '-safe',
          '0',
          '-i',
          listFile.path,
          '-vf',
          _evenScale,
          '-c:v',
          encoder,
          '-b:v',
          '8M',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-movflags',
          '+faststart',
          if (encoder != 'h264_mediacodec') ...['-pix_fmt', 'yuv420p'],
          outputPath,
        ],
        outputPath: outputPath,
        progressLength: length,
        onProgress: onProgress == null
            ? null
            : (value) => onProgress((value * 100).round().clamp(0, 100)),
      );
      return encoded ? outputPath : null;
    } catch (_) {
      await _delete(File(outputPath));
      return null;
    } finally {
      await _delete(listFile);
    }
  }

  /// Horizontal mirror. [onProgress] is 0–100.
  static Future<String?> horizontalFlip({
    required String inputPath,
    required String outputPath,
    void Function(int progress)? onProgress,
  }) async {
    final length = Duration(milliseconds: await durationMilliseconds(inputPath));
    final ok = await _encodeWithFallback(
      arguments: (encoder) => _videoEncodeArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        encoder: encoder,
        videoFilter: 'hflip,$_evenScale',
      ),
      outputPath: outputPath,
      progressLength: length,
      onProgress: onProgress == null
          ? null
          : (value) => onProgress((value * 100).round().clamp(0, 100)),
    );
    return ok ? outputPath : null;
  }

  /// Writes the audio track to [outputPath] as AAC.
  static Future<String?> extractAudio({
    required String inputPath,
    required String outputPath,
  }) async {
    final ok = await _run(
      arguments: [
        '-y',
        '-i',
        inputPath,
        '-vn',
        '-c:a',
        'aac',
        '-b:a',
        '128k',
        outputPath,
      ],
      outputPath: outputPath,
      minBytes: 32,
    );
    return ok ? outputPath : null;
  }

  /// Replaces the video audio with [audioPath]. Audio loops to the video end.
  static Future<String?> muxAudio({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    bool loopAudio = true,
  }) async {
    final copyArgs = <String>['-y', '-i', videoPath];
    if (loopAudio) {
      copyArgs
        ..add('-stream_loop')
        ..add('-1');
    }
    copyArgs.addAll([
      '-i',
      audioPath,
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-shortest',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-movflags',
      '+faststart',
      outputPath,
    ]);
    if (await _run(arguments: copyArgs, outputPath: outputPath)) {
      return outputPath;
    }

    final length = Duration(milliseconds: await durationMilliseconds(videoPath));
    final encoded = await _encodeWithFallback(
      arguments: (encoder) {
        final args = <String>['-y', '-i', videoPath];
        if (loopAudio) {
          args
            ..add('-stream_loop')
            ..add('-1');
        }
        args.addAll([
          '-i',
          audioPath,
          '-map',
          '0:v:0',
          '-map',
          '1:a:0',
          '-shortest',
          '-vf',
          _evenScale,
          '-c:v',
          encoder,
          '-b:v',
          '8M',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          '-movflags',
          '+faststart',
        ]);
        if (encoder != 'h264_mediacodec') {
          args
            ..add('-pix_fmt')
            ..add('yuv420p');
        }
        args.add(outputPath);
        return args;
      },
      outputPath: outputPath,
      progressLength: length,
    );
    return encoded ? outputPath : null;
  }

  /// Encodes [start] through [end] into [outputPath].
  static Future<String?> encodeRange({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
    bool enableAudio = true,
  }) async {
    if (end <= start) return null;
    final length = end - start;
    final ok = await _encodeWithFallback(
      arguments: (encoder) => _videoEncodeArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        encoder: encoder,
        videoFilter: _evenScale,
        start: start,
        length: length,
        enableAudio: enableAudio,
      ),
      outputPath: outputPath,
      progressLength: length,
    );
    return ok ? outputPath : null;
  }

  static List<String> _videoEncodeArgs({
    required String inputPath,
    required String outputPath,
    required String encoder,
    required String videoFilter,
    Duration start = Duration.zero,
    Duration? length,
    bool enableAudio = true,
    String bitrate = '8M',
  }) {
    final args = <String>['-y', '-i', inputPath];
    if (start > Duration.zero) {
      args
        ..add('-ss')
        ..add(_seconds(start));
    }
    if (length != null) {
      args
        ..add('-t')
        ..add(_seconds(length));
    }
    args
      ..add('-map')
      ..add('0:v:0')
      ..add('-vf')
      ..add(videoFilter)
      ..add('-c:v')
      ..add(encoder)
      ..add('-b:v')
      ..add(bitrate);
    if (enableAudio) {
      args
        ..add('-map')
        ..add('0:a:0?')
        ..add('-c:a')
        ..add('aac')
        ..add('-b:a')
        ..add('128k');
    } else {
      args.add('-an');
    }
    args
      ..add('-movflags')
      ..add('+faststart');
    if (encoder != 'h264_mediacodec') {
      args
        ..add('-pix_fmt')
        ..add('yuv420p');
    }
    args.add(outputPath);
    return args;
  }

  static Future<bool> _encodeWithFallback({
    required List<String> Function(String encoder) arguments,
    required String outputPath,
    Duration progressLength = Duration.zero,
    void Function(double progress)? onProgress,
  }) async {
    final primary = _hardwareEncoder();
    final first = await _run(
      arguments: arguments(primary),
      outputPath: outputPath,
      progressLength: progressLength,
      onProgress: onProgress,
    );
    if (first || primary == 'mpeg4') return first;
    onProgress?.call(0);
    return _run(
      arguments: arguments('mpeg4'),
      outputPath: outputPath,
      progressLength: progressLength,
      onProgress: onProgress,
    );
  }

  static String _hardwareEncoder() {
    if (Platform.isIOS) return 'h264_videotoolbox';
    if (Platform.isAndroid) return 'h264_mediacodec';
    return 'mpeg4';
  }

  static Future<bool> _run({
    required List<String> arguments,
    required String outputPath,
    Duration progressLength = Duration.zero,
    void Function(double progress)? onProgress,
    int minBytes = 64,
  }) async {
    final completer = Completer<bool>();
    try {
      await FFmpegKit.executeWithArgumentsAsync(
        arguments,
        (session) async {
          if (completer.isCompleted) return;
          final code = await session.getReturnCode();
          final file = File(outputPath);
          final ok = ReturnCode.isSuccess(code) &&
              await file.exists() &&
              await file.length() > minBytes;
          if (!ok) await _delete(file);
          completer.complete(ok);
        },
        null,
        onProgress == null
            ? null
            : (Statistics stats) {
                final total = progressLength.inMilliseconds;
                if (total <= 0) return;
                onProgress((stats.getTime() / total).clamp(0.0, 1.0));
              },
      );
    } catch (_) {
      await _delete(File(outputPath));
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  static void _addStillCodec(List<String> args, String outputPath, int quality) {
    final extension = path.extension(outputPath).toLowerCase();
    final clamped = quality.clamp(1, 100);
    if (extension == '.png') {
      args
        ..add('-c:v')
        ..add('png');
      return;
    }
    if (extension == '.webp') {
      args
        ..add('-c:v')
        ..add('libwebp')
        ..add('-quality')
        ..add('$clamped');
      return;
    }
    final qscale = (31 - (clamped / 100 * 29)).round().clamp(2, 31);
    args
      ..add('-q:v')
      ..add('$qscale');
  }

  static String? _thumbnailScale(int maxWidth, int maxHeight) {
    if (maxWidth <= 0 && maxHeight <= 0) return null;
    final width = maxWidth > 0 ? '$maxWidth' : '-2';
    final height = maxHeight > 0 ? '$maxHeight' : '-2';
    return 'scale=$width:$height:force_original_aspect_ratio=decrease';
  }

  static String? _headerBlock(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return null;
    final lines = headers.entries.map((entry) => '${entry.key}: ${entry.value}');
    return '${lines.join('\r\n')}\r\n';
  }

  static bool _isRemote(String video) =>
      video.startsWith('http://') || video.startsWith('https://');

  static String _concatLine(String filePath) {
    final escaped = filePath.replaceAll("'", r"'\''");
    return "file '$escaped'";
  }

  static int _rotationDegrees(StreamInformation stream) {
    final tags = stream.getTags();
    final tagged = int.tryParse('${tags?['rotate'] ?? ''}');
    final degrees = tagged ?? _sideDataRotation(stream);
    return ((degrees % 360) + 360) % 360;
  }

  static int _sideDataRotation(StreamInformation stream) {
    final sideData = stream.getProperty('side_data_list');
    if (sideData is! List) return 0;
    for (final item in sideData) {
      if (item is! Map) continue;
      final parsed = int.tryParse('${item['rotation']}');
      if (parsed != null && parsed != 0) return parsed;
    }
    return 0;
  }

  static String _seconds(Duration duration) =>
      (duration.inMilliseconds / 1000).toStringAsFixed(3);

  static Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
