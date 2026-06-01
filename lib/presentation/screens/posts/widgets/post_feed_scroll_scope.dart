import 'package:flutter/material.dart';

/// Scroll state for post-card feeds: defers heavy media work while the list moves.
class PostFeedScrollScope extends InheritedWidget {
  const PostFeedScrollScope({
    super.key,
    required this.isScrolling,
    required super.child,
  });

  /// True between [ScrollStartNotification] and [ScrollEndNotification].
  final bool isScrolling;

  /// Video init/playback should run only when the list is idle.
  bool get allowHeavyMedia => !isScrolling;

  static PostFeedScrollScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PostFeedScrollScope>();

  @override
  bool updateShouldNotify(PostFeedScrollScope oldWidget) =>
      oldWidget.isScrolling != isScrolling;
}
