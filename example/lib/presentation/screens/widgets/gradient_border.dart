import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class GradientInputBorder extends InputBorder {
  const GradientInputBorder({
    required this.gradient,
    this.width = 1.0,
    this.gapPadding = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  final double width;

  final BorderRadius borderRadius;

  final Gradient gradient;

  final double gapPadding;

  @override
  InputBorder copyWith({BorderSide? borderSide}) => this;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(borderSide.width),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final paint = _getPaint(rect);
    final outer = borderRadius.toRRect(rect);
    final center = outer.deflate(borderSide.width / 2.0);
    if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
      canvas.drawRRect(center, paint);
    } else {
      final extent =
          lerpDouble(0.0, gapExtent + gapPadding * 2.0, gapPercentage)!;
      switch (textDirection!) {
        case TextDirection.rtl:
          final path = _gapBorderPath(
            canvas,
            center,
            math.max(0, gapStart + gapPadding - extent),
            extent,
          );
          canvas.drawPath(path, paint);
          break;

        case TextDirection.ltr:
          final path = _gapBorderPath(
            canvas,
            center,
            math.max(0, gapStart - gapPadding),
            extent,
          );
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => GradientInputBorder(
        width: width * t,
        borderRadius: borderRadius * t,
        gradient: gradient,
      );

  Paint _getPaint(Rect rect) => Paint()
    ..strokeWidth = width
    ..shader = gradient.createShader(rect)
    ..style = PaintingStyle.stroke;

  Path _gapBorderPath(
    Canvas canvas,
    RRect center,
    double start,
    double extent,
  ) {
    // When the corner radii on any side add up to be greater than the
    // given height, each radius has to be scaled to not exceed the
    // size of the width/height of the RRect.
    final scaledRRect = center.scaleRadii();

    final tlCorner = Rect.fromLTWH(
      scaledRRect.left,
      scaledRRect.top,
      scaledRRect.tlRadiusX * 2.0,
      scaledRRect.tlRadiusY * 2.0,
    );
    final trCorner = Rect.fromLTWH(
      scaledRRect.right - scaledRRect.trRadiusX * 2.0,
      scaledRRect.top,
      scaledRRect.trRadiusX * 2.0,
      scaledRRect.trRadiusY * 2.0,
    );
    final brCorner = Rect.fromLTWH(
      scaledRRect.right - scaledRRect.brRadiusX * 2.0,
      scaledRRect.bottom - scaledRRect.brRadiusY * 2.0,
      scaledRRect.brRadiusX * 2.0,
      scaledRRect.brRadiusY * 2.0,
    );
    final blCorner = Rect.fromLTWH(
      scaledRRect.left,
      scaledRRect.bottom - scaledRRect.blRadiusY * 2.0,
      scaledRRect.blRadiusX * 2.0,
      scaledRRect.blRadiusX * 2.0,
    );

    const cornerArcSweep = math.pi / 2.0;
    final tlCornerArcSweep = start < scaledRRect.tlRadiusX
        ? math.asin((start / scaledRRect.tlRadiusX).clamp(-1.0, 1.0))
        : math.pi / 2.0;

    final path = Path()
      ..addArc(tlCorner, math.pi, tlCornerArcSweep)
      ..moveTo(scaledRRect.left + scaledRRect.tlRadiusX, scaledRRect.top);

    if (start > scaledRRect.tlRadiusX) {
      path.lineTo(scaledRRect.left + start, scaledRRect.top);
    }

    const trCornerArcStart = (3 * math.pi) / 2.0;
    const trCornerArcSweep = cornerArcSweep;
    if (start + extent < scaledRRect.width - scaledRRect.trRadiusX) {
      path
        ..relativeMoveTo(extent, 0)
        ..lineTo(scaledRRect.right - scaledRRect.trRadiusX, scaledRRect.top)
        ..addArc(trCorner, trCornerArcStart, trCornerArcSweep);
    } else if (start + extent < scaledRRect.width) {
      final dx = scaledRRect.width - (start + extent);
      final sweep = math.acos(dx / scaledRRect.trRadiusX);
      path.addArc(trCorner, trCornerArcStart + sweep, trCornerArcSweep - sweep);
    }

    return path
      ..moveTo(scaledRRect.right, scaledRRect.top + scaledRRect.trRadiusY)
      ..lineTo(scaledRRect.right, scaledRRect.bottom - scaledRRect.brRadiusY)
      ..addArc(brCorner, 0, cornerArcSweep)
      ..lineTo(scaledRRect.left + scaledRRect.blRadiusX, scaledRRect.bottom)
      ..addArc(blCorner, math.pi / 2.0, cornerArcSweep)
      ..lineTo(scaledRRect.left, scaledRRect.top + scaledRRect.tlRadiusY);
  }
}

class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
    this.borderRadius = BorderRadius.zero,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final BorderRadius borderRadius;
  final Gradient gradient;
  final BoxShape shape;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  BoxBorder scale(double t) => GradientBoxBorder(
        width: width * t,
        borderRadius: borderRadius * t,
        gradient: gradient,
      );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    if (shape == BoxShape.circle) {
      final radius = rect.width / 2.0;
      final center = rect.center;
      canvas.drawCircle(center, radius - width / 2.0, paint);
    } else {
      final rRect =
          borderRadius?.toRRect(rect) ?? this.borderRadius.toRRect(rect);
      final innerRect = rRect.deflate(width / 2.0);
      canvas.drawRRect(innerRect, paint);
    }
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    if (shape == BoxShape.circle) {
      final radius = rect.width / 2.0 - width / 2.0;
      return Path()
        ..addOval(Rect.fromCircle(center: rect.center, radius: radius));
    }
    return Path()
      ..addRRect(
        borderRadius.resolve(textDirection).toRRect(rect).deflate(width / 2.0),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (shape == BoxShape.circle) {
      final radius = rect.width / 2.0 + width / 2.0;
      return Path()
        ..addOval(Rect.fromCircle(center: rect.center, radius: radius));
    }
    return Path()
      ..addRRect(
        borderRadius.resolve(textDirection).toRRect(rect).inflate(width / 2.0),
      );
  }

  @override
  BorderSide get top => BorderSide(color: Colors.transparent, width: width);

  @override
  BorderSide get bottom => BorderSide(color: Colors.transparent, width: width);
}
