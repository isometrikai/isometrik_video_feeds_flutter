import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class VideoMergerUtil {
  static const MethodChannel _channel =
      MethodChannel('flutter_ecommerce/video_merger');

  /// Merges multiple video segments into a single video file
  /// Returns the path to the merged video file
  static Future<String?> mergeVideoSegments(List<String> videoPaths) async {
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

      final result = await _channel.invokeMethod<String>(
        'mergeVideos',
        {
          'videoPaths': videoPaths,
          'outputPath': outputPath,
        },
      );

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
}
