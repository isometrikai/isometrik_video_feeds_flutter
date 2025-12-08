import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class CameraButtonWidget extends StatelessWidget {
  const CameraButtonWidget({
    super.key,
    required this.onTap,
    required this.mediaSelectionConfig,
  });

  final VoidCallback onTap;
  final MediaSelectionConfig mediaSelectionConfig;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          color: '#5D5D5D'.color,
          child: Center(
            child: mediaSelectionConfig.cameraIcon,
          ),
        ),
      );
}
