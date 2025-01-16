import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({
    super.key,
    this.thickness,
    this.height,
    this.indent,
    this.endIndent,
    this.color,
  });

  final double? thickness;
  final double? height;
  final double? indent;
  final double? endIndent;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        child: Divider(
          height: height ?? IsrDimens.five + (thickness ?? IsrDimens.one),
          color: color ?? Theme.of(context).dividerColor,
          thickness: thickness ?? IsrDimens.one,
          indent: endIndent ?? IsrDimens.zero,
          endIndent: endIndent ?? IsrDimens.zero,
        ),
      );
}
