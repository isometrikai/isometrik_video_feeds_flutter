import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';

/// Host-shell touch layer for the strip between the seek bar and tab icons.
///
/// Sits under the transparent [HomeBottomNavigationBar] (non-icon areas pass
/// touches through) so horizontal scrub works in the nav chrome below the bar.
class IsrHostReelsSeekTouchLayer extends StatelessWidget {
  const IsrHostReelsSeekTouchLayer({
    required this.bottomChromeHeight,
    super.key,
  });

  /// Nav content row height plus device safe-area (home indicator).
  final double bottomChromeHeight;

  @override
  Widget build(BuildContext context) {
    if (!IsrVideoReelConfig.seekTouchDelegatedToHost) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: bottomChromeHeight,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) =>
            IsrVideoReelConfig.dispatchReelsSeekPointerDown(event.position),
        onPointerMove: (event) =>
            IsrVideoReelConfig.dispatchReelsSeekPointerMove(event.position),
        onPointerUp: (event) =>
            IsrVideoReelConfig.dispatchReelsSeekPointerUp(event.position),
        onPointerCancel: (_) =>
            IsrVideoReelConfig.dispatchReelsSeekPointerCancel(),
      ),
    );
  }
}
