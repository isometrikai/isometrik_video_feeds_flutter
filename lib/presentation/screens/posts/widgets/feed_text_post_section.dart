import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_plain_text_post_body.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

/// Threads / X style text post section — plain text only.
///
/// Layout:
/// [avatar + follow badge]  username · timestamp        [more]
///                          post content
class FeedTextPostSection extends StatelessWidget {
  const FeedTextPostSection({
    super.key,
    required this.formatting,
    required this.userName,
    required this.userNameStyle,
    required this.textColor,
    required this.timestampColor,
    this.profileAvatar,
    this.timestamp,
    this.isVerified = false,
    this.onUserTap,
    this.moreButton,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 4),
    this.avatarGap = 12,
    this.verifiedBadge,
    this.contentTopSpacing = 4,
    this.plainTextBodyStyle,
    this.plainTextToggleStyle,
    this.mentions = const [],
    this.onMentionTap,
    this.onMentionsTap,
    this.mentionStyle,
    this.mentionConfig,
  });

  final TextPostFormatting formatting;
  final String userName;
  final TextStyle userNameStyle;
  final Color textColor;
  final Color timestampColor;
  final Widget? profileAvatar;
  final String? timestamp;
  final bool isVerified;
  final VoidCallback? onUserTap;
  final Widget? moreButton;
  final EdgeInsetsGeometry padding;
  final double avatarGap;
  final Widget? verifiedBadge;
  final double contentTopSpacing;
  final TextStyle? plainTextBodyStyle;
  final TextStyle? plainTextToggleStyle;
  final List<MentionMetaData> mentions;
  final void Function(MentionMetaData mention)? onMentionTap;
  final void Function(List<MentionMetaData> mentions)? onMentionsTap;
  final TextStyle? mentionStyle;
  final MentionConfig? mentionConfig;

  static const TextHeightBehavior _compactTextHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  TextPostFormatting get _plainFormatting => formatting.asPlainText();

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._leadingAvatarWidgets(),
            Expanded(child: _buildContentColumn()),
            if (moreButton != null) _buildMoreButtonSlot(),
          ],
        ),
      );

  Widget _buildContentColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserMetaRow(),
          if (_plainFormatting.hasContent) ...[
            SizedBox(height: contentTopSpacing),
            FeedPlainTextPostBody(
              formatting: _plainFormatting,
              textColor: textColor,
              bodyTextStyle: plainTextBodyStyle,
              moreTextStyle: plainTextToggleStyle,
              mentions: mentions,
              onMentionTap: onMentionTap,
              mentionStyle: mentionStyle,
            ),
          ],
        ],
      );

  List<Widget> _leadingAvatarWidgets() {
    if (profileAvatar == null) return const [];
    return [
      profileAvatar!,
      SizedBox(width: avatarGap),
    ];
  }

  Widget _buildMoreButtonSlot() => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: moreButton!,
        ),
      );

  Widget _buildUserMetaRow() => TapHandler(
        onTap: onUserTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                userName,
                style: userNameStyle.copyWith(height: 1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textHeightBehavior: _compactTextHeight,
              ),
            ),
            if (isVerified && verifiedBadge != null) ...[
              const SizedBox(width: 4),
              verifiedBadge!,
            ],
            if (timestamp != null && timestamp!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                timestamp!,
                style: userNameStyle.copyWith(
                  fontSize: (userNameStyle.fontSize ?? 14) - 1,
                  fontWeight: FontWeight.w400,
                  color: timestampColor,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textHeightBehavior: _compactTextHeight,
              ),
            ],
          ],
        ),
      );
}
