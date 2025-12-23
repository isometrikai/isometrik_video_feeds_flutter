import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraSegmentDoneButton extends StatelessWidget {
  const CameraSegmentDoneButton({
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
              cameraBloc.add(CameraConfirmRecordingEvent());
            }
          },
          borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done,
              color: Colors.white,
              size: IsrDimens.twentyFour,
            ),
          ),
        ),
      );
}
