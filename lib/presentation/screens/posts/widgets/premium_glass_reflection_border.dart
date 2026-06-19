import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Outline shape for [PremiumGlassReflectionBorderPainter].
enum PremiumGlassBorderShape {
  pill,
  circle,
}

/// Two-reflection glass rim — shared by pills and circular action buttons.
class PremiumGlassReflectionBorderPainter extends CustomPainter {
  const PremiumGlassReflectionBorderPainter({
    required this.shape,
    required this.borderWidth,
    this.cornerRadius,
    this.borderVisibility = 0.76,
  });

  final PremiumGlassBorderShape shape;
  final double borderWidth;
  final double? cornerRadius;
  final double borderVisibility;

  static const int _steps = 240;

  static double _smoothFade(double t) {
    t = t.clamp(0.0, 1.0);
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  static double _reflectionFadeIn(double t) => _smoothFade(t);

  static double _reflectionFadeOut(double t) => 1 - _smoothFade(t);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = borderWidth;

    if (shape == PremiumGlassBorderShape.circle) {
      _paintCircle(canvas, size, stroke);
      return;
    }

    _paintPill(canvas, size, stroke);
  }

  void _paintPill(Canvas canvas, Size size, double stroke) {
    final w = size.width;
    final h = size.height;
    final capR = cornerRadius ?? h / 2;
    final r = capR - stroke / 2;
    final cy = h / 2;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, h - stroke),
          Radius.circular(r),
        ),
      );

    _drawGradientOpacityStroke(
      canvas,
      outline,
      stroke,
      (x, y) => _opacityAtPillPoint(x, y, w, h, capR, stroke),
    );

    _drawCornerGleam(
      canvas,
      Offset(capR - r * 0.72, cy - r * 0.72),
      stroke,
      intensity: 0.72,
    );
    _drawCornerGleam(
      canvas,
      Offset(w - capR + r * 0.72, cy + r * 0.72),
      stroke,
      intensity: 0.58,
    );
  }

  void _paintCircle(Canvas canvas, Size size, double stroke) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - stroke / 2;

    final outline = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    _drawGradientOpacityStroke(
      canvas,
      outline,
      stroke,
      (x, y) => _opacityAtCirclePoint(x, y, cx, cy, r),
    );

    _drawCornerGleam(
      canvas,
      Offset(cx - r * 0.72, cy - r * 0.72),
      stroke,
      intensity: 0.72,
    );
    _drawCornerGleam(
      canvas,
      Offset(cx + r * 0.72, cy + r * 0.72),
      stroke,
      intensity: 0.58,
    );
  }

  bool _onCapArc(double x, double y, double cx, double cy, double r) {
    final dx = x - cx;
    final dy = y - cy;
    return (math.sqrt(dx * dx + dy * dy) - r).abs() <= 3.5;
  }

  double _opacityAtPillPoint(
    double x,
    double y,
    double w,
    double h,
    double capR,
    double stroke,
  ) {
    final cy = h / 2;
    final cxL = capR;
    final cxR = w - capR;
    final r = capR - stroke / 2;
    final inset = stroke / 2;
    const band = 2.8;
    final featherPx = math.max(12.0, r * 0.72);

    if (y <= inset + band && x >= cxL - 1 && x <= cxR + 1) {
      var opacity = 0.82;
      final featherStart = cxR - featherPx;
      if (x > featherStart) {
        opacity *= _reflectionFadeOut((x - featherStart) / featherPx);
      }
      return opacity;
    }

    if (y >= h - inset - band && x >= cxL - 1 && x <= cxR + 1) {
      var opacity = 0.78;
      final featherEnd = cxL + featherPx;
      if (x < featherEnd) {
        opacity *= _reflectionFadeOut((featherEnd - x) / featherPx);
      }
      return opacity;
    }

    final arcT = (y - cy) / r;

    if (_onCapArc(x, y, cxL, cy, r) && x <= cxL + 2) {
      if (arcT <= 0.0) return 0.76;
      if (arcT <= 0.92) {
        return 0.76 * _reflectionFadeOut(arcT / 0.92);
      }
      return 0.0;
    }

    if (_onCapArc(x, y, cxR, cy, r) && x >= cxR - 2) {
      if (arcT < -0.48) return 0.0;
      if (arcT < 0.16) {
        return 0.76 * _reflectionFadeIn((arcT - (-0.48)) / (0.16 - (-0.48)));
      }
      return 0.76;
    }

    return 0.0;
  }

  double _opacityAtCirclePoint(
    double x,
    double y,
    double cx,
    double cy,
    double r,
  ) {
    final arcT = (y - cy) / r;
    final arcS = (x - cx) / r;

    // Upper arc — feather toward top-right hidden quadrant.
    if (arcT < -0.12) {
      var opacity = 0.82;
      if (arcS > -0.15) {
        opacity *= _reflectionFadeOut(((arcS + 0.15) / 0.95).clamp(0.0, 1.0));
      }
      return opacity;
    }

    // Lower arc — feather toward bottom-left hidden quadrant.
    if (arcT > 0.12) {
      var opacity = 0.78;
      if (arcS < 0.15) {
        opacity *= _reflectionFadeOut(((-arcS + 0.15) / 0.95).clamp(0.0, 1.0));
      }
      return opacity;
    }

    // Left side — dissolve downward past left-center.
    if (arcS <= -0.08) {
      if (arcT <= 0.0) return 0.76;
      if (arcT <= 0.92) {
        return 0.76 * _reflectionFadeOut(arcT / 0.92);
      }
      return 0.0;
    }

    // Right side — gradually appear from upper-right hidden zone.
    if (arcS >= 0.08) {
      if (arcT < -0.48) return 0.0;
      if (arcT < 0.16) {
        return 0.76 * _reflectionFadeIn((arcT - (-0.48)) / (0.16 - (-0.48)));
      }
      return 0.76;
    }

    return 0.0;
  }

  void _drawGradientOpacityStroke(
    Canvas canvas,
    Path path,
    double stroke,
    double Function(double x, double y) opacityAt,
  ) {
    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      if (length <= 0) continue;

      final step = length / _steps;
      for (var i = 0; i < _steps; i++) {
        final start = step * i;
        final end = step * (i + 1);
        final tangentStart = metric.getTangentForOffset(start);
        final tangentEnd = metric.getTangentForOffset(end);
        if (tangentStart == null || tangentEnd == null) continue;

        final alpha = (opacityAt(
                  tangentStart.position.dx,
                  tangentStart.position.dy,
                ) +
                opacityAt(
                  tangentEnd.position.dx,
                  tangentEnd.position.dy,
                )) /
            2 *
            borderVisibility;
        if (alpha < 0.006) continue;

        final segment = metric.extractPath(
          step * i,
          step * (i + 1),
          startWithMoveTo: true,
        );

        canvas.drawPath(
          segment,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: alpha),
        );
      }
    }
  }

  void _drawCornerGleam(
    Canvas canvas,
    Offset point,
    double stroke, {
    required double intensity,
  }) {
    canvas.drawCircle(
      point,
      stroke * 1.6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14 * borderVisibility * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      point,
      stroke * 0.55,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.38 * borderVisibility * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }

  @override
  bool shouldRepaint(covariant PremiumGlassReflectionBorderPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.borderVisibility != borderVisibility;
}

/// Shared frosted-glass fill layers (blur must wrap this stack externally).
class PremiumGlassFillLayers extends StatelessWidget {
  const PremiumGlassFillLayers({
    required this.borderRadius,
    super.key,
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.48, 1.0],
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, 0.55),
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: const Alignment(0, 0.65),
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.10),
                ],
              ),
            ),
          ),
        ],
      );
}
