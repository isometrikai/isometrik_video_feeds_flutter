import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

/// Circular avatar with gradient (unviewed) or muted (viewed) story ring.
class StoryRingAvatar extends StatelessWidget {
  const StoryRingAvatar({
    super.key,
    required this.size,
    required this.imageUrl,
    required this.hasUnviewed,
    this.placeholder,
    this.ringWidth = 2.5,
  });

  final double size;
  final String imageUrl;
  final bool hasUnviewed;
  final Widget? placeholder;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    final inner = size - ringWidth * 2;

    Widget avatarChild;
    if (imageUrl.trim().isNotEmpty) {
      avatarChild = AppImage.network(
        imageUrl,
        fit: BoxFit.cover,
        placeHolderWidget: (_, __) => placeholder ?? _defaultPlaceholder(inner),
      );
    } else {
      avatarChild = placeholder ?? _defaultPlaceholder(inner);
    }

    final avatar = ClipOval(
      child: SizedBox(width: inner, height: inner, child: avatarChild),
    );

    if (!hasUnviewed) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.seenRing, width: ringWidth),
        ),
        child: avatar,
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: theme.unseenGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: EdgeInsets.all(1.5.responsiveDimension),
        child: avatar,
      ),
    );
  }

  Widget _defaultPlaceholder(double inner) => ColoredBox(
        color: Colors.grey.shade300,
        child: Icon(Icons.person, size: inner * 0.45, color: Colors.white70),
      );
}
