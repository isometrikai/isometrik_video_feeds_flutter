import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_scroll_scope.dart';

/// Horizontal carousel that yields to the parent vertical feed while the list scrolls.
class PostFeedMediaCarousel extends StatelessWidget {
  const PostFeedMediaCarousel({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onPageChanged,
    required this.itemBuilder,
  });

  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final scope = PostFeedScrollScope.maybeOf(context);
    final listScrolling = scope?.isScrolling ?? false;

    return PageView.builder(
      controller: controller,
      itemCount: itemCount,
      onPageChanged: onPageChanged,
      physics: listScrolling
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      allowImplicitScrolling: false,
      itemBuilder: itemBuilder,
    );
  }
}
