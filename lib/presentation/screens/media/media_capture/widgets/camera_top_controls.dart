import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_screen.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraTopControls extends StatelessWidget {
  const CameraTopControls({
    super.key,
    required this.cameraBloc,
    this.onAddSoundTap,
    this.onDismissEntireFlow,
    this.dubSoundPickerTracks,
    this.dubWithAudioMode = false,
  });

  final CameraBloc cameraBloc;
  final void Function(BuildContext context)? onAddSoundTap;
  final VoidCallback? onDismissEntireFlow;
  final List<SoundTrack>? dubSoundPickerTracks;
  final bool dubWithAudioMode;

  bool get _showAddSound =>
      !dubWithAudioMode &&
      IsrVideoReelConfig.createEditPostConfig.enableAddSoundOnCamera &&
      cameraBloc.selectedMediaType == MediaType.video &&
      (cameraBloc.selectedDuration == 15 ||
          cameraBloc.selectedDuration == 60);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topInset + 6.responsiveDimension,
      left: 0,
      right: 0,
      child: Padding(
        padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
        child: SizedBox(
          height: 44.responsiveDimension,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TapHandler(
                  onTap: () {
                    //stop recording
                    if (cameraBloc.isRecording ||
                        cameraBloc.isSegmentRecording) {
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
                        if (onDismissEntireFlow != null) {
                          onDismissEntireFlow!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                  child: Container(
                    padding: IsrDimens.edgeInsetsAll(7.responsiveDimension),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.responsiveDimension,
                    ),
                  ),
                ),
              ),
              if (_showAddSound)
                TapHandler(
                  onTap: () async {
                    if (onAddSoundTap != null) {
                      onAddSoundTap!(context);
                      return;
                    }
                    cameraBloc.add(CameraFramingMusicRouteObscuredEvent(true));
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => SoundSelectionScreen(
                          cameraBloc: cameraBloc,
                          restrictedTracks: dubSoundPickerTracks,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      cameraBloc.add(CameraFramingMusicRouteObscuredEvent(false));
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 220.responsiveDimension,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.responsiveDimension,
                      vertical: 8.responsiveDimension,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius:
                          BorderRadius.circular(22.responsiveDimension),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 20.responsiveDimension,
                        ),
                        SizedBox(width: 6.responsiveDimension),
                        Text(
                          cameraBloc.hasMusicSelected
                              ? (cameraBloc.selectedMusicName ?? 'Sound')
                              : 'Add a sound',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.responsiveDimension,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
