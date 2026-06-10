import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Instagram-style vertical cube flip between two compact header meta rows
/// (e.g. location ↔ audio).
class InstagramMetaCubeFlip extends StatefulWidget {
  const InstagramMetaCubeFlip({
    super.key,
    required this.showSecond,
    required this.firstChild,
    required this.secondChild,
    this.duration = const Duration(milliseconds: 400),
    this.perspective = 0.0012,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final bool showSecond;
  final Widget firstChild;
  final Widget secondChild;
  final Duration duration;
  final double perspective;
  final AlignmentGeometry alignment;

  @override
  State<InstagramMetaCubeFlip> createState() => _InstagramMetaCubeFlipState();
}

class _InstagramMetaCubeFlipState extends State<InstagramMetaCubeFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(covariant InstagramMetaCubeFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSecond != widget.showSecond) {
      _controller.forward(from: 0);
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _cubeFace(Widget child, double angle) {
    final opacity = math.cos(angle).abs().clamp(0.0, 1.0);
    return ClipRect(
      child: Transform(
        alignment: widget.alignment,
        transform: Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(angle),
        child: Opacity(
          opacity: opacity,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_controller.isAnimating && _controller.value == 0) {
          return widget.showSecond ? widget.secondChild : widget.firstChild;
        }

        final t = Curves.easeInOutCubic.transform(_controller.value);
        final goingToSecond = widget.showSecond;
        final outgoing =
            goingToSecond ? widget.firstChild : widget.secondChild;
        final incoming =
            goingToSecond ? widget.secondChild : widget.firstChild;

        if (t < 0.5) {
          final angle = -math.pi / 2 * (t * 2);
          return _cubeFace(outgoing, angle);
        }

        final angle = math.pi / 2 * (1 - (t - 0.5) * 2);
        return _cubeFace(incoming, angle);
      },
    );
  }
}
