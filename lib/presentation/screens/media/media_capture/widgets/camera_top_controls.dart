import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraTopControls extends StatelessWidget {
  const CameraTopControls({
    super.key,
    required this.cameraBloc,
  });

  final CameraBloc cameraBloc;

  @override
  Widget build(BuildContext context) => Positioned(
        top: 30.responsiveDimension,
        left: 0,
        right: 0,
        child: Padding(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TapHandler(
                onTap: () {
                  //stop recording
                  if (cameraBloc.isRecording || cameraBloc.isSegmentRecording) {
                    cameraBloc.add(CameraStopSegmentRecordingEvent());
                  }
                  //show confirmation dialog
                  Utility.showAppDialog(
                    isTwoButtons: true,
                    message: 'Are you sure you want to exit?',
                    positiveButtonText: 'Retake',
                    negativeButtonText: 'Yes',
                    onPressPositiveButton: () {
                      cameraBloc.add(CameraDiscardRecordingEvent());
                    },
                    onPressNegativeButton: () {
                      Navigator.pop(context);
                    },
                  );
                },
                child: Container(
                  padding: IsrDimens.edgeInsetsAll(7.responsiveDimension),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.25)),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.responsiveDimension,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
