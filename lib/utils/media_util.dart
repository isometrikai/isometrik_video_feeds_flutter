import 'dart:io';

import 'package:easy_video_editor/easy_video_editor.dart' as eve;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MediaUtil {
  /// Merges multiple video segments into a single video file
  /// Returns the path to the merged video file
  static Future<String?> mergeVideoSegments(List<String> videoPaths,
      {Function(int progress)? onProgress}) async {
    try {
      if (videoPaths.isEmpty) {
        return null;
      }

      if (videoPaths.length == 1) {
        return videoPaths.first;
      }

      for (var i = 0; i < videoPaths.length; i++) {
        final videoPath = videoPaths[i];
        final file = File(videoPath);
        if (!await file.exists()) {
          throw Exception('Video file not found: $videoPath');
        }
      }

      // Create output file path
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(tempDir.path, 'merged_video_$timestamp.mp4');
      final firstVideo = videoPaths.firstOrNull;
      final otherVideoPaths = videoPaths.toList();
      otherVideoPaths.removeAt(0);
      var progress = 0;
      final editor = eve.VideoEditorBuilder(videoPath: firstVideo!)
          .merge(otherVideoPaths: otherVideoPaths);

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
          return result;
        } else {
          AppLog.error('ERROR: Merged file does not exist at: $result');
        }
      } else {
        AppLog.error('ERROR: Native method returned null');
      }

      return null;
    } on PlatformException catch (e) {
      AppLog.error('PlatformException during merge: ${e.code} - ${e.message}');
      AppLog.error('Details: ${e.details}');
      throw Exception('Platform error merging videos: ${e.message}');
    } catch (e, stackTrace) {
      AppLog.error('Exception during merge: $e');
      AppLog.error('Stack trace: $stackTrace');
      throw Exception('Failed to merge videos: $e');
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
}
