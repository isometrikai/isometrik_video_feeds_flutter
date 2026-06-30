import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/constants/asset_constants.dart';

class ProfilePostsPlaceholder extends StatelessWidget {
  const ProfilePostsPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconWidth = 48,
    this.iconHeight = 48,
    this.showLabels = true,
  });

  final String icon;
  final String title;
  final String subtitle;
  final double iconWidth;
  final double iconHeight;
  final bool showLabels;

  Widget _placeholderIcon(String assetPath) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      final resolved = AssetConstants.resolveAsset(assetPath);
      return AppImage.svg(
        resolved.path,
        height: iconHeight,
        width: iconWidth,
        package: resolved.package,
      );
    }
    return AppImage.asset(assetPath, height: iconHeight, width: iconWidth);
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = const Color(0xFF242424);
    final supportingText = const Color(0xFF979797);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          _placeholderIcon(icon),
          if (showLabels && title.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryText,
              ),
            ),
          ],
          if (showLabels && subtitle.isNotEmpty) ...[
            SizedBox(height: title.isNotEmpty ? 8 : 16),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: supportingText),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
