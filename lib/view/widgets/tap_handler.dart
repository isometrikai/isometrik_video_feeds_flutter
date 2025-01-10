import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';

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
          borderRadius: Dimens.borderRadiusAll(borderRadius ?? Dimens.zero),
          splashColor: Theme.of(context).splashColor,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Padding(
            padding: Dimens.edgeInsetsAll(padding ?? Dimens.zero),
            child: child,
          ),
          onLongPress: onLongPress,
        ),
      );
}
