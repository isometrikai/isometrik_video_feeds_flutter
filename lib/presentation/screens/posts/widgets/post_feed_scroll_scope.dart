import 'package:flutter/material.dart';

/// Dismisses an open post-feed overlay menu when the feed scrolls.
class PostFeedOverlayMenuCoordinator {
  PostFeedOverlayMenuCoordinator._();

  static VoidCallback? _dismiss;

  static void register(VoidCallback dismiss) => _dismiss = dismiss;

  static void unregister([VoidCallback? dismiss]) {
    if (dismiss == null || identical(_dismiss, dismiss)) {
      _dismiss = null;
    }
  }

  static void dismissIfOpen() => _dismiss?.call();
}

/// Vertical scroll state for post-card feeds (e.g. lock carousel while scrolling).
class PostFeedScrollScope extends InheritedWidget {
  const PostFeedScrollScope({
    super.key,
    required this.isScrolling,
    required super.child,
  });

  /// True between [ScrollStartNotification] and [ScrollEndNotification].
  final bool isScrolling;

  static PostFeedScrollScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PostFeedScrollScope>();

  @override
  bool updateShouldNotify(PostFeedScrollScope oldWidget) =>
      oldWidget.isScrolling != isScrolling;
}
