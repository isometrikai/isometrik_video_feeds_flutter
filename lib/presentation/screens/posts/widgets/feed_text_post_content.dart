import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

/// Renders a text-only post body using API `text_formatting`.
class FeedTextPostContent extends StatelessWidget {
  const FeedTextPostContent({
    super.key,
    required this.formatting,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
    this.plainTextColor,
    this.plainBackgroundColor,
  });

  final TextPostFormatting formatting;
  final EdgeInsetsGeometry padding;
  final Color? plainTextColor;
  final Color? plainBackgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!formatting.hasContent) {
      return ColoredBox(color: formatting.fallbackBackgroundColor);
    }

    if (!formatting.hasBackground) {
      final textColor = plainTextColor ?? Colors.white;
      return ColoredBox(
        color: plainBackgroundColor ?? const Color(0xFF000000),
        child: Padding(
          padding: padding,
          child: Align(
            alignment: formatting.alignment,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                formatting.text,
                textAlign: formatting.textAlignValue,
                style: formatting.buildPlainTextStyle(textColor),
              ),
            ),
          ),
        ),
      );
    }

    final gradient = formatting.backgroundGradient;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? formatting.fallbackBackgroundColor : null,
      ),
      child: Padding(
        padding: padding,
        child: Align(
          alignment: formatting.alignment,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              formatting.text,
              textAlign: formatting.textAlignValue,
              style: formatting.buildTextStyle(),
            ),
          ),
        ),
      ),
    );
  }
}
