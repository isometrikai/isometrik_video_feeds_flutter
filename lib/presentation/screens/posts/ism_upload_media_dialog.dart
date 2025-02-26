// Create a new file: lib/presentation/widgets/dialogs/ism_upload_media_dialog.dart

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';

class UploadMediaResult {
  UploadMediaResult({
    required this.mediaType,
    required this.source,
  });

  final MediaType mediaType;
  final MediaSource source;
}

class IsmUploadMediaDialog extends StatelessWidget {
  const IsmUploadMediaDialog({
    super.key,
    required this.onMediaSelected,
    this.mediaType = MediaType.both,
  });

  final MediaType mediaType;
  final Function(UploadMediaResult result) onMediaSelected;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    IsrTranslationFile.choosePhotoOrVideo,
                    style: IsrStyles.primaryText16.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TapHandler(
                    onTap: () => Navigator.pop(context),
                    borderRadius: IsrDimens.twenty,
                    padding: IsrDimens.eight,
                    child: const AppImage.svg(AssetConstants.icCrossIcon),
                  ),
                ],
              ),
              IsrDimens.boxHeight(IsrDimens.sixteen),
              Text(
                IsrTranslationFile.noNakedPicture,
                style: IsrStyles.secondaryText14.copyWith(
                  color: IsrColors.color909090,
                ),
              ),
              IsrDimens.boxHeight(IsrDimens.twentyFour),
              if (mediaType == MediaType.photo || mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icCameraIcon),
                  title: IsrTranslationFile.takePhoto,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.photo,
                    MediaSource.camera,
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.sixteen),
              ],
              if (mediaType == MediaType.photo || mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icGalleryIcon),
                  title: IsrTranslationFile.selectImageFromGallery,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.photo,
                    MediaSource.gallery,
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.sixteen),
              ],
              if (mediaType == MediaType.video || mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icCameraIcon),
                  title: IsrTranslationFile.takeVideo,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.video,
                    MediaSource.camera,
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.sixteen),
              ],
              if (mediaType == MediaType.video || mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icGalleryIcon),
                  title: IsrTranslationFile.selectVideoFromGallery,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.video,
                    MediaSource.gallery,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildOptionItem({
    required BuildContext context,
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) =>
      TapHandler(
        onTap: onTap,
        borderRadius: IsrDimens.eight,
        padding: IsrDimens.eight,
        child: Row(
          children: [
            SizedBox(
              width: IsrDimens.forty,
              height: IsrDimens.forty,
              child: icon,
            ),
            IsrDimens.boxWidth(IsrDimens.sixteen),
            Text(
              title,
              style: IsrStyles.primaryText14,
            ),
          ],
        ),
      );

  void _handleSelection(
    BuildContext context,
    MediaType mediaType,
    MediaSource source,
  ) {
    Navigator.pop(context);
    onMediaSelected(
      UploadMediaResult(
        mediaType: mediaType,
        source: source,
      ),
    );
  }
}
