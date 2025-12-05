import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';

class CameraRecordingProgressBar extends StatelessWidget {
  const CameraRecordingProgressBar({
    super.key,
    required this.cameraBloc,
    required this.state,
  });

  final CameraBloc cameraBloc;
  final CameraState state;

  @override
  Widget build(BuildContext context) {
    var recordingDuration = 0;
    var maxDuration = cameraBloc.selectedDuration;
    var segments = <VideoSegment>[];

    if (state is CameraRecordingState) {
      recordingDuration = (state as CameraRecordingState).recordingDuration;
      maxDuration = (state as CameraRecordingState).maxDuration;
    } else if (state is CameraSegmentRecordingState) {
      recordingDuration =
          (state as CameraSegmentRecordingState).recordingDuration;
      maxDuration = (state as CameraSegmentRecordingState).maxDuration;
      segments = (state as CameraSegmentRecordingState).segments;
    } else {
      recordingDuration = cameraBloc.totalRecordingDuration;
      segments = cameraBloc.videoSegments;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final progressValue = maxDuration > 0
        ? (recordingDuration / maxDuration).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        SizedBox(
          height: IsrDimens.four,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: IsrDimens.four,
                color: Colors.black.withValues(alpha: 0.25),
              ),
              FractionallySizedBox(
                widthFactor: progressValue,
                child: Container(
                  height: IsrDimens.four,
                  color: IsrColors.white,
                ),
              ),
              if (segments.isNotEmpty)
                ...segments.asMap().entries.map((entry) {
                  final segmentIndex = entry.key;
                  final previousSegmentsDuration = segments
                      .sublist(0, segmentIndex)
                      .fold<int>(0, (sum, seg) => sum + seg.duration);
                  final segmentPosition = maxDuration > 0
                      ? previousSegmentsDuration / maxDuration
                      : 0.0;
                  return Positioned(
                    left: segmentPosition * screenWidth,
                    child: Container(
                      width: IsrDimens.two,
                      height: IsrDimens.four,
                      color: IsrColors.black,
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
