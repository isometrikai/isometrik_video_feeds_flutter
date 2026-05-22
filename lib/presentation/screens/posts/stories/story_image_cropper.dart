import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Crops a picked image to story dimensions (9:16) before compose/upload.
class StoryImageCropper {
  const StoryImageCropper._();

  static const CropAspectRatio aspectRatio =
      CropAspectRatio(ratioX: 9, ratioY: 16);

  static Future<File?> crop(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: aspectRatio,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop story',
          toolbarColor: IsrColors.white,
          toolbarWidgetColor: IsrColors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          cropStyle: CropStyle.rectangle,
          aspectRatioPresets: const [CropAspectRatioPreset.original],
        ),
        IOSUiSettings(
          title: 'Crop story',
          cropStyle: CropStyle.rectangle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPresets: const [CropAspectRatioPreset.original],
        ),
      ],
    );
    if (cropped == null || cropped.path.isEmpty) return null;
    return File(cropped.path);
  }
}
