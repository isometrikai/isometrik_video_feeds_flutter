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

    test('gradient background remains supported', () {
      final formatting = TextPostFormatting.fromDynamic({
        'text': 'Stay focused.',
        'background': {
          'type': 'gradient',
          'value': 'purple_pink',
          'text_color': '#FFFFFF',
        },
      });

      expect(formatting.hasBackground, isTrue);
      expect(formatting.backgroundGradient, isNotNull);
    });
  });
}
