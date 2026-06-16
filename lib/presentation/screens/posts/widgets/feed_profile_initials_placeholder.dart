import 'package:flutter/material.dart';

/// Deterministic accent colors for profile initials placeholders.
class FeedProfileInitialsPalette {
  FeedProfileInitialsPalette._();

  static const _colors = <Color>[
    Color(0xFF5856D6),
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFFFF2D55),
    Color(0xFF00C7BE),
    Color(0xFF5AC8FA),
  ];

  static Color colorFor(String seed) {
    final normalized = seed.trim().toUpperCase();
    if (normalized.isEmpty) return _colors.first;
    final hash = normalized.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _colors[hash % _colors.length];
  }
}

/// Attractive circular initials avatar when the user has no profile photo.
class FeedProfileInitialsPlaceholder extends StatelessWidget {
  const FeedProfileInitialsPlaceholder({
    super.key,
    required this.initials,
    required this.size,
    this.seed,
  });

  final String initials;
  final double size;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    final display = initials.trim().toUpperCase();
    if (display.isEmpty) {
      return SizedBox(width: size, height: size);
    }

    final base = FeedProfileInitialsPalette.colorFor(seed ?? display);
    final fontSize = (size * 0.38).clamp(11.0, 18.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            Color.lerp(base, Colors.black, 0.18) ?? base,
          ],
        ),
      ),
      child: Center(
        child: Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
      ),
    );
  }
}
