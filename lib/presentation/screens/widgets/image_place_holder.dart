import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';

class ImagePlaceHolder extends StatelessWidget {
  const ImagePlaceHolder({
    super.key,
    this.padding,
    this.borderColor,
    this.boxShape = BoxShape.rectangle,
    this.boxFit,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.placeHolderName,
    this.child,
    this.height,
    this.width,
  });

  final double? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final BoxShape? boxShape;
  final BoxFit? boxFit;
  final BorderRadius? borderRadius;
  final LinearGradient? gradient;
  final String? placeHolderName;
  final Widget? child;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: IsrDimens.edgeInsetsAll(padding ?? IsrDimens.zero),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          border: Border.all(color: borderColor ?? Colors.white),
          shape: boxShape ?? BoxShape.rectangle,
          borderRadius: boxShape == BoxShape.rectangle ? borderRadius : null,
          gradient: gradient,
        ),
        child: child ??
            AppImage.svg(
              placeHolderName ?? AssetConstants.icAppImagePlaceHolder,
              fit: boxFit ?? BoxFit.contain,
            ),
      );
}
