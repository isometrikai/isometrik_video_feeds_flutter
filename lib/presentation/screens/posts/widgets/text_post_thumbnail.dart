import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

/// Compact grid thumbnail for `type: text` posts (plain text only).
class TextPostThumbnail extends StatelessWidget {
  const TextPostThumbnail({
    super.key,
    required this.formatting,
    this.padding = const EdgeInsets.all(6),
    this.maxLines = 8,
    this.fontSizeDivisor = 2.3,
  });

  factory TextPostThumbnail.fromPost(
    TimeLineData post, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    int maxLines = 8,
    double fontSizeDivisor = 2.3,
  }) =>
      TextPostThumbnail(
        formatting: post.plainTextPostFormatting,
        padding: padding,
        maxLines: maxLines,
        fontSizeDivisor: fontSizeDivisor,
      );

  /// Divides API [TextPostFormatting.fontSize] for small grid cells (~18 → ~6–7px).
  final double fontSizeDivisor;

  final TextPostFormatting formatting;
  final EdgeInsetsGeometry padding;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final plainFormatting = formatting.asPlainText();
    if (!plainFormatting.hasContent) {
      return const ColoredBox(color: Color(0xFF000000));
    }

    return ColoredBox(
      color: const Color(0xFF000000),
      child: Padding(
        padding: padding,
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            plainFormatting.text,
            textAlign: plainFormatting.textAlignValue,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: plainFormatting.buildThumbnailTextStyle(
              fontSizeDivisor: fontSizeDivisor,
              textColorOverride: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
