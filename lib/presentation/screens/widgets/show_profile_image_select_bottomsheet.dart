import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';

class ShowProfileImageSelectBottomSheet extends StatelessWidget {
  const ShowProfileImageSelectBottomSheet({
    super.key,
    required this.collectionBloc,
  });

  final CollectionBloc collectionBloc;

  @override
  Widget build(BuildContext context) {
    final textColor = CollectionThemeResolver.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 6, 36, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IsrDimens.boxHeight(IsrDimens.twentyFour),
          TapHandler(
            onTap: () {
              collectionBloc.add(
                CollectionImageUploadEvent(
                  imageSource: ImageSource.camera,
                ),
              );

              context.pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  IsrTranslationFile.takePhoto,
                  style: IsrStyles.secondaryText16.copyWith(color: textColor),
                ),
              ],
            ),
          ),
          IsrDimens.boxHeight(IsrDimens.thirtyTwo),
          TapHandler(
            onTap: () {
              collectionBloc.add(
                CollectionImageUploadEvent(
                  imageSource: ImageSource.gallery,
                ),
              );
              context.pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  IsrTranslationFile.chooseFromGallery,
                  style: IsrStyles.secondaryText16.copyWith(color: textColor),
                ),
              ],
            ),
          ),
          IsrDimens.boxHeight(IsrDimens.eighty),
        ],
      ),
    );
  }
}
