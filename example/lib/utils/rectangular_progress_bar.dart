import 'package:flutter/material.dart';

class RectangularProgressBar extends CustomPainter {
  RectangularProgressBar({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
    this.borderRadius = 8.0,
  });
  final double progress; // from 0.0 to 1.0
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;
    final radius = borderRadius;

    // Calculate total perimeter for straight edges (no arc math)
    final total = (width + height) * 2;
    final currentLength = total * progress;

    final path = Path();

    // Define corner points
    final topRight = Offset(width - radius, 0);
    final start = Offset(radius, 0);

    var remaining = currentLength;

    path.moveTo(start.dx, start.dy);

    // Top edge
    final topEdgeLength = width - 2 * radius;
    if (remaining <= topEdgeLength) {
      path.lineTo(start.dx + remaining, start.dy);
      canvas.drawPath(path, paint);
      return;
    } else {
      path.lineTo(topRight.dx, topRight.dy);
      remaining -= topEdgeLength;
    }

    // Top-right arc + right edge
    final rightEdgeLength = height - 2 * radius;
    if (remaining <= radius) {
      path.arcToPoint(
        Offset(width, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      canvas.drawPath(path, paint);
      return;
    } else {
      path.arcToPoint(
        Offset(width, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      remaining -= radius;
    }

    if (remaining <= rightEdgeLength) {
      path.lineTo(width, radius + remaining);
      canvas.drawPath(path, paint);
      return;
    } else {
      path.lineTo(width, height - radius);
      remaining -= rightEdgeLength;
    }

    // Bottom-right arc + bottom edge
    if (remaining <= radius) {
      path.arcToPoint(
        Offset(width - radius, height),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      canvas.drawPath(path, paint);
      return;
    } else {
      path.arcToPoint(
        Offset(width - radius, height),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      remaining -= radius;
    }

    final bottomEdgeLength = width - 2 * radius;
    if (remaining <= bottomEdgeLength) {
      path.lineTo(width - radius - remaining, height);
      canvas.drawPath(path, paint);
      return;
    } else {
      path.lineTo(radius, height);
      remaining -= bottomEdgeLength;
    }

    // Bottom-left arc + left edge
    if (remaining <= radius) {
      path.arcToPoint(
        Offset(0, height - radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      canvas.drawPath(path, paint);
      return;
    } else {
      path.arcToPoint(
        Offset(0, height - radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      remaining -= radius;
    }

    final leftEdgeLength = height - 2 * radius;
    if (remaining <= leftEdgeLength) {
      path.lineTo(0, height - radius - remaining);
      canvas.drawPath(path, paint);
      return;
    } else {
      path.lineTo(0, radius);
      remaining -= leftEdgeLength;
    }

    // Top-left arc (end)
    if (remaining > 0) {
      path.arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RectangularProgressBar oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
