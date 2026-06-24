import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_text_post_formatted_body.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_mention_text.dart';

/// Renders a text-only post body using API `text_formatting`.
class FeedTextPostContent extends StatelessWidget {
  const FeedTextPostContent({
    super.key,
    required this.formatting,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
    this.plainTextColor,
    this.plainBackgroundColor,
    this.aspectRatio = 4 / 5,
    this.scrollable = true,
    this.mentions = const [],
    this.onMentionsTap,
    this.onMentionTap,
    this.mentionStyle,
    this.mentionConfig,
  });

  final TextPostFormatting formatting;
  final EdgeInsetsGeometry padding;
  final Color? plainTextColor;
  final Color? plainBackgroundColor;
  final double aspectRatio;
  final bool scrollable;
  final List<MentionMetaData> mentions;
  final void Function(List<MentionMetaData> mentions)? onMentionsTap;
  final void Function(MentionMetaData mention)? onMentionTap;
  final TextStyle? mentionStyle;
  final MentionConfig? mentionConfig;

  @override
  Widget build(BuildContext context) {
    if (!formatting.hasContent) {
      return ColoredBox(color: formatting.fallbackBackgroundColor);
    }

    if (!formatting.hasBackground) {
      final textColor = plainTextColor ?? Colors.white;
      final textStyle = formatting.buildPlainTextStyle(textColor);
      final canTapMentions = onMentionTap != null && mentions.isNotEmpty;

      return ColoredBox(
        color: plainBackgroundColor ?? const Color(0xFF000000),
        child: Padding(
          padding: padding,
          child: Align(
            alignment: formatting.alignment,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: canTapMentions
                  ? RichText(
                      textAlign: formatting.textAlignValue,
                      text: TextPostMentionText.buildDescriptionSpan(
                        text: formatting.text,
                        style: textStyle,
                        mentions: mentions,
                        onMentionTap: onMentionTap!,
                        mentionStyle: mentionStyle ??
                            textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    )
                  : Text(
                      formatting.text,
                      textAlign: formatting.textAlignValue,
                      style: textStyle,
                    ),
            ),
          ),
        ),
      );
    }

    return FeedTextPostFormattedBody(
      formatting: formatting,
      aspectRatio: aspectRatio,
      borderRadius: BorderRadius.zero,
      padding: padding,
      mentions: mentions,
      onMentionsTap: onMentionsTap,
      onMentionTap: onMentionTap,
      mentionConfig: mentionConfig,
      scrollable: scrollable,
    );
  }
}
