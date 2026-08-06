import 'package:ism_video_reel_player/res/constants/isr_app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

enum CaptionLinkType { email, phone }

class CaptionLinkMatch {
  const CaptionLinkMatch({
    required this.start,
    required this.end,
    required this.type,
    required this.value,
  });

  final int start;
  final int end;
  final CaptionLinkType type;
  final String value;
}

/// Detects valid email addresses and phone numbers in posted caption text.
class CaptionLinkUtils {
  CaptionLinkUtils._();

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?\d{1,4}[\s.-]?)?(?:\(?\d{2,4}\)?[\s.-]?)?\d{2,4}[\s.-]?\d{2,4}(?:[\s.-]?\d{1,4})?',
  );

  static final RegExp _trailingPunctuation = RegExp(r'[.,!?;:]+$');

  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(IsrAppConstants.emailPattern).hasMatch(trimmed);
  }

  static bool isValidPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) return false;

    return RegExp(
      r'^(?:\+?\d{1,4}[\s.-]?)?(?:\(?\d{2,4}\)?[\s.-]?)?\d[\d\s().-]{5,}\d$',
    ).hasMatch(trimmed);
  }

  static List<CaptionLinkMatch> findLinks(String text) {
    if (text.isEmpty) return const [];

    final matches = <CaptionLinkMatch>[];

    for (final match in _emailRegex.allMatches(text)) {
      final value = match.group(0)!;
      if (!isValidEmail(value)) continue;
      matches.add(
        CaptionLinkMatch(
          start: match.start,
          end: match.end,
          type: CaptionLinkType.email,
          value: value,
        ),
      );
    }

    for (final match in _phoneRegex.allMatches(text)) {
      var value = match.group(0)!;
      value = value.replaceAll(_trailingPunctuation, '');
      if (value.isEmpty || !isValidPhone(value)) continue;

      final start = match.start;
      final end = start + value.length;
      if (_overlapsAny(matches, start, end)) continue;

      matches.add(
        CaptionLinkMatch(
          start: start,
          end: end,
          type: CaptionLinkType.phone,
          value: value,
        ),
      );
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }

  static bool _overlapsAny(
    List<CaptionLinkMatch> matches,
    int start,
    int end,
  ) =>
      matches.any(
        (existing) => start < existing.end && end > existing.start,
      );

  static Future<void> launchLink(CaptionLinkType type, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final uris = switch (type) {
      CaptionLinkType.email => [
          Uri(scheme: 'mailto', path: trimmed),
          Uri.parse('mailto:$trimmed'),
        ],
      CaptionLinkType.phone => [
          Uri.parse(
            'tel:${trimmed.replaceAll(RegExp(r'[\s().-]'), '')}',
          ),
        ],
    };

    for (final uri in uris) {
      for (final mode in [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
      ]) {
        try {
          if (await launchUrl(uri, mode: mode)) return;
        } on Object {
          // Try next launch strategy.
        }
      }
    }
  }
}
