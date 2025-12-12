import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

class DashedBorderContainer extends StatelessWidget {
  DashedBorderContainer({
    super.key,
    required this.child,
    this.strokeWidth = 1.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.color = IsrColors.blackColor,
    this.radius = 0.0,
    this.padding,
  });

  final Widget child;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final Color color;
  final double radius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: DashedBorderPainter(
          strokeWidth: strokeWidth,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
          color: color,
          radius: radius,
        ),
        child: Padding(
          padding: padding ?? IsrDimens.edgeInsetsAll(0),
          child: child,
        ),
      );
}

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.color,
    required this.radius,
  });

  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    /// inset so stroke isn’t clipped
    final inset = strokeWidth / 2;

    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(radius),
        ),
      );

    final dashed = _createDashedPath(path);
    canvas.drawPath(dashed, paint);
  }

  Path _createDashedPath(Path source) {
    final dashedPath = Path();

    for (final metric in source.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, next),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}
