import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Shared [Hero] tag for feed media expanding into fullscreen preview.
class FeedPostMediaHero {
  FeedPostMediaHero._();

  static String tag({required String postId, required int mediaIndex}) =>
      'feed_post_media_${postId.trim()}_$mediaIndex';

  static bool isEnabled(String postId) => postId.trim().isNotEmpty;
}

/// Thumbnail shell used for hero flights — must not contain [GlobalKey] children.
class FeedPostVideoHeroShell extends StatelessWidget {
  const FeedPostVideoHeroShell({
    super.key,
    required this.thumbnailUrl,
  });

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailUrl.trim();
    return ColoredBox(
      color: Colors.black,
      child: thumb.isNotEmpty
          ? AppImage.network(
              thumb,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheKey: thumb,
              cacheManager: IsrPostFeedImageCacheManager.instance,
              fadeAnimationEnable: false,
            )
          : const SizedBox.expand(),
    );
  }
}

/// Wraps feed / fullscreen media with a matching hero flight.
class FeedPostMediaHeroScope extends StatelessWidget {
  const FeedPostMediaHeroScope({
    super.key,
    required this.postId,
    required this.mediaIndex,
    required this.child,
    this.enabled = true,
  });

  final String postId;
  final int mediaIndex;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !FeedPostMediaHero.isEnabled(postId)) {
      return child;
    }

    return Hero(
      tag: FeedPostMediaHero.tag(postId: postId, mediaIndex: mediaIndex),
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final sourceHero = flightDirection == HeroFlightDirection.push
            ? fromHeroContext.widget as Hero
            : toHeroContext.widget as Hero;
        return Material(
          type: MaterialType.transparency,
          child: sourceHero.child,
        );
      },
      placeholderBuilder: (_, __, child) => child,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
