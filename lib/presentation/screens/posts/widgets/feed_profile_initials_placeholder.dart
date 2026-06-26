import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Circular initials avatar when the user has no profile photo.
///
/// Uses opaque theme colors that match the host profile screen in both light
/// and dark mode (not translucent, so reels/location overlays look identical).
class FeedProfileInitialsPlaceholder extends StatelessWidget {
  const FeedProfileInitialsPlaceholder({
    super.key,
    required this.initials,
    required this.size,
    this.seed,
  });

  final String initials;
  final double size;

  /// Kept for API compatibility; color is always theme-based.
  final String? seed;

  @override
  Widget build(BuildContext context) {
    final display = initials.trim().toUpperCase();
    if (display.isEmpty) {
      return SizedBox(width: size, height: size);
    }

    final backgroundColor = IsrColors.profileInitialsBackground;
    final foregroundColor = IsrColors.profileInitialsForeground;
    final fontSize = (size * 0.38).clamp(11.0, 18.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
          letterSpacing: -0.4,
          height: 1,
        ),
      ),
    );
  }
}
