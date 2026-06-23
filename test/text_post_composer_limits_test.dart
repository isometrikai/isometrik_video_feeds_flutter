import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/utils/text_post_composer_limits.dart';

void main() {
  group('TextPostComposerLimits', () {
    test('counts lines', () {
      expect(TextPostComposerLimits.lineCount(''), 0);
      expect(TextPostComposerLimits.lineCount('a'), 1);
      expect(TextPostComposerLimits.lineCount('a\nb\nc'), 3);
    });

    test('rejects more than 30 lines for plain posts', () {
      final text = List.filled(31, 'x').join('\n');
      final result =
          TextPostComposerLimits.validate(text, isCard: false);
      expect(result.isValid, isFalse);
      expect(result.issue, TextPostValidationIssue.tooManyLines);
    });

    test('rejects more than 1 consecutive blank line', () {
      const text = 'a\n\n\nb';
      final result =
          TextPostComposerLimits.validate(text, isCard: false);
      expect(result.isValid, isFalse);
      expect(result.issue, TextPostValidationIssue.tooManyBlankLines);
    });

    test('allows one consecutive blank line', () {
      const text = 'a\n\nb';
      final result =
          TextPostComposerLimits.validate(text, isCard: false);
      expect(result.isValid, isTrue);
    });

    test('normalizeForFeedDisplay collapses extra blank lines', () {
      const raw = 'A\n\n\n\nB\n\n\n\nC';
      final normalized = TextPostComposerLimits.normalizeForFeedDisplay(raw);
      expect(normalized, 'A\n\nB\n\nC');
    });

    test('trimIndexForInlineToggle reserves room for ellipsis and toggle', () {
      const style = TextStyle(fontSize: 14, height: 1.3);
      const toggleStyle = TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700);
      const ellipsis = '...';
      const toggleText = ' more';
      final text = List.generate(20, (i) => 'line ${i + 1}').join('\n');
      const maxWidth = 320.0;

      final trimAt = TextPostComposerLimits.trimIndexForInlineToggle(
        text: text,
        bodyStyle: style,
        toggleStyle: toggleStyle,
        ellipsis: ellipsis,
        toggleText: toggleText,
        maxWidth: maxWidth,
        maxLines: TextPostComposerLimits.feedDisplayMaxLines,
      );

      expect(trimAt, lessThan(text.length));
      expect(trimAt, greaterThan(0));

      final painter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: text.substring(0, trimAt), style: style),
            const TextSpan(text: ellipsis, style: style),
            const TextSpan(text: toggleText, style: toggleStyle),
          ],
        ),
        maxLines: TextPostComposerLimits.feedDisplayMaxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      expect(painter.didExceedMaxLines, isFalse);
    });

    test('sanitize trims lines and blank runs on paste', () {
      final pasted = '${'line\n' * 40}';
      final sanitized =
          TextPostComposerLimits.sanitize(pasted, isCard: false);
      expect(
        TextPostComposerLimits.lineCount(sanitized),
        lessThanOrEqualTo(TextPostComposerLimits.plainMaxLines),
      );
      expect(sanitized.length, lessThanOrEqualTo(2000));
    });
  });
}
