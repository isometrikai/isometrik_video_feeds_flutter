import 'package:flutter/material.dart';

/// Keeps an off-screen carousel page alive so video players are not recreated on swipe.
class PostFeedCarouselKeepAlivePage extends StatefulWidget {
  const PostFeedCarouselKeepAlivePage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<PostFeedCarouselKeepAlivePage> createState() =>
      _PostFeedCarouselKeepAlivePageState();
}

class _PostFeedCarouselKeepAlivePageState extends State<PostFeedCarouselKeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
