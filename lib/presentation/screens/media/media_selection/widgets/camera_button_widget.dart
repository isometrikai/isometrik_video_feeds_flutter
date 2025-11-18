import 'package:flutter/material.dart';
import '../media_selection.dart';

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
          color: Colors.grey[100],
          child: Center(
            child: mediaSelectionConfig.cameraIcon,
          ),
        ),
      );
}
