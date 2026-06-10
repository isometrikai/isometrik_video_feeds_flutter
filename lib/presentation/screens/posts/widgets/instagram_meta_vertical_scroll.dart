import 'package:flutter/material.dart';

/// Vertical scroll transition between two compact header meta rows
/// (e.g. location ↔ audio), similar to Instagram's subtitle ticker.
class InstagramMetaVerticalScroll extends StatefulWidget {
  const InstagramMetaVerticalScroll({
    super.key,
    required this.showSecond,
    required this.firstChild,
    required this.secondChild,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeInOut,
  });

  final bool showSecond;
  final Widget firstChild;
  final Widget secondChild;
  final Duration duration;
  final Curve curve;

  @override
  State<InstagramMetaVerticalScroll> createState() =>
      _InstagramMetaVerticalScrollState();
}

class _InstagramMetaVerticalScrollState extends State<InstagramMetaVerticalScroll>
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
  void didUpdateWidget(covariant InstagramMetaVerticalScroll oldWidget) {
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

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          if (height <= 0) {
            return widget.showSecond ? widget.secondChild : widget.firstChild;
          }

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (!_controller.isAnimating && _controller.value == 0) {
                return widget.showSecond
                    ? widget.secondChild
                    : widget.firstChild;
              }

              final t = widget.curve.transform(_controller.value);
              final goingToSecond = widget.showSecond;
              final outgoing =
                  goingToSecond ? widget.firstChild : widget.secondChild;
              final incoming =
                  goingToSecond ? widget.secondChild : widget.firstChild;

              return ClipRect(
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -height * t),
                      child: outgoing,
                    ),
                    Transform.translate(
                      offset: Offset(0, height * (1 - t)),
                      child: incoming,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
}
