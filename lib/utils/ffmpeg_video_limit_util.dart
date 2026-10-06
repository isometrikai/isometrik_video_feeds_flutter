import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_video/statistics.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Trims with a stream copy, then hardware-encodes once if the result is
/// still over the post duration or size limit.
class FfmpegVideoLimitUtil {
  FfmpegVideoLimitUtil._();

  static const String _bitrate = '12M';
  static const double _durationSlackSeconds = 0.5;

  static int get _maxBytes =>
      IsrVideoReelConfig.createEditPostConfig.postVideoMaxSizeMb *
      1024 *
      1024;

  /// Duration in seconds, or null when the file cannot be probed.
  static Future<double?> probeDurationSeconds(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final raw = session.getMediaInformation()?.getDuration();
      if (raw == null || raw.isEmpty) return null;
      final seconds = double.tryParse(raw);
      if (seconds == null || seconds <= 0) return null;
      return seconds;
    } catch (_) {
      return null;
    }
  }

  /// Returns a path that is within [maxSeconds] and the configured size cap.
  ///
  /// [userTrimmed] is true when the user picked [start] and [length].
  /// Cancel returns null and deletes partial output.
  static Future<String?> ensureWithinLimits({
    required BuildContext context,
    required String inputPath,
    required Duration start,
    required Duration? length,
    required int maxSeconds,
    required String outputFilename,
    required bool userTrimmed,
  }) async {
    final input = File(inputPath);
    if (!await input.exists()) return null;
    final inputSize = await input.length();

    if (!userTrimmed) {
      if (inputSize <= _maxBytes) return inputPath;
      if (!context.mounted) return null;
      final probed = await probeDurationSeconds(inputPath);
      final encodeLength = probed == null
          ? Duration(seconds: maxSeconds)
          : Duration(milliseconds: (probed * 1000).round());
      return _encodeExactSpan(
        context: context,
        inputPath: inputPath,
        start: Duration.zero,
        length: encodeLength,
        outputFilename: outputFilename,
      );
    }

    final span = length ?? Duration(seconds: maxSeconds);
    final copyPath = await _tempPath(outputFilename, 'copy');
    final copied = await _streamCopy(
      inputPath: inputPath,
      start: start,
      length: span,
      outputPath: copyPath,
    );
    if (!copied) {
      await _deleteIfExists(File(copyPath));
      if (!context.mounted) return null;
      return _encodeExactSpan(
        context: context,
        inputPath: inputPath,
        start: start,
        length: span,
        outputFilename: outputFilename,
      );
    }

    final outDuration = await probeDurationSeconds(copyPath);
    final outSize = await File(copyPath).length();
    final durationOver =
        outDuration == null || outDuration > maxSeconds + _durationSlackSeconds;
    final sizeOver = outSize > _maxBytes;
    if (!durationOver && !sizeOver) return copyPath;

    await _deleteIfExists(File(copyPath));
    if (!context.mounted) return null;
    return _encodeExactSpan(
      context: context,
      inputPath: inputPath,
      start: start,
      length: span,
      outputFilename: outputFilename,
    );
  }

  static Future<String?> _encodeExactSpan({
    required BuildContext context,
    required String inputPath,
    required Duration start,
    required Duration length,
    required String outputFilename,
  }) async {
    if (!context.mounted) return null;
    final progress = ValueNotifier<double>(0);
    int? sessionId;
    var cancelled = false;
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EncodeProgressDialog(
        progress: progress,
        onCancel: () {
          cancelled = true;
          final id = sessionId;
          if (id != null) unawaited(FFmpegKit.cancel(id));
        },
      ),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(navigator.push(route));

    try {
      final primary = _hardwareEncoder();
      final primaryPath = await _tempPath(outputFilename, 'enc');
      final first = await _run(
        arguments: _encodeArguments(
          inputPath: inputPath,
          start: start,
          length: length,
          outputPath: primaryPath,
          encoder: primary,
        ),
        outputPath: primaryPath,
        length: length,
        progress: progress,
        onSession: (id) {
          sessionId = id;
          if (cancelled) unawaited(FFmpegKit.cancel(id));
        },
      );
      if (first == _FfmpegRun.success) return primaryPath;
      await _deleteIfExists(File(primaryPath));
      if (cancelled || first == _FfmpegRun.cancelled || primary == 'mpeg4') {
        return null;
      }

      progress.value = 0;
      final fallbackPath = await _tempPath(outputFilename, 'mpeg4');
      final second = await _run(
        arguments: _encodeArguments(
          inputPath: inputPath,
          start: start,
          length: length,
          outputPath: fallbackPath,
          encoder: 'mpeg4',
        ),
        outputPath: fallbackPath,
        length: length,
        progress: progress,
        onSession: (id) {
          sessionId = id;
          if (cancelled) unawaited(FFmpegKit.cancel(id));
        },
      );
      if (second == _FfmpegRun.success) return fallbackPath;
      await _deleteIfExists(File(fallbackPath));
      return null;
    } finally {
      if (route.navigator != null) {
        route.navigator!.removeRoute(route);
      }
      await Future<void>.delayed(Duration.zero);
      progress.dispose();
    }
  }

  static String _hardwareEncoder() {
    if (Platform.isIOS) return 'h264_videotoolbox';
    if (Platform.isAndroid) return 'h264_mediacodec';
    return 'mpeg4';
  }

  static List<String> _encodeArguments({
    required String inputPath,
    required Duration start,
    required Duration length,
    required String outputPath,
    required String encoder,
  }) {
    const scale =
        "scale='min(1080,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease,"
        'scale=trunc(iw/2)*2:trunc(ih/2)*2';
    final args = <String>[
      '-y',
      '-i',
      inputPath,
      '-ss',
      _seconds(start),
      '-t',
      _seconds(length),
      '-map',
      '0:v:0',
      '-map',
      '0:a:0?',
      '-vf',
      scale,
      '-c:v',
      encoder,
      '-b:v',
      _bitrate,
      '-c:a',
      'aac',
      '-b:a',
      '128k',
      '-movflags',
      '+faststart',
    ];
    if (encoder != 'h264_mediacodec') {
      args
        ..add('-pix_fmt')
        ..add('yuv420p');
    }
    args.add(outputPath);
    return args;
  }

  static Future<bool> _streamCopy({
    required String inputPath,
    required Duration start,
    required Duration length,
    required String outputPath,
  }) async {
    final result = await _run(
      arguments: [
        '-y',
        '-ss',
        _seconds(start),
        '-i',
        inputPath,
        '-t',
        _seconds(length),
        '-c',
        'copy',
        '-avoid_negative_ts',
        'make_zero',
        outputPath,
      ],
      outputPath: outputPath,
      length: length,
    );
    return result == _FfmpegRun.success;
  }

  static Future<_FfmpegRun> _run({
    required List<String> arguments,
    required String outputPath,
    required Duration length,
    ValueNotifier<double>? progress,
    void Function(int sessionId)? onSession,
  }) async {
    final completer = Completer<_FfmpegRun>();
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        arguments,
        (completed) async {
          if (completer.isCompleted) return;
          final code = await completed.getReturnCode();
          if (ReturnCode.isCancel(code)) {
            await _deleteIfExists(File(outputPath));
            completer.complete(_FfmpegRun.cancelled);
            return;
          }
          if (!ReturnCode.isSuccess(code)) {
            await _deleteIfExists(File(outputPath));
            completer.complete(_FfmpegRun.failed);
            return;
          }
          final file = File(outputPath);
          if (!await file.exists() || await file.length() <= 64) {
            await _deleteIfExists(file);
            completer.complete(_FfmpegRun.failed);
            return;
          }
          completer.complete(_FfmpegRun.success);
        },
        null,
        progress == null
            ? null
            : (Statistics stats) {
                final totalMs = length.inMilliseconds;
                if (totalMs <= 0) return;
                progress.value = (stats.getTime() / totalMs).clamp(0.0, 1.0);
              },
      );
      final id = session.getSessionId();
      if (id != null) onSession?.call(id);
    } catch (_) {
      await _deleteIfExists(File(outputPath));
      if (!completer.isCompleted) completer.complete(_FfmpegRun.failed);
    }
    return completer.future;
  }

  static String _seconds(Duration duration) =>
      (duration.inMilliseconds / 1000).toStringAsFixed(3);

  static Future<String> _tempPath(String filename, String suffix) async {
    final dir = await getTemporaryDirectory();
    final base = path.basenameWithoutExtension(filename);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return path.join(dir.path, '${base}_${suffix}_$stamp.mp4');
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

enum _FfmpegRun { success, cancelled, failed }

class _EncodeProgressDialog extends StatelessWidget {
  const _EncodeProgressDialog({
    required this.progress,
    required this.onCancel,
  });

  final ValueNotifier<double> progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Preparing video'),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: value <= 0 ? null : value,
                ),
                const SizedBox(height: 12),
                Text('${(value * 100).clamp(0, 100).round()}%'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
      );
}
