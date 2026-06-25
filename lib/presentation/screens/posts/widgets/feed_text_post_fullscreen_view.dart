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

/// Plain text body for fullscreen preview.
class FeedTextPostFullscreenCard extends StatelessWidget {
  const FeedTextPostFullscreenCard({
    super.key,
    required this.formatting,
    this.mentions = const [],
    this.onMentionTap,
    this.onMentionsTap,
    this.mentionConfig,
  });

  final TextPostFormatting formatting;
  final List<MentionMetaData> mentions;
  final void Function(MentionMetaData mention)? onMentionTap;
  final void Function(List<MentionMetaData> mentions)? onMentionsTap;
  final MentionConfig? mentionConfig;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        IsrDimens.twentyFour,
        IsrDimens.sixteen,
        IsrDimens.twentyFour,
        IsrDimens.sixteen,
      ),
      child: FeedTextPostContent(
        formatting: formatting,
        scrollable: true,
        mentions: mentions,
        onMentionTap: onMentionTap,
        onMentionsTap: onMentionsTap,
        mentionConfig: mentionConfig,
      ),
    );
  }
}
