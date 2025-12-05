import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraSegmentDeleteButton extends StatelessWidget {
  const CameraSegmentDeleteButton({
    super.key,
    required this.cameraBloc,
  });

  final CameraBloc cameraBloc;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (cameraBloc.videoSegments.isNotEmpty) {
              _showRemoveSegmentBottomSheet(context);
            }
          },
          borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: IsrDimens.twentyFour,
            ),
          ),
        ),
      );

  Future<void> _showRemoveSegmentBottomSheet(BuildContext context) async {
    await Utility.showBottomSheet(
      child: Container(
        decoration: BoxDecoration(
          color: IsrColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(IsrDimens.sixteen),
            topRight: Radius.circular(IsrDimens.sixteen),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            IsrDimens.boxHeight(IsrDimens.twelve),
            IsrDimens.boxHeight(IsrDimens.sixteen),
            Padding(
              padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remove Previous Segment?',
                    style: IsrStyles.primaryText18.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TapHandler(
                    onTap: () => context.pop(),
                    child: AppImage.svg(
                      AssetConstants.icClose,
                      width: IsrDimens.twentyFour,
                      height: IsrDimens.twentyFour,
                      color: IsrColors.black,
                    ),
                  ),
                ],
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.sixteen),
            Padding(
              padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
              child: Text(
                'Do you want to remove the previous segment?',
                style: IsrStyles.primaryText14,
                textAlign: TextAlign.center,
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            Padding(
              padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      title: 'Cancel',
                      onPress: () => context.pop(),
                      color: IsrColors.white,
                      borderColor: '#CBCBCB'.color,
                      borderWidth: 1.2,
                      textColor: IsrColors.color9797BE,
                    ),
                  ),
                  IsrDimens.boxWidth(IsrDimens.sixteen),
                  Expanded(
                    child: CustomButton(
                      title: 'Remove',
                      onPress: () {
                        context.pop();
                        cameraBloc.add(CameraRemoveLastSegmentEvent());
                      },
                    ),
                  ),
                ],
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.sixteen),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
