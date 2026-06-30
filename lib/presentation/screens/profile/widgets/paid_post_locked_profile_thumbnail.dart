import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/response/timeline_response.dart';
import 'package:ism_video_reel_player/presentation/cubits/social_action/social_action_cubit.dart';

bool shouldShowPaidLockedProfileThumbnail({
  required bool? isLocked,
  required String? lockReason,
  required bool? isPaid,
  required String? postUserId,
  String? loggedInUserId,
}) {
  if (isLocked != true) return false;
  final viewerId = (loggedInUserId ?? IsmSocialActionCubit.instance().userId)
      .trim();
  final ownerId = (postUserId ?? '').trim();
  if (viewerId.isNotEmpty && ownerId.isNotEmpty && viewerId == ownerId) {
    return false;
  }
  final reason = (lockReason ?? '').toLowerCase();
  return reason == 'paid' || isPaid == true;
}

bool shouldShowPaidLockedProfileThumbnailForPost(TimeLineData? post) {
  if (post == null) return false;
  return shouldShowPaidLockedProfileThumbnail(
    isLocked: post.isLocked,
    lockReason: post.lockReason,
    isPaid: post.settings?.isPaid,
    postUserId: post.user?.id ?? post.userId,
  );
}

class PaidPostLockedProfileThumbnail extends StatelessWidget {
  const PaidPostLockedProfileThumbnail({
    super.key,
    required this.child,
    required this.isLocked,
    this.iconSize = 22,
    this.blurSigma = 14,
    this.dimColor = const Color(0x66000000),
  });

  final Widget child;
  final bool isLocked;
  final double iconSize;
  final double blurSigma;
  final Color dimColor;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: child,
          ),
        ),
        ColoredBox(color: dimColor),
        Center(
          child: Icon(Icons.lock_outline, color: Colors.white, size: iconSize),
        ),
      ],
    );
  }
}
