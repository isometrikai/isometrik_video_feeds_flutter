import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:uuid/uuid.dart';

enum ReelDownloadOutcome {
  saved,
  failed,
  permissionDenied,
}

/// Saves reel / post media to the device photo library.
class ReelDownloadUtil {
  ReelDownloadUtil._();

  static const int _maxVideoDownloadBytes = 150 * 1024 * 1024;

  /// Host [PostConfig.canDownload] plus API `settings.download_enabled`
  /// (defaults to `true` when omitted).
  static bool isPostDownloadAllowed({
    required PostConfig postConfig,
    required TimeLineData post,
  }) {
    if (!postConfig.canDownload) return false;
    if (post.isLocked == true) return false;
    return post.settings?.downloadEnabled ?? true;
  }

  /// Downloads all media items for [post] into the gallery.
  static Future<ReelDownloadOutcome> downloadPostMedia(TimeLineData post) async {
    if (!await _ensureGalleryPermission()) {
      return ReelDownloadOutcome.permissionDenied;
    }

    final items = reelMediaMetaDataFromTimeline(post);
    if (items.isEmpty) return ReelDownloadOutcome.failed;

    var savedAny = false;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final url = item.mediaUrl.trim();
      if (url.isEmpty) continue;
      if (url.toLowerCase().contains('.m3u8')) continue;

      final isVideo = item.mediaType == 1;
      final saved = await _saveMediaItem(
        url: url,
        isVideo: isVideo,
        index: i,
        postId: post.id ?? 'post',
      );
      if (saved) savedAny = true;
    }
    return savedAny ? ReelDownloadOutcome.saved : ReelDownloadOutcome.failed;
  }

  static Future<bool> _ensureGalleryPermission() async {
    final ps = await pm.PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps == pm.PermissionState.limited) return true;

    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;
    }

    if (ps == pm.PermissionState.denied) {
      await pm.PhotoManager.openSetting();
    }
    return false;
  }

  static Future<bool> _saveMediaItem({
    required String url,
    required bool isVideo,
    required int index,
    required String postId,
  }) async {
    try {
      if (url.startsWith('file://') || (url.startsWith('/') && !url.startsWith('//'))) {
        final filePath = url.startsWith('file://')
            ? Uri.parse(url).toFilePath()
            : url;
        final file = File(filePath);
        if (!await file.exists()) return false;
        return isVideo
            ? _saveVideoFile(file, title: '${postId}_$index.mp4')
            : _saveImageBytes(await file.readAsBytes(), title: '${postId}_$index.jpg');
      }

      final uri = Uri.tryParse(url);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return false;
      }

      if (isVideo) {
        final file = await _downloadToTempFile(uri, extension: '.mp4');
        if (file == null) return false;
        try {
          return await _saveVideoFile(file, title: '${postId}_$index.mp4');
        } finally {
          await _deleteIfExists(file);
        }
      }

      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      return _saveImageBytes(response.bodyBytes, title: '${postId}_$index.jpg');
    } catch (e, st) {
      AppLog.error('ReelDownloadUtil: save failed $e\n$st');
      return false;
    }
  }

  static Future<File?> _downloadToTempFile(
    Uri uri, {
    required String extension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final out = File(
      path.join(tempDir.path, 'reel_dl_${const Uuid().v4()}$extension'),
    );
    final request = http.Request('GET', uri);
    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final sink = out.openWrite();
    var total = 0;
    try {
      await for (final chunk in response.stream) {
        total += chunk.length;
        if (total > _maxVideoDownloadBytes) {
          await sink.close();
          await _deleteIfExists(out);
          return null;
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }

    if (!await out.exists() || await out.length() < 64) {
      await _deleteIfExists(out);
      return null;
    }
    return out;
  }

  static Future<void> _deleteIfExists(File? f) async {
    if (f == null || !await f.exists()) return;
    try {
      await f.delete();
    } catch (_) {}
  }

  static Future<bool> _saveImageBytes(
    List<int> bytes, {
    required String title,
  }) async {
    if (bytes.isEmpty) return false;
    await pm.PhotoManager.editor.saveImage(
      Uint8List.fromList(bytes),
      title: title,
      filename: title,
    );
    return true;
  }

  static Future<bool> _saveVideoFile(
    File file, {
    required String title,
  }) async {
    if (!await file.exists()) return false;
    await pm.PhotoManager.editor.saveVideo(
      file,
      title: title,
    );
    return true;
  }
}
