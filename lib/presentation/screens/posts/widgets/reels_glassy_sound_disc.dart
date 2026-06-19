import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/tap_handler.dart';
import 'package:ism_video_reel_player/res/constants/asset_constants.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

/// Instagram-style spinning sound disc for glassy reels (bottom-right).
class ReelsGlassySoundDisc extends StatefulWidget {
  const ReelsGlassySoundDisc({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.size = 24,
    this.spin = true,
  });

  final String imageUrl;
  final VoidCallback onTap;
  final double size;
  final bool spin;

  @override
  State<ReelsGlassySoundDisc> createState() => _ReelsGlassySoundDiscState();
}

class _ReelsGlassySoundDiscState extends State<ReelsGlassySoundDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant ReelsGlassySoundDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spin != widget.spin) {
      _syncSpin();
    }
  }

  void _syncSpin() {
    if (widget.spin) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
    } else {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final imageUrl = widget.imageUrl.trim();
    final hasArtwork = imageUrl.isNotEmpty;

    final discContent = hasArtwork
        ? AppImage.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
          )
        : Image.asset(
            AssetConstants.icGlassyReelsSoundDisc,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );

    return TapHandler(
      onTap: widget.onTap,
      borderRadius: size / 2,
      child: RotationTransition(
        turns: _spinController,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: hasArtwork
                ? Border.all(
                    color: IsrColors.white,
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.changeOpacity(0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: discContent),
        ),
      ),
    );
  }
}
