import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_mention_text.dart';

/// Gradient / color background text block for formatted text posts in feed.
class FeedTextPostFormattedBody extends StatelessWidget {
  const FeedTextPostFormattedBody({
    super.key,
    required this.formatting,
    this.aspectRatio = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    this.onTap,
    this.mentions = const [],
    this.onMentionsTap,
    this.onMentionTap,
    this.mentionStyle,
    this.mentionConfig,
    this.scrollable = false,
  });

  final TextPostFormatting formatting;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final List<MentionMetaData> mentions;
  final void Function(List<MentionMetaData> mentions)? onMentionsTap;
  final void Function(MentionMetaData mention)? onMentionTap;
  final TextStyle? mentionStyle;
  final MentionConfig? mentionConfig;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (!formatting.hasBackground || !formatting.hasContent) {
      return const SizedBox.shrink();
    }

    final gradient = formatting.backgroundGradient;
    final textStyle = formatting.buildTextStyle();
    final canTapMentions = onMentionTap != null && mentions.isNotEmpty;
    final showMentionBadge =
        mentions.isNotEmpty && onMentionsTap != null;
    // Card mentions keep the same look as body text; taps still work.
    final effectiveMentionStyle = mentionStyle ?? textStyle;

    final textWidget = canTapMentions
        ? RichText(
            textAlign: formatting.textAlignValue,
            text: TextPostMentionText.buildDescriptionSpan(
              text: formatting.text,
              style: textStyle,
              mentions: mentions,
              onMentionTap: onMentionTap!,
              mentionStyle: effectiveMentionStyle,
            ),
          )
        : Text(
            formatting.text,
            textAlign: formatting.textAlignValue,
            style: textStyle,
          );

    final alignedText = Align(
      alignment: formatting.alignment,
      child: scrollable
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: textWidget,
            )
          : textWidget,
    );

    final card = ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                color:
                    gradient == null ? formatting.fallbackBackgroundColor : null,
              ),
              child: Padding(
                padding: padding,
                child: alignedText,
              ),
            ),
            if (showMentionBadge)
              Positioned(
                left: 12,
                bottom: 12,
                child: _InCardMentionBadge(
                  onTap: () => onMentionsTap!(mentions),
                  mentionConfig: mentionConfig,
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Compact icon-only badge (black circle, white icon) — same affordance as image posts.
class _InCardMentionBadge extends StatelessWidget {
  const _InCardMentionBadge({
    required this.onTap,
    this.mentionConfig,
  });

  final VoidCallback onTap;
  final MentionConfig? mentionConfig;

  static const double _iconSize = 16;
  static const double _padding = 6;

  @override
  Widget build(BuildContext context) {
    final iconSize = mentionConfig?.mentionIconSize ?? _iconSize;

    return TapHandler(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: mentionConfig?.mentionIcon != null
            ? AppImage.svg(
                mentionConfig!.mentionIcon!,
                width: iconSize,
                height: iconSize,
                color: Colors.white,
              )
            : Icon(
                Icons.person_rounded,
                size: iconSize,
                color: Colors.white,
              ),
      ),
    );
  }
}
