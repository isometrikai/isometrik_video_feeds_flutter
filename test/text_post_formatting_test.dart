import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

void main() {
  group('TextPostFormatting', () {
    test('empty background is treated as plain text post', () {
      final formatting = TextPostFormatting.fromDynamic({
        'text': 'text test post',
        'font_family': 'Open Sans',
        'font_size': 17,
        'font_style': 'normal',
        'text_align': 'left',
        'background': <String, dynamic>{},
      });

      expect(formatting.hasBackground, isFalse);
      expect(formatting.backgroundGradient, isNull);
      expect(formatting.text, 'text test post');
      expect(formatting.textAlignValue.name, 'left');
    });

    test('plain text uses bundled font without GoogleFonts', () {
      final formatting = TextPostFormatting.fromDynamic({
        'text': 'Hello @user',
        'font_family': 'Product Sans',
        'font_size': 16,
        'font_style': 'normal',
        'text_align': 'left',
      });

      expect(TextPostFormatting.usesGoogleFont('Product Sans'), isFalse);
      final style = formatting.buildPlainTextStyle(const Color(0xFFFFFFFF));
      expect(style.fontFamily, 'Product Sans');
      expect(style.fontSize, 16);
    });

    test('asPlainText strips card background and resets typography', () {
      final formatting = TextPostFormatting.fromDynamic({
        'text': 'Stay focused.',
        'font_family': 'Pacifico',
        'font_size': 32,
        'font_style': 'bold',
        'text_align': 'center',
        'background': {
          'type': 'gradient',
          'value': 'purple_pink',
          'text_color': '#FFFFFF',
        },
      });

      expect(formatting.hasBackground, isTrue);
      final plain = formatting.asPlainText();
      expect(plain.hasBackground, isFalse);
      expect(plain.text, 'Stay focused.');
      expect(plain.fontSize, TextPostFormatting.plainFontSize);
      expect(plain.textAlign, TextPostFormatting.plainTextAlign);
    });
  });
}
