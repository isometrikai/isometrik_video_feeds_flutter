import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/utils/caption_link_utils.dart';

void main() {
  group('CaptionLinkUtils', () {
    test('finds valid email addresses', () {
      final links = CaptionLinkUtils.findLinks(
        'Reach us at hello@example.com for help.',
      );

      expect(links, hasLength(1));
      expect(links.first.type, CaptionLinkType.email);
      expect(links.first.value, 'hello@example.com');
    });

    test('finds valid phone numbers', () {
      final links = CaptionLinkUtils.findLinks(
        'Call +1 (555) 123-4567 today.',
      );

      expect(links, hasLength(1));
      expect(links.first.type, CaptionLinkType.phone);
      expect(links.first.value, '+1 (555) 123-4567');
    });

    test('ignores invalid short digit sequences', () {
      final links = CaptionLinkUtils.findLinks('Posted in 2024');

      expect(links, isEmpty);
    });

    test('does not treat mentions as emails', () {
      final links = CaptionLinkUtils.findLinks('@john.doe is here');

      expect(links, isEmpty);
    });

    test('finds compact phone numbers without separators', () {
      final links = CaptionLinkUtils.findLinks('call me at 8976000167');

      expect(links, hasLength(1));
      expect(links.first.type, CaptionLinkType.phone);
      expect(links.first.value, '8976000167');
    });

    test('finds email in mixed caption text', () {
      final links = CaptionLinkUtils.findLinks(
        'call me at 8976000167 email me at appscrip13@yopmail.com',
      );

      expect(links, hasLength(2));
      expect(links[0].type, CaptionLinkType.phone);
      expect(links[1].type, CaptionLinkType.email);
      expect(links[1].value, 'appscrip13@yopmail.com');
    });
  });
}
