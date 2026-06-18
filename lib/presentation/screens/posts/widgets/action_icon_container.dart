import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/domain/models/post_config.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/res/isr_dimens.dart';

const List<BoxShadow> kDefaultActionIconShadow = [
  BoxShadow(
    color: Color(0x40000000),
    blurRadius: 2,
    offset: Offset.zero,
  ),
];

/// Renders a configured reels action icon (SVG or PNG asset).
class ActionIconImage extends StatelessWidget {
  const ActionIconImage({
    required this.path,
    this.config,
    super.key,
  });

  final String path;
  final ActionIconConfig? config;

  bool get _isGlass =>
      config?.containerStyle == ActionIconContainerStyle.glass;

  bool get _useHostAppAssets => config?.useHostAppAssets ?? false;

  double get _size => config?.iconSize ?? IsrDimens.twentyFive;

  double get _scale =>
      _isGlass ? (config?.glassConfig?.iconScale ?? 1) : 1;

  @override
  Widget build(BuildContext context) {
    final isPng = path.toLowerCase().endsWith('.png');
    Widget image;
    if (isPng) {
      if (_useHostAppAssets) {
        image = Image(
          image: AssetImage(path, bundle: rootBundle),
          width: _size,
          height: _size,
          fit: BoxFit.contain,
        );
      } else {
        image = Image.asset(
          path,
          width: _size,
          height: _size,
          fit: BoxFit.contain,
        );
      }
    } else if (_useHostAppAssets) {
      image = SvgPicture.asset(
        path,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        bundle: rootBundle,
      );
    } else {
      image = AppImage.svg(
        path,
        width: _size,
        height: _size,
      );
    }

    if (_scale != 1) {
      image = Transform.scale(scale: _scale, child: image);
    }

    return image;
  }
}

/// Wraps a reels side-action icon with optional glassmorphism styling.
class ActionIconContainer extends StatelessWidget {
  const ActionIconContainer({
    required this.child,
    this.config,
    super.key,
  });

  final Widget child;
  final ActionIconConfig? config;

  bool get _isGlass =>
      config?.containerStyle == ActionIconContainerStyle.glass;

  @override
  Widget build(BuildContext context) {
    if (!_isGlass) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: config?.iconShadow ?? kDefaultActionIconShadow,
        ),
        child: child,
      );
    }

    final glass = config?.glassConfig ?? const ActionIconGlassConfig();
    final size = glass.containerSize;

    // No outer [boxShadow] — it paints outside the 40×40 bounds and bleeds onto
    // the count label stacked below in the reels action column.
    return SizedBox(
      width: size,
      height: size,
      child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glass.borderColor,
                glass.borderShadowColor,
              ],
            ),
          ),
          padding: EdgeInsets.all(glass.borderWidth),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: glass.blurSigma,
                    sigmaY: glass.blurSigma,
                  ),
                  child: const ColoredBox(color: Colors.transparent),
                ),
                // Light pooling from the north-west, darkening to the south-east.
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.6, -0.6),
                      radius: 1.5,
                      colors: [
                        glass.highlightColor,
                        glass.backgroundColor,
                        glass.shadowColor,
                      ],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                ),
                // Smooth top sheen across the upper third (no localized dot).
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        glass.innerHighlightColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Center(child: child),
              ],
            ),
          ),
      ),
    );
  }
}
