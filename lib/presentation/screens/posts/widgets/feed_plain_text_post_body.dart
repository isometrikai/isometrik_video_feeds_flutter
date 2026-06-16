import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

/// Body text for plain (no background) text posts in feed — sits directly under the username row.
class FeedPlainTextPostBody extends StatelessWidget {
  const FeedPlainTextPostBody({
    super.key,
    required this.formatting,
    required this.textColor,
  });

  final TextPostFormatting formatting;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (!formatting.hasContent) return const SizedBox.shrink();

    return Text(
      formatting.text,
      textAlign: formatting.textAlignValue,
      style: formatting.buildPlainTextStyle(textColor).copyWith(height: 1.3),
    );
  }
}
