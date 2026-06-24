import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_text_post_content.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Resolves @mentions for a post — same source order as the feed card.
List<MentionMetaData> resolveTextPostMentions(ReelsData reel) {
  if (!reel.mentions.isListEmptyOrNull) return reel.mentions;

  final postData = reel.postData;
  if (postData is! TimeLineData) return const [];

  final mentions = postData.tags?.mentions;
  if (mentions.isListEmptyOrNull) return const [];

  return mentions!
      .map(
        (m) => MentionMetaData(
          userId: m.userId,
          username: m.username,
          name: m.name,
          avatarUrl: m.avatarUrl,
          tag: m.tag,
          textPosition: m.textPosition != null
              ? MentionPosition(
                  start: m.textPosition?.start,
                  end: m.textPosition?.end,
                )
              : null,
          mediaPosition: m.mediaPosition != null
              ? MediaPosition(
                  position: m.mediaPosition?.position,
                  x: m.mediaPosition?.x,
                  y: m.mediaPosition?.y,
                )
              : null,
        ),
      )
      .toList();
}

/// Text-card body for fullscreen preview — taller than the feed card.
class FeedTextPostFullscreenCard extends StatelessWidget {
  const FeedTextPostFullscreenCard({
    super.key,
    required this.formatting,
    this.formattedAspectRatio = 4 / 5,
    this.mentions = const [],
    this.onMentionTap,
    this.onMentionsTap,
    this.mentionConfig,
  });

  final TextPostFormatting formatting;
  final double formattedAspectRatio;
  final List<MentionMetaData> mentions;
  final void Function(MentionMetaData mention)? onMentionTap;
  final void Function(List<MentionMetaData> mentions)? onMentionsTap;
  final MentionConfig? mentionConfig;

  /// Minimum card height in logical pixels (matches composer card floor).
  static const double minCardHeight = 300;

  /// Fill the padded preview column between top/bottom chrome.
  static const double previewHeightFraction = 1;

  static double resolvePreviewCardHeight({
    required double maxWidth,
    required double maxHeight,
    required double formattedAspectRatio,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0) return minCardHeight;

    final aspectHeight = maxWidth / formattedAspectRatio;
    final expandedHeight = maxHeight * previewHeightFraction;
    return math.min(
      maxHeight,
      math.max(minCardHeight, math.max(aspectHeight, expandedHeight)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final cardHeight = resolvePreviewCardHeight(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          formattedAspectRatio: formattedAspectRatio,
        );

        return SizedBox(
          width: maxWidth,
          height: cardHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(IsrDimens.twelve),
            child: FeedTextPostContent(
              formatting: formatting,
              aspectRatio: maxWidth / cardHeight,
              scrollable: true,
              mentions: mentions,
              onMentionTap: onMentionTap,
              onMentionsTap: onMentionsTap,
              mentionConfig: mentionConfig,
            ),
          ),
        );
      },
    );
  }
}
