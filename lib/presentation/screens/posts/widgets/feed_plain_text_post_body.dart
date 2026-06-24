import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_mention_text.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/text_post_composer_limits.dart';

/// Body text for plain (no background) text posts in feed — sits directly under the username row.
///
/// Long posts collapse to [TextPostComposerLimits.feedDisplayMaxLines] rendered lines
/// with an inline `... more` / ` less` affordance (Instagram-style).
class FeedPlainTextPostBody extends StatefulWidget {
  const FeedPlainTextPostBody({
    super.key,
    required this.formatting,
    required this.textColor,
    this.bodyTextStyle,
    this.collapsedMaxLines = TextPostComposerLimits.feedDisplayMaxLines,
    this.moreTextStyle,
    this.mentions = const [],
    this.onMentionTap,
    this.mentionStyle,
  });

  final TextPostFormatting formatting;
  final Color textColor;
  final TextStyle? bodyTextStyle;
  final int collapsedMaxLines;
  final TextStyle? moreTextStyle;
  final List<MentionMetaData> mentions;
  final void Function(MentionMetaData mention)? onMentionTap;
  final TextStyle? mentionStyle;

  static const String collapsedEllipsis = '...';

  @override
  State<FeedPlainTextPostBody> createState() => _FeedPlainTextPostBodyState();
}

class _FeedPlainTextPostBodyState extends State<FeedPlainTextPostBody> {
  var _expanded = false;

  void _onToggleTap() => setState(() => _expanded = !_expanded);

  String get _moreToggleLabel =>
      ' ${IsrTranslationFile.plainTextPostMore}';

  String get _lessToggleLabel =>
      ' ${IsrTranslationFile.plainTextPostLess}';

  WidgetSpan _toggleSpan(String label, TextStyle style) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: _onToggleTap,
          behavior: HitTestBehavior.opaque,
          child: Text(label, style: style),
        ),
      );

  TextSpan _buildBodySpan(
    String value,
    TextStyle textStyle,
  ) =>
      TextPostMentionText.buildDescriptionSpan(
        text: value,
        style: textStyle,
        mentions: widget.mentions,
        onMentionTap: widget.onMentionTap ?? (_) {},
        mentionStyle: widget.onMentionTap == null
            ? null
            : (widget.mentionStyle ??
                textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: IsrColors.appColor,
                )),
      );

  @override
  Widget build(BuildContext context) {
    if (!widget.formatting.hasContent) return const SizedBox.shrink();

    final text = TextPostComposerLimits.normalizeForFeedDisplay(
      widget.formatting.text,
    );
    final textStyle = (widget.bodyTextStyle ??
            widget.formatting.buildPlainTextStyle(widget.textColor))
        .copyWith(height: 1.3);
    final toggleStyle = widget.moreTextStyle ??
        textStyle.copyWith(fontWeight: FontWeight.w700);
    final textAlign = widget.formatting.textAlignValue;
    final canTapMentions =
        widget.onMentionTap != null && widget.mentions.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final showToggle = maxWidth > 0 &&
            TextPostComposerLimits.exceedsFeedDisplayLines(
              text: text,
              style: textStyle,
              maxWidth: maxWidth,
              textAlign: textAlign,
              maxLines: widget.collapsedMaxLines,
            );

        if (!showToggle) {
          if (!canTapMentions) {
            return Text(
              text,
              textAlign: textAlign,
              style: textStyle,
            );
          }
          return RichText(
            textAlign: textAlign,
            text: _buildBodySpan(text, textStyle),
          );
        }

        if (_expanded) {
          return Text.rich(
            TextSpan(
              style: textStyle,
              children: [
                if (canTapMentions)
                  _buildBodySpan(text, textStyle)
                else
                  TextSpan(text: text),
                _toggleSpan(_lessToggleLabel, toggleStyle),
              ],
            ),
            textAlign: textAlign,
          );
        }

        final trimAt = TextPostComposerLimits.trimIndexForInlineToggle(
          text: text,
          bodyStyle: textStyle,
          toggleStyle: toggleStyle,
          ellipsis: FeedPlainTextPostBody.collapsedEllipsis,
          toggleText: _moreToggleLabel,
          maxWidth: maxWidth,
          maxLines: widget.collapsedMaxLines,
          textAlign: textAlign,
        );

        final collapsedText = text.substring(0, trimAt);

        return Text.rich(
          TextSpan(
            style: textStyle,
            children: [
              if (canTapMentions)
                _buildBodySpan(collapsedText, textStyle)
              else
                TextSpan(text: collapsedText),
              const TextSpan(text: FeedPlainTextPostBody.collapsedEllipsis),
              _toggleSpan(_moreToggleLabel, toggleStyle),
            ],
          ),
          textAlign: textAlign,
        );
      },
    );
  }
}
