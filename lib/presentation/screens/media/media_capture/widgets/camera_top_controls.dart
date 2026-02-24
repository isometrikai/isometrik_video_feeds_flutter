import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraTopControls extends StatelessWidget {
  const CameraTopControls({
    super.key,
    required this.cameraBloc,
    required this.soundDubbingEnabled,
    required this.soundDataNotifier,
  });

  final CameraBloc cameraBloc;
  final bool soundDubbingEnabled;
  final ValueNotifier<SoundData?> soundDataNotifier;

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
              if (soundDubbingEnabled)
                TapHandler(
                  onTap: () async {
                    soundDataNotifier.value =
                        await SoundSelectorBottomSheet.show(context);
                  },
                  child: ValueListenableBuilder<SoundData?>(
                    valueListenable: soundDataNotifier,
                    builder: (context, value, child) => Container(
                        padding: IsrDimens.edgeInsetsAll(7.responsiveDimension),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      child: Stack(
                        children: [
                          if (value != null) _buildPreviewImage(value),
                          if (value == null)
                            Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 24.responsiveDimension,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildPreviewImage(SoundData sound) =>
      sound.previewUrl != null && sound.previewUrl!.isNotEmpty
          ? Image.network(
              sound.previewUrl!,
              fit: BoxFit.cover,
              width: IsrDimens.twentyFour,
              height: IsrDimens.twentyFour,
              loadingBuilder: (_, __, ___) => _placeholderThumbnail(),
              errorBuilder: (_, __, ___) => _placeholderThumbnail(),
            )
          : _placeholderThumbnail();

  Widget _placeholderThumbnail() => Container(
        width: IsrDimens.twentyFour,
        height: IsrDimens.twentyFour,
        color: IsrColors.appColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.music_note,
          color: IsrColors.appColor,
          size: IsrDimens.twentyFour,
        ),
      );
}
