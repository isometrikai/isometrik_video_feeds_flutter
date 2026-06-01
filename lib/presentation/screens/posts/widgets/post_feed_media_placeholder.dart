import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Instagram-style shimmer while post-feed images load.
class PostFeedMediaPlaceholder extends StatelessWidget {
  const PostFeedMediaPlaceholder({
    super.key,
    this.baseColor = const Color(0xFFEFEFEF),
    this.highlightColor = const Color(0xFFF7F7F7),
  });

  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ColoredBox(color: baseColor),
      );
}
