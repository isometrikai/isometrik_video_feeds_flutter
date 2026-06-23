import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_plain_text_post_body.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_text_post_formatted_body.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

/// Unified Threads / X style text post section for plain and formatted posts.
///
/// Layout:
/// [avatar + follow badge]  username · timestamp        [more]
///                          post content (plain text or gradient card)
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
    this.formattedAspectRatio = 1,
    this.contentTopSpacing = 4,
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
  final double formattedAspectRatio;
  final double contentTopSpacing;

  static const TextHeightBehavior _compactTextHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  bool get _isCardPost => formatting.hasBackground;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._leadingAvatarWidgets(),
            Expanded(child: _buildContentColumn()),
            if (!_isCardPost && moreButton != null) _buildMoreButtonSlot(),
          ],
        ),
      );

  Widget _buildContentColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderRow(),
          if (formatting.hasContent) ...[
            SizedBox(height: contentTopSpacing),
            _buildContent(),
          ],
        ],
      );

  /// Card posts keep [moreButton] on the username row only so the card can
  /// span the full content column width (16px from the screen edge).
  Widget _buildHeaderRow() {
    if (_isCardPost && moreButton != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildUserMetaRow()),
          _buildMoreButtonSlot(),
        ],
      );
    }
    return _buildUserMetaRow();
  }

  Widget _buildContent() {
    if (_isCardPost) {
      return FeedTextPostFormattedBody(
        formatting: formatting,
        aspectRatio: formattedAspectRatio,
      );
    }
    return FeedPlainTextPostBody(
      formatting: formatting,
      textColor: textColor,
    );
  }

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
