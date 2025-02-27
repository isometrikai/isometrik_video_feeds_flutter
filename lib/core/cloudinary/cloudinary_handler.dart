import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class CloudinaryHandler {
  static Cloudinary? getCloudinary({
    required String apiKey,
    required String apiSecret,
    required String cloudName,
  }) {
    try {
      return Cloudinary.signedConfig(
        apiKey: apiKey,
        apiSecret: apiSecret,
        cloudName: cloudName,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<CloudinaryResponse?> uploadMedia({
    required Cloudinary cloudinary,
    required File file,
    required String fileName,
    required String cloudinaryCustomFolder,
    required CloudinaryResourceType resourceType,
    required Function(int, int) progressCallback,
  }) async {
    final response = await cloudinary.upload(
        file: file.path,
        fileBytes: file.readAsBytesSync(),
        resourceType: resourceType,
        folder: cloudinaryCustomFolder,
        fileName: fileName,
        progressCallback: (count, total) {
          progressCallback(count, total);
        });

    if (response.isSuccessful) {
      AppLog('Get your image from with ${response.secureUrl}');
      return response;
    } else {
      return null;
    }
  }

  static Future<bool> deleteMedia({
    required Cloudinary cloudinary,
    required String cloudinaryPublicId,
    required String mediaUrl,
    required CloudinaryResourceType resourceType,
  }) async {
    final response = await cloudinary.destroy(
      cloudinaryPublicId,
      url: mediaUrl,
      resourceType: resourceType,
    );
    if (response.isSuccessful) {
      AppLog('Media deleted successfully');
    }
    return response.isSuccessful;
  }
}
