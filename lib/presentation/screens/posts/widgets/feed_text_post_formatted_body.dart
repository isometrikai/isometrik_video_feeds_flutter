import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

/// Gradient / color background text block for formatted text posts in feed.
class FeedTextPostFormattedBody extends StatelessWidget {
  const FeedTextPostFormattedBody({
    super.key,
    required this.formatting,
    this.aspectRatio = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  });

  final TextPostFormatting formatting;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!formatting.hasBackground || !formatting.hasContent) {
      return const SizedBox.shrink();
    }

    final gradient = formatting.backgroundGradient;
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? formatting.fallbackBackgroundColor : null,
          ),
          child: Padding(
            padding: padding,
            child: Align(
              alignment: formatting.alignment,
              child: Text(
                formatting.text,
                textAlign: formatting.textAlignValue,
                style: formatting.buildTextStyle(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
