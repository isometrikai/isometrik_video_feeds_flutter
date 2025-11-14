import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class PostShimmerView extends StatelessWidget {
  const PostShimmerView({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          padding: IsrDimens.edgeInsets(bottom: context.bottomPadding),
          child: Stack(
            children: [
              // Fullscreen video placeholder
              Positioned.fill(
                child: Container(color: Colors.black),
              ),

              // Right-side shimmer action buttons
              Positioned(
                right: 16,
                bottom: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      4,
                      (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                _shimmerCircle(size: 40), // circle button
                                const SizedBox(height: 6),
                                _shimmerBox(width: 20, height: 8), // small line
                              ],
                            ),
                          )),
                ),
              ),

              // Bottom left profile & text shimmer
              Positioned(
                left: 16,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _shimmerCircle(size: 30),
                        const SizedBox(width: 8),
                        _shimmerBox(width: 200, height: 12),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _shimmerBox(width: 200, height: 12),
                    const SizedBox(height: 8),
                    _shimmerBox(width: 170, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _shimmerCircle({required double size}) => Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _shimmerBox({required double width, required double height}) => Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}
