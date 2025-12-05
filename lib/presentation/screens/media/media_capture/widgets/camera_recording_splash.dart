import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

class CameraRecordingSplash extends StatefulWidget {
  const CameraRecordingSplash({super.key});

  @override
  State<CameraRecordingSplash> createState() => _CameraRecordingSplashState();
}

class _CameraRecordingSplashState extends State<CameraRecordingSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final splashSize = screenSize.width * 0.3;

    final buttonCenterX = screenSize.width / 2;
    final buttonCenterY = screenSize.height -
        safeAreaBottom -
        IsrDimens.sixteen -
        (IsrDimens.sixtyFour / 2) -
        IsrDimens.four;

    return Positioned(
      left: buttonCenterX - (splashSize / 2),
      top: buttonCenterY - (splashSize / 2),
      child: IgnorePointer(
        child: SizedBox(
          width: splashSize,
          height: splashSize,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _RecordingSplashPainter(
                progress: _controller.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingSplashPainter extends CustomPainter {
  _RecordingSplashPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;
    final minRadius = size.width * 0.1;

    final radius = minRadius + (maxRadius - minRadius) * progress;

    for (var i = 0; i < 3; i++) {
      final rippleProgress = (progress + i * 0.3) % 1.0;
      final rippleRadius = minRadius + (maxRadius - minRadius) * rippleProgress;
      final opacity = (1.0 - rippleProgress) * 0.4;

      final paint = Paint()
        ..color = Colors.red.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, rippleRadius, paint);
    }

    final mainPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, mainPaint);
  }

  @override
  bool shouldRepaint(_RecordingSplashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
