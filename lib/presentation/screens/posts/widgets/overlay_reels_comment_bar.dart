import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Instagram-style comment composer pinned to the bottom of overlay reels
/// (Explore, Profile, notifications, etc.) so the seek bar sits above the
/// system home / recents gesture zone.
///
/// Always uses a dark opaque chrome regardless of host app theme.
class OverlayReelsCommentBar extends StatelessWidget {
  const OverlayReelsCommentBar({
    required this.onTap,
    super.key,
  });

  static const double contentHeight = 44;
  static const double topPadding = 8;
  static const Color _chromeColor = Color(0xFF000000);
  static const Color _inputFillColor = Color(0xFF262626);

  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + contentHeight + topPadding;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const hintText = IsrTranslationFile.addAComment;
    const borderRadius = 22.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ColoredBox(
        color: _chromeColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              IsrDimens.twelve,
              topPadding,
              IsrDimens.twelve,
              0,
            ),
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: contentHeight,
                alignment: Alignment.centerLeft,
                padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.sixteen,
                ),
                decoration: BoxDecoration(
                  color: _inputFillColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: const Text(
                  hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
