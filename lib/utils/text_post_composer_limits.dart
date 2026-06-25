import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Plain / card text-post limits for compose-time validation and feed display.
abstract final class TextPostComposerLimits {
  static const int plainCharLimit = 2000;
  static const int cardCharLimit = 500;
  static const int plainMaxLines = 30;
  static const int cardMaxLines = 15;
  static const int maxConsecutiveBlankLines = 1;

  /// Collapsed plain-text feed body shows this many rendered lines before "View More".
  static const int feedDisplayMaxLines = 5;

  static TextPostLimitsConfig config({bool isCard = false}) => isCard
      ? const TextPostLimitsConfig(
          charLimit: cardCharLimit,
          maxLines: cardMaxLines,
        )
      : const TextPostLimitsConfig(
          charLimit: plainCharLimit,
          maxLines: plainMaxLines,
        );

  static int lineCount(String text) {
    if (text.isEmpty) return 0;
    return text.split('\n').length;
  }

  static int maxConsecutiveBlankLineRun(String text) {
    if (text.isEmpty) return 0;
    var maxRun = 0;
    var run = 0;
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty) {
        run++;
        if (run > maxRun) maxRun = run;
      } else {
        run = 0;
      }
    }
    return maxRun;
  }

  static TextPostValidationResult validate(
    String text, {
    bool isCard = false,
  }) {
    final limits = config(isCard: isCard);
    if (text.length > limits.charLimit) {
      return TextPostValidationResult.tooManyCharacters(limits.charLimit);
    }
    final lines = lineCount(text);
    if (lines > limits.maxLines) {
      return TextPostValidationResult.tooManyLines(limits.maxLines);
    }
    final blankRun = maxConsecutiveBlankLineRun(text);
    if (blankRun > maxConsecutiveBlankLines) {
      return TextPostValidationResult.tooManyBlankLines(
        maxConsecutiveBlankLines,
      );
    }
    return const TextPostValidationResult.valid();
  }

  /// Truncates pasted / imported text to fit compose limits.
  static String sanitize(String text, {bool isCard = false}) {
    final limits = config(isCard: isCard);
    var next = text;
    if (next.length > limits.charLimit) {
      next = next.substring(0, limits.charLimit);
    }
    next = _collapseExcessBlankLines(next);
    while (lineCount(next) > limits.maxLines && next.contains('\n')) {
      next = next.substring(0, next.lastIndexOf('\n'));
    }
    if (next.length > limits.charLimit) {
      next = next.substring(0, limits.charLimit);
    }
    return next;
  }

  static String _collapseExcessBlankLines(String text) {
    final lines = text.split('\n');
    final out = <String>[];
    var emptyRun = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        emptyRun++;
        if (emptyRun <= maxConsecutiveBlankLines) {
          out.add('');
        }
      } else {
        emptyRun = 0;
        out.add(line);
      }
    }
    return out.join('\n');
  }

  /// Collapses runs of blank lines for feed display (existing posts included).
  static String normalizeForFeedDisplay(String text) =>
      _collapseExcessBlankLines(text);

  /// Layout-measured line count for [text] at [maxWidth] — used for feed collapse.
  static int renderedLineCount({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (text.isEmpty || maxWidth <= 0) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.computeLineMetrics().length;
  }

  static bool exceedsFeedDisplayLines({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.left,
    int maxLines = feedDisplayMaxLines,
  }) =>
      renderedLineCount(
        text: text,
        style: style,
        maxWidth: maxWidth,
        textAlign: textAlign,
      ) >
      maxLines;

  /// Largest prefix of [text] so [ellipsis] (body style) + [toggleText] (toggle
  /// style) can sit inline within [maxLines] — e.g. `lorem... more`.
  static int trimIndexForInlineToggle({
    required String text,
    required TextStyle bodyStyle,
    required TextStyle toggleStyle,
    required String ellipsis,
    required String toggleText,
    required double maxWidth,
    required int maxLines,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (text.isEmpty || maxWidth <= 0) return 0;

    bool fits(int endIndex) {
      final painter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: text.substring(0, endIndex), style: bodyStyle),
            TextSpan(text: ellipsis, style: bodyStyle),
            TextSpan(text: toggleText, style: toggleStyle),
          ],
        ),
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
      )..layout(maxWidth: maxWidth);
      return !painter.didExceedMaxLines;
    }

    if (fits(text.length)) return text.length;

    var low = 0;
    var high = text.length;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Largest prefix of [text] so [suffix] can sit inline within [maxLines].
  static int trimIndexForInlineSuffix({
    required String text,
    required TextStyle bodyStyle,
    required TextStyle suffixStyle,
    required String suffix,
    required double maxWidth,
    required int maxLines,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (text.isEmpty || maxWidth <= 0) return 0;

    bool fits(int endIndex) {
      final painter = TextPainter(
        text: TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: text.substring(0, endIndex)),
            TextSpan(text: suffix, style: suffixStyle),
          ],
        ),
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
      )..layout(maxWidth: maxWidth);
      return !painter.didExceedMaxLines;
    }

    if (fits(text.length)) return text.length;

    var low = 0;
    var high = text.length;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }
}

class TextPostLimitsConfig {
  const TextPostLimitsConfig({
    required this.charLimit,
    required this.maxLines,
  });

  final int charLimit;
  final int maxLines;
}

class TextPostValidationResult {
  const TextPostValidationResult._({
    required this.isValid,
    this.issue,
    this.limit,
  });

  const TextPostValidationResult.valid()
      : this._(isValid: true);

  const TextPostValidationResult.tooManyCharacters(int limit)
      : this._(
          isValid: false,
          issue: TextPostValidationIssue.tooManyCharacters,
          limit: limit,
        );

  const TextPostValidationResult.tooManyLines(int limit)
      : this._(
          isValid: false,
          issue: TextPostValidationIssue.tooManyLines,
          limit: limit,
        );

  const TextPostValidationResult.tooManyBlankLines(int limit)
      : this._(
          isValid: false,
          issue: TextPostValidationIssue.tooManyBlankLines,
          limit: limit,
        );

  final bool isValid;
  final TextPostValidationIssue? issue;
  final int? limit;
}

enum TextPostValidationIssue {
  tooManyCharacters,
  tooManyLines,
  tooManyBlankLines,
}

/// Enforces character, line, and consecutive blank-line limits while typing.
class TextPostComposerInputFormatter extends TextInputFormatter {
  TextPostComposerInputFormatter({required this.isCard});

  final bool isCard;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text == oldValue.text) return newValue;

    final validation =
        TextPostComposerLimits.validate(newValue.text, isCard: isCard);
    if (validation.isValid) return newValue;

    final sanitized = TextPostComposerLimits.sanitize(
      newValue.text,
      isCard: isCard,
    );
    if (sanitized == newValue.text) return newValue;
    if (sanitized == oldValue.text) return oldValue;

    return TextEditingValue(
      text: sanitized,
      selection: _clampSelection(newValue.selection, sanitized.length),
    );
  }

  TextSelection _clampSelection(TextSelection selection, int length) {
    final base = selection.baseOffset.clamp(0, length);
    final extent = selection.extentOffset.clamp(0, length);
    return selection.copyWith(baseOffset: base, extentOffset: extent);
  }
}
