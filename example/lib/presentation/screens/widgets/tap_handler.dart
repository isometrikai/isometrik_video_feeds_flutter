import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

class TapHandler extends StatelessWidget {
  const TapHandler({
    super.key,
    this.onTap,
    this.behavior,
    this.onLongPress,
    this.onDoubleTap,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final HitTestBehavior? behavior;
  final Widget child;
  final double? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: IsrDimens.borderRadiusAll(borderRadius ?? IsrDimens.zero),
          splashColor: Theme.of(context).splashColor,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: IsrDimens.edgeInsetsAll(padding ?? IsrDimens.zero),
            child: child,
          ),
        ),
      );
}
