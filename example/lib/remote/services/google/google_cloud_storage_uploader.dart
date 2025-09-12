import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class GoogleCloudStorageUploader {
  static Future<String?> uploadFile({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double)? onProgress,
    String? cloudFolderName,
  }) async {
    try {
      final finalFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final normalizedFolder = cloudFolderName.isEmptyOrNull == false
          ? cloudFolderName?.trim() ?? ''
          : '${AppConstants.tenantId}/${AppConstants.projectId}/user_$userId/posts/$finalFileName$fileExtension';

      final serviceJsonFile =
          await rootBundle.loadString(AssetConstants.googleServiceJson);
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceJsonFile);

      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        http.Client(),
      );

      final accessToken = accessCredentials.accessToken.data;
      final bytes = await file.readAsBytes();
      final contentType = _getContentType(fileName);
      final totalBytes = bytes.length;

      final uploadUrl =
          'https://storage.googleapis.com/upload/storage/v1/b/${AppConstants.bucketName}/o?uploadType=media&name=${Uri.encodeComponent(normalizedFolder)}';

      // Create a StreamedRequest for progress tracking
      final request = http.StreamedRequest('POST', Uri.parse(uploadUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Content-Type': contentType,
        'Content-Length': totalBytes.toString(),
      });

      // Track progress
      var bytesSent = 0;
      const chunkSize = 1024 * 8; // 8KB chunks

      // Add bytes to request in chunks while tracking progress
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);

        request.sink.add(chunk);
        bytesSent += chunk.length;

        // Calculate and report progress
        final progress = bytesSent / totalBytes;
        onProgress?.call(progress);

        // Small delay to prevent overwhelming the UI
        if (onProgress != null) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      await request.sink.close();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Ensure progress shows 100% completion
        onProgress?.call(1.0);

        await _makeObjectPublic(normalizedFolder, accessToken);
        // ✅ explicitly set metadata so it streams instead of downloads
        await _setObjectMetadata(normalizedFolder, accessToken, contentType);
        return 'https://storage.googleapis.com/${AppConstants.bucketName}/$normalizedFolder';
      } else {
        debugPrint('Upload failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Ensures correct Content-Type so the file streams in video_player
  static Future<void> _setObjectMetadata(
      String objectPath, String accessToken, String contentType) async {
    final url =
        'https://storage.googleapis.com/storage/v1/b/${AppConstants.bucketName}/o/${Uri.encodeComponent(objectPath)}';

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contentType': contentType,
        'contentDisposition': 'inline', // ✅ prevents forced download
      }),
    );

    if (response.statusCode != 200) {
      debugPrint(
          'Failed to set metadata: ${response.statusCode} ${response.body}');
    }
  }

  static Future<String?> uploadFileWithRealProgress({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double)? onProgress,
    String? cloudFolderName,
  }) async {
    try {
      final finalFileName = fileName;
      final normalizedFolder = cloudFolderName.isEmptyOrNull == false
          ? cloudFolderName?.trim() ?? ''
          : '${AppConstants.tenantId}/${AppConstants.projectId}/user_$userId/posts/$finalFileName$fileExtension';

      final serviceJsonFile =
          await rootBundle.loadString(AssetConstants.googleServiceJson);
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceJsonFile);

      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        http.Client(),
      );

      final accessToken = accessCredentials.accessToken.data;
      final bytes = await file.readAsBytes();
      final contentType = _getContentType(fileName);

      final uploadUrl =
          'https://storage.googleapis.com/upload/storage/v1/b/${AppConstants.bucketName}/o?uploadType=media&name=${Uri.encodeComponent(normalizedFolder)}';

      // Create Dio instance
      final dio = Dio();

      // Configure timeout
      dio.options.connectTimeout = const Duration(minutes: 5);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      dio.options.sendTimeout = const Duration(minutes: 5);

      final response = await dio.post(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': contentType,
          },
          validateStatus: (status) => status! < 500,
        ),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            // Calculate upload progress (0% to 90%)
            final uploadProgress = (sent / total) * 0.9;
            onProgress(uploadProgress);
            debugPrint(
                'Upload progress: ${(uploadProgress * 100).toInt()}% ($sent/$total bytes)');
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Set progress to 95% while making object public
        onProgress?.call(0.95);

        await _makeObjectPublic(normalizedFolder, accessToken);

        // Set progress to 100% when completely done
        onProgress?.call(1.0);

        return 'https://storage.googleapis.com/${AppConstants.bucketName}/$normalizedFolder';
      } else {
        debugPrint('Upload failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // First, let's make sure basic upload works without progress tracking
  static Future<String?> uploadFileBasic({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    String? cloudFolderName,
  }) async {
    try {
      final finalFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final normalizedFolder = cloudFolderName.isEmptyOrNull == false
          ? cloudFolderName?.trim() ?? ''
          : '${AppConstants.tenantId}/${AppConstants.projectId}/user_$userId/posts/$finalFileName$fileExtension';

      debugPrint('1. Starting upload process...');

      final serviceJsonFile =
          await rootBundle.loadString(AssetConstants.googleServiceJson);
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceJsonFile);

      debugPrint('2. Getting access credentials...');
      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        http.Client(),
      );

      final accessToken = accessCredentials.accessToken.data;
      debugPrint('3. Got access token: ${accessToken.substring(0, 20)}...');

      final bytes = await file.readAsBytes();
      final contentType = _getContentType(fileName);

      debugPrint(
          '4. File read: ${bytes.length} bytes, content type: $contentType');

      final uploadUrl =
          'https://storage.googleapis.com/upload/storage/v1/b/${AppConstants.bucketName}/o?uploadType=media&name=${Uri.encodeComponent(normalizedFolder)}';

      debugPrint('5. Upload URL: $uploadUrl');

      // Use simple HTTP POST
      final response = await http
          .post(
            Uri.parse(uploadUrl),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': contentType,
              'Content-Length': bytes.length.toString(),
            },
            body: bytes,
          )
          .timeout(const Duration(minutes: 5));

      debugPrint('6. Upload response status: ${response.statusCode}');
      debugPrint('7. Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('8. Upload successful, making object public...');
        await _makeObjectPublic(normalizedFolder, accessToken);

        final publicUrl =
            'https://storage.googleapis.com/${AppConstants.bucketName}/$normalizedFolder';
        debugPrint('9. Returning public URL: $publicUrl');
        return publicUrl;
      } else {
        debugPrint('Upload failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Upload error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<void> _makeObjectPublic(
      String objectName, String accessToken) async {
    try {
      final aclUrl =
          'https://storage.googleapis.com/storage/v1/b/${AppConstants.bucketName}/o/${Uri.encodeComponent(objectName)}/acl';

      await http.post(
        Uri.parse(aclUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'entity': 'allUsers',
          'role': 'READER',
        }),
      );
    } catch (e) {
      debugPrint('Failed to make object public: $e');
    }
  }

  static String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'm3u8':
        return 'application/vnd.apple.mpegurl'; // HLS

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';

      // Docs
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';

      default:
        return 'application/octet-stream'; // fallback
    }
  }

  // Alternative method using resumable upload for large files
  static Future<String?> uploadLargeFile(File file, String fileName,
      {Function(double)? onProgress}) async {
    try {
      final serviceJsonFile =
          await rootBundle.loadString(AssetConstants.googleServiceJson);

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceJsonFile);
      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        http.Client(),
      );

      final accessToken = accessCredentials.accessToken.data;
      final bytes = await file.readAsBytes();
      final contentType = _getContentType(fileName);
      final objectName =
          'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Step 1: Initiate resumable upload
      final initiateUrl =
          'https://storage.googleapis.com/upload/storage/v1/b/${AppConstants.bucketName}/o?uploadType=resumable';

      final initiateResponse = await http.post(
        Uri.parse(initiateUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'X-Upload-Content-Type': contentType,
          'X-Upload-Content-Length': bytes.length.toString(),
        },
        body: json.encode({
          'name': objectName,
          'metadata': {
            'contentType': contentType,
          },
        }),
      );

      if (initiateResponse.statusCode != 200) {
        debugPrint('Failed to initiate upload: ${initiateResponse.statusCode}');
        return null;
      }

      final uploadUrl = initiateResponse.headers['location'];
      if (uploadUrl == null) {
        debugPrint('No upload URL received');
        return null;
      }

      // Step 2: Upload the file data
      const chunkSize = 256 * 1024; // 256KB chunks
      var uploadedBytes = 0;

      while (uploadedBytes < bytes.length) {
        final end = (uploadedBytes + chunkSize < bytes.length)
            ? uploadedBytes + chunkSize
            : bytes.length;

        final chunk = bytes.sublist(uploadedBytes, end);

        final chunkResponse = await http.put(
          Uri.parse(uploadUrl),
          headers: {
            'Content-Length': chunk.length.toString(),
            'Content-Range': 'bytes $uploadedBytes-${end - 1}/${bytes.length}',
          },
          body: chunk,
        );

        if (chunkResponse.statusCode == 308) {
          // Continue uploading
          uploadedBytes = end;
          onProgress?.call(uploadedBytes / bytes.length);
        } else if (chunkResponse.statusCode == 200 ||
            chunkResponse.statusCode == 201) {
          // Upload complete
          onProgress?.call(1.0);
          await _makeObjectPublic(objectName, accessToken);
          return 'https://storage.googleapis.com/${AppConstants.bucketName}/$objectName';
        } else {
          debugPrint('Upload failed with status: ${chunkResponse.statusCode}');
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Large file upload error: $e');
      return null;
    }
  }
}
