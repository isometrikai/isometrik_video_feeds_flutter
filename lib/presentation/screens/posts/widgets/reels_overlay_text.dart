import 'package:flutter/material.dart';

/// Labels drawn on top of reels video (counts, Share, Save).
///
/// Uses [inherit: false] and an explicit white [color] so host-app theme text
/// cannot paint counts black. Do not set [foreground] and [shadows] together —
/// that can double-render round glyphs like "0".
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
