import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/post_config.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/premium_glass_reflection_border.dart';

/// Premium Instagram/TikTok-style glass pill for reels mention & location tags.
///
/// Width is driven by [child] + [padding] — never stretches to parent width.
class GlassPillContainer extends StatelessWidget {
  const GlassPillContainer({
    required this.child,
    this.glassConfig,
    this.height = 32,
    this.padding = const EdgeInsets.fromLTRB(9, 2, 12, 2),
    this.blurSigma = 16,
    super.key,
  });

  final Widget child;
  final ActionIconGlassConfig? glassConfig;
  final double height;
  final EdgeInsetsGeometry padding;

  /// Backdrop blur strength (12–20px ≈ sigma 14–18).
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final glass = glassConfig ?? const ActionIconGlassConfig();
    final cornerRadius = (height / 2) - 1.5;
    final sigma =
        glass.blurSigma > 0 ? glass.blurSigma.clamp(12.0, 20.0) : blurSigma;
    const borderWidth = 0.9;
    final resolvedPadding = padding.resolve(Directionality.of(context));

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned.fill(
            child: PremiumGlassFillLayers(
              borderRadius: BorderRadius.circular(cornerRadius),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: PremiumGlassReflectionBorderPainter(
                shape: PremiumGlassBorderShape.pill,
                borderWidth: borderWidth,
                cornerRadius: cornerRadius,
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: SizedBox(
              height: height - resolvedPadding.vertical,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
