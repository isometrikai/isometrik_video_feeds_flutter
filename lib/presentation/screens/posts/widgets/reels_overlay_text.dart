import 'package:flutter/material.dart';

/// Labels drawn on top of reels video (counts, Share, Save).
///
/// Host apps often wrap the SDK in a dark [DefaultTextStyle] for the Feed tab.
/// Material 3 [TextStyle.foreground] on that style overrides [TextStyle.color]
/// when styles merge, so normal [Text] can render black on video. This widget
/// always paints with an explicit white foreground and never inherits theme text.
class ReelsOverlayText extends StatelessWidget {
  const ReelsOverlayText(
    this.data, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.letterSpacing,
    this.height,
    this.shadows,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double? letterSpacing;
  final double? height;
  final List<Shadow>? shadows;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static const Color foreground = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) => Text(
        data,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          inherit: false,
          color: foreground,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing,
          height: height,
          shadows: shadows,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        ),
      );
}
