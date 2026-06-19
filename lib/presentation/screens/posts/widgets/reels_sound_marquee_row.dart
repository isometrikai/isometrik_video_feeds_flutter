import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/post_sound_info.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_sound_icon.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/tap_handler.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

/// Glassy reels sound row: note icon + auto-scrolling title/artist with a
/// right-edge fade before the follow button.
class ReelsSoundMarqueeRow extends StatelessWidget {
  const ReelsSoundMarqueeRow({
    super.key,
    required this.sound,
    required this.textStyle,
    required this.onTap,
    this.fadeRightEdge = true,
    this.fadeWidth = 36,
  });

  final PostSoundInfo sound;
  final TextStyle textStyle;
  final VoidCallback onTap;
  final bool fadeRightEdge;
  final double fadeWidth;

  double get _iconBlockWidth => 14.responsiveDimension + IsrDimens.four;

  static double _measureTextWidth(
    BuildContext context,
    String text,
    TextStyle style,
  ) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final label = sound.glassyMarqueeLabel;
    final lineHeight = (textStyle.fontSize ?? 12) * (textStyle.height ?? 1.2);

    Widget buildMarquee({
      required double textViewportWidth,
      required bool needsScroll,
    }) {
      final marquee = ReelsMarqueeText(
        text: label,
        style: textStyle,
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PostSoundIcon(
            size: 14.responsiveDimension,
            style: PostSoundIconStyle.glassOverlay,
          ),
          IsrDimens.boxWidth(IsrDimens.four),
          SizedBox(
            width: textViewportWidth,
            height: lineHeight,
            child: fadeRightEdge && needsScroll
                ? ShaderMask(
                    shaderCallback: (bounds) {
                      final fadeStart =
                          ((bounds.width - fadeWidth) / bounds.width)
                              .clamp(0.0, 1.0);
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.0, fadeStart, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: marquee,
                  )
                : marquee,
          ),
        ],
      );
    }

    return TapHandler(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowMaxWidth = constraints.maxWidth;
          if (!rowMaxWidth.isFinite || rowMaxWidth <= 0) {
            return Row(
              children: [
                PostSoundIcon(
                  size: 14.responsiveDimension,
                  style: PostSoundIconStyle.glassOverlay,
                ),
                IsrDimens.boxWidth(IsrDimens.four),
                Expanded(
                  child: SizedBox(
                    height: lineHeight,
                    child: ReelsMarqueeText(
                      text: label,
                      style: textStyle,
                    ),
                  ),
                ),
              ],
            );
          }

          final fullTextWidth =
              _measureTextWidth(context, label, textStyle);
          final availableTextWidth =
              (rowMaxWidth - _iconBlockWidth).clamp(0.0, double.infinity);
          final needsScroll = fullTextWidth > availableTextWidth + 0.5;
          final textViewportWidth = needsScroll
              ? availableTextWidth
              : (fullTextWidth + 2).ceilToDouble();

          if (textViewportWidth <= 0) {
            return const SizedBox.shrink();
          }

          return buildMarquee(
            textViewportWidth: textViewportWidth,
            needsScroll: needsScroll,
          );
        },
      ),
    );
  }
}

/// Seamless infinite marquee — plain [Text] only (no [WidgetSpan]).
class ReelsMarqueeText extends StatefulWidget {
  const ReelsMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 14,
    this.gap = 48,
    this.startPause = const Duration(milliseconds: 1800),
  });

  final String text;
  final TextStyle style;
  final double velocity;
  final double gap;
  final Duration startPause;

  @override
  State<ReelsMarqueeText> createState() => _ReelsMarqueeTextState();
}

class _ReelsMarqueeTextState extends State<ReelsMarqueeText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _offsetAnimation;
  double _loopDistance = 0;
  String? _loopedText;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReelsMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.velocity != widget.velocity ||
        oldWidget.gap != widget.gap ||
        oldWidget.startPause != widget.startPause) {
      _disposeController();
      _loopedText = null;
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _offsetAnimation = null;
    _loopDistance = 0;
  }

  double _measureTextWidth(BuildContext context, String text) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  String _gapPadding(BuildContext context) {
    final spaceWidth = _measureTextWidth(context, '\u00A0');
    if (spaceWidth <= 0) return '\u00A0\u00A0\u00A0\u00A0';
    final count = (widget.gap / spaceWidth).ceil().clamp(2, 64);
    return List.filled(count, '\u00A0').join();
  }

  String _buildLoopedText(BuildContext context) {
    final gap = _gapPadding(context);
    return '${widget.text}$gap${widget.text}';
  }

  double _measureLoopDistance(BuildContext context, String loopedText) {
    final fullWidth = _measureTextWidth(context, loopedText);
    return fullWidth / 2;
  }

  void _configureAnimation(double loopDistance) {
    if (loopDistance <= 0) {
      _disposeController();
      return;
    }

    if (_controller != null && (_loopDistance - loopDistance).abs() < 0.5) {
      return;
    }

    _disposeController();
    _loopDistance = loopDistance;

    final scrollMs =
        ((loopDistance / widget.velocity) * 1000).round().clamp(5000, 22000);
    final pauseMs = widget.startPause.inMilliseconds;
    final totalMs = pauseMs + scrollMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: pauseMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: loopDistance),
        weight: scrollMs.toDouble(),
      ),
    ]).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.linear,
    ));

    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _controller!.forward(from: 0);
      }
    });

    _controller!.forward(from: 0);
  }

  Widget _buildLine(String text) => Text(
        text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      );

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewWidth = constraints.maxWidth;
          if (!constraints.hasBoundedWidth || viewWidth <= 0) {
            return const SizedBox.shrink();
          }

          final textWidth = _measureTextWidth(context, widget.text);
          final needsScroll = textWidth > viewWidth + 1;

          if (!needsScroll) {
            if (_controller != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(_disposeController);
              });
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: _buildLine(widget.text),
            );
          }

          _loopedText ??= _buildLoopedText(context);
          final loopedText = _loopedText!;
          final loopDistance = _measureLoopDistance(context, loopedText);

          if (_controller == null ||
              (_loopDistance - loopDistance).abs() >= 0.5) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _configureAnimation(loopDistance);
              setState(() {});
            });
          }

          final animation = _offsetAnimation;
          if (animation == null) {
            return Align(
              alignment: Alignment.centerLeft,
              child: _buildLine(loopedText),
            );
          }

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-animation.value, 0),
                child: _buildLine(loopedText),
              ),
            ),
          );
        },
      ),
    );
  }
}
