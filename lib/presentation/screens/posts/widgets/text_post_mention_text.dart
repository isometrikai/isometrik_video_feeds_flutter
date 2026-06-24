import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utility.dart';

/// Builds tappable @mention spans for text posts (feed, reels, thumbnails).
abstract final class TextPostMentionText {
  TextPostMentionText._();

  static TextSpan buildDescriptionSpan({
    required String text,
    required TextStyle style,
    required List<MentionMetaData> mentions,
    required void Function(MentionMetaData mention) onMentionTap,
    TextStyle? mentionStyle,
    List<MentionMetaData> hashtags = const [],
  }) {
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    if (mentions.isEmpty && hashtags.isEmpty) {
      return TextSpan(
        style: style,
        children: Utility.buildPlainTextSpansWithContactLinks(text, style),
      );
    }

    final positioned = mentions
        .where(
          (m) =>
              m.textPosition?.start != null && m.textPosition?.end != null,
        )
        .toList()
      ..sort(
        (a, b) => (a.textPosition!.start ?? 0).compareTo(
          b.textPosition!.start ?? 0,
        ),
      );

    if (positioned.isNotEmpty) {
      final positionedSpan = _buildFromPositions(
        text: text,
        style: style,
        mentions: positioned,
        onMentionTap: onMentionTap,
        mentionStyle: mentionStyle,
      );
      if (positionedSpan != null) return positionedSpan;
    }

    return Utility.buildPostDescriptionTextSpan(
      text,
      mentions,
      hashtags,
      style,
      onMentionTap,
      mentionStyle: mentionStyle,
    );
  }

  static TextSpan? _buildFromPositions({
    required String text,
    required TextStyle style,
    required List<MentionMetaData> mentions,
    required void Function(MentionMetaData mention) onMentionTap,
    TextStyle? mentionStyle,
  }) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final mention in mentions) {
      final start = mention.textPosition!.start!.toInt().clamp(0, text.length);
      final end =
          mention.textPosition!.end!.toInt().clamp(start, text.length);
      if (start < cursor) continue;

      if (start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, start),
            style: style,
          ),
        );
      }

      final slice = text.substring(start, end);
      if (slice.isEmpty) continue;

      spans.add(
        TextSpan(
          text: slice,
          style: mentionStyle ??
              style.copyWith(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onMentionTap(mention),
        ),
      );
      cursor = end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: style,
        ),
      );
    }

    if (spans.isEmpty) return null;
    return TextSpan(style: style, children: spans);
  }
}
