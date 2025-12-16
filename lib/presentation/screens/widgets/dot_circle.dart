import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

class DotCircle extends StatelessWidget {
  DotCircle({
    this.size,
    this.color,
    this.padding,
  });

  final double? size;
  final double? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: IsrDimens.edgeInsetsAll(padding ?? IsrDimens.zero),
        decoration: BoxDecoration(
          color: IsrColors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context)
                  .primaryColor), // Change the color of the dot here
        ),
        child: Container(
          width: size ?? IsrDimens.ten, // Adjust the size of the dot as needed
          height: size ?? IsrDimens.ten,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ??
                Theme.of(context)
                    .primaryColor, // Change the color of the dot here
          ),
        ),
      );
}
