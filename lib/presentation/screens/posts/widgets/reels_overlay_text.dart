import 'package:flutter/material.dart';

/// Labels drawn on top of reels video (counts, Share, Save, captions).
///
/// Host apps often wrap the SDK in a dark [DefaultTextStyle] for the Feed tab.
/// Material 3 [TextStyle.foreground] on that style overrides [TextStyle.color]
/// when styles merge, so normal [Text] can render black on video. This widget
/// always paints with an explicit foreground and never inherits theme text.
///
/// Shadows are painted as a separate offset text layer (not [TextStyle.shadows])
/// to avoid Impeller glyph-shadow ghosting when text scrolls or the value changes.
class ReelsOverlayText extends StatelessWidget {
  const ReelsOverlayText(
    this.data, {
    super.key,
    this.color = foreground,
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
  final Color color;
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

  TextStyle _baseStyle({required Color textColor}) => TextStyle(
        inherit: false,
        color: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
        letterSpacing: letterSpacing,
        height: height,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  @override
  Widget build(BuildContext context) {
    final style = _baseStyle(textColor: color);
    return _LayeredShadowText(
      shadows: shadows,
      textAlign: textAlign,
      builder: (textColor) => Text(
            data,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            style: textColor == null ? style : _baseStyle(textColor: textColor),
          ),
    );
  }
}

/// [RichText] variant that uses layered shadows instead of [TextStyle.shadows].
class ReelsOverlayRichText extends StatelessWidget {
  const ReelsOverlayRichText({
    super.key,
    required this.text,
    this.shadows,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final InlineSpan text;
  final List<Shadow>? shadows;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => _LayeredShadowText(
        shadows: shadows,
        textAlign: textAlign,
        builder: (shadowColor) => RichText(
          textAlign: textAlign ?? TextAlign.start,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.clip,
          text: shadowColor == null
              ? _stripGlyphShadows(text)
              : _recolorSpanForShadow(text, shadowColor),
        ),
      );
}

/// Shared stack that paints offset duplicate glyphs under the real text.
class _LayeredShadowText extends StatelessWidget {
  const _LayeredShadowText({
    required this.builder,
    this.shadows,
    this.textAlign,
  });

  /// Builds the text widget. Pass `null` for the main (foreground) layer;
  /// pass a shadow color for each shadow layer.
  final Widget Function(Color? shadowColor) builder;
  final List<Shadow>? shadows;
  final TextAlign? textAlign;

  /// Keep shadow layers aligned with [textAlign]. Default is start/left so
  /// short labels inside [Expanded] do not appear centered.
  Alignment get _stackAlignment {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
      case null:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shadowList = shadows;
    if (shadowList == null || shadowList.isEmpty) {
      return builder(null);
    }

    return Stack(
      alignment: _stackAlignment,
      clipBehavior: Clip.none,
      children: [
        for (final shadow in shadowList)
          IgnorePointer(
            child: Transform.translate(
              offset: shadow.offset,
              child: builder(shadow.color),
            ),
          ),
        builder(null),
      ],
    );
  }
}

InlineSpan _stripGlyphShadows(InlineSpan span) {
  if (span is! TextSpan) return span;
  return TextSpan(
    text: span.text,
    children: span.children?.map(_stripGlyphShadows).toList(),
    style: span.style?.copyWith(shadows: const []),
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

/// Shadow layer: same glyphs, flat shadow color, no nested glyph shadows / gestures.
InlineSpan _recolorSpanForShadow(InlineSpan span, Color color) {
  if (span is! TextSpan) return span;
  return TextSpan(
    text: span.text,
    children: span.children?.map((child) => _recolorSpanForShadow(child, color)).toList(),
    style: (span.style ?? const TextStyle()).copyWith(
      color: color,
      shadows: const [],
    ),
  );
}
