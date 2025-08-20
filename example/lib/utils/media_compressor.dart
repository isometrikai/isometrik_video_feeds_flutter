import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class MediaCompressor {
  /// Compresses an image or video based on the [isVideo] flag.
  /// Returns a new [File] or null if compression fails.
  static Future<File?> compressMedia(
    File file, {
    required bool isVideo,
    Function(double)? onProgress,
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
      final targetPath = path.join(dir.path, 'img_${DateTime.now().millisecondsSinceEpoch}.jpg');

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

  /// Compresses video using `video_compress`
  static Future<File?> _compressVideo(File file, Function(double)? onProgress) async {
    try {
      final subscription = VideoCompress.compressProgress$.subscribe((progress) {
        debugPrint('Video compression progress: $progress');
        if (onProgress != null) onProgress(progress);
      });

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality, // Options: Low, Medium, High
        deleteOrigin: false,
      );
      subscription.unsubscribe();
      return info?.file;
    } catch (e) {
      debugPrint('Video compression failed: $e');
      return null;
    }
  }

  /// Dispose video compressor resources after you're done (recommended)
  static void dispose() {
    VideoCompress.dispose();
  }
}
