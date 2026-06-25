import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_mention_text.dart';

/// Renders a text-only post body using plain default theme (ignores card formatting).
class FeedTextPostContent extends StatelessWidget {
  const FeedTextPostContent({
    super.key,
    required this.formatting,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
    this.plainTextColor,
    this.plainBackgroundColor,
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
  final bool scrollable;
  final List<MentionMetaData> mentions;
  final void Function(List<MentionMetaData> mentions)? onMentionsTap;
  final void Function(MentionMetaData mention)? onMentionTap;
  final TextStyle? mentionStyle;
  final MentionConfig? mentionConfig;

  @override
  Widget build(BuildContext context) {
    final plainFormatting = formatting.asPlainText();
    if (!plainFormatting.hasContent) {
      return ColoredBox(color: plainBackgroundColor ?? const Color(0xFF000000));
    }

    final textColor = plainTextColor ?? Colors.white;
    final textStyle = plainFormatting.buildPlainTextStyle(textColor);
    final canTapMentions = onMentionTap != null && mentions.isNotEmpty;
    final body = canTapMentions
        ? RichText(
            textAlign: plainFormatting.textAlignValue,
            text: TextPostMentionText.buildDescriptionSpan(
              text: plainFormatting.text,
              style: textStyle,
              mentions: mentions,
              onMentionTap: onMentionTap!,
              mentionStyle: mentionStyle ??
                  textStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          )
        : Text(
            plainFormatting.text,
            textAlign: plainFormatting.textAlignValue,
            style: textStyle,
          );

    return ColoredBox(
      color: plainBackgroundColor ?? const Color(0xFF000000),
      child: Padding(
        padding: padding,
        child: Align(
          alignment: plainFormatting.alignment,
          child: scrollable
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: body,
                )
              : body,
        ),
      ),
    );
  }
}
