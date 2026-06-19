import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/domain/models/post_config.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/premium_glass_reflection_border.dart';
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
    final sigma = glass.blurSigma.clamp(12.0, 20.0);
    const borderWidth = 0.9;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: const SizedBox.expand(),
            ),
            const PremiumGlassFillLayers(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            CustomPaint(
              painter: PremiumGlassReflectionBorderPainter(
                shape: PremiumGlassBorderShape.circle,
                borderWidth: borderWidth,
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
