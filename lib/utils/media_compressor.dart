import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ism_video_reel_player/utils/ffmpeg_media_ops.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Callback for compression progress
typedef ProgressCallback = void Function(double progress);

class MediaCompressor {
  /// Compresses an image or video based on the [isVideo] flag.
  /// Returns a new [File] or null if compression fails.
  static Future<File?> compressMedia(
    File file, {
    required bool isVideo,
    ProgressCallback? onProgress,
  }) async {
    if (isVideo) {
      return await _compressVideo(file, onProgress);
    } else {
      return await _compressImage(file);
    }
  }

  /// Compresses image using
  static Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
          dir.path, 'img_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75, // Adjust for size vs quality (60–80 is good)
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return null;
    }
  }

  /// Compresses video with FFmpeg.
  static Future<File?> _compressVideo(
      File file, ProgressCallback? onProgress) async {
    try {
      final outputPath = await FfmpegMediaOps.compressVideo(
        inputPath: file.path,
        onProgress: (progress) {
          debugPrint('Video compression progress: $progress');
          onProgress?.call(progress);
        },
      );
      if (outputPath == null) return null;
      return File(outputPath);
    } catch (e) {
      debugPrint('Video compression failed: $e');
      return null;
    }
  }

  /// Kept so existing callers can release compressor state.
  static void dispose() {}
}
