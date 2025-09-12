// Create a new file: lib/presentation/widgets/dialogs/upload_media_dialog.dart

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class UploadMediaResult {
  UploadMediaResult({
    required this.mediaType,
    required this.source,
  });

  final MediaType mediaType;
  final MediaSource source;
}

class UploadMediaDialog extends StatelessWidget {
  const UploadMediaDialog({
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
          padding: Dimens.edgeInsetsAll(Dimens.twentyFour),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TranslationFile.choosePhotoOrVideo,
                    style: Styles.primaryText16.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TapHandler(
                    onTap: () => Navigator.pop(context),
                    borderRadius: Dimens.twenty,
                    padding: Dimens.eight,
                    child: const AppImage.svg(AssetConstants.icCrossIcon),
                  ),
                ],
              ),
              Dimens.boxHeight(Dimens.sixteen),
              Text(
                TranslationFile.noNakedPicture,
                style: Styles.secondaryText14.copyWith(
                  color: AppColors.color909090,
                ),
              ),
              Dimens.boxHeight(Dimens.twentyFour),
              if (mediaType == MediaType.photo ||
                  mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icCameraIcon),
                  title: TranslationFile.takePhoto,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.photo,
                    MediaSource.camera,
                  ),
                ),
                Dimens.boxHeight(Dimens.sixteen),
              ],
              if (mediaType == MediaType.photo ||
                  mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icGalleryIcon),
                  title: TranslationFile.selectImageFromGallery,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.photo,
                    MediaSource.gallery,
                  ),
                ),
                Dimens.boxHeight(Dimens.sixteen),
              ],
              if (mediaType == MediaType.video ||
                  mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icCameraIcon),
                  title: TranslationFile.takeVideo,
                  onTap: () => _handleSelection(
                    context,
                    MediaType.video,
                    MediaSource.camera,
                  ),
                ),
                Dimens.boxHeight(Dimens.sixteen),
              ],
              if (mediaType == MediaType.video ||
                  mediaType == MediaType.both) ...[
                _buildOptionItem(
                  context: context,
                  icon: const AppImage.svg(AssetConstants.icGalleryIcon),
                  title: TranslationFile.selectVideoFromGallery,
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
        borderRadius: Dimens.eight,
        padding: Dimens.eight,
        child: Row(
          children: [
            SizedBox(
              width: Dimens.forty,
              height: Dimens.forty,
              child: icon,
            ),
            Dimens.boxWidth(Dimens.sixteen),
            Text(
              title,
              style: Styles.primaryText14,
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
