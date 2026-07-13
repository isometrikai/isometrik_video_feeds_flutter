import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// YouTube-style playback speed picker.
class PlaybackSpeedBottomSheet extends StatelessWidget {
  const PlaybackSpeedBottomSheet({
    super.key,
    this.speeds = VideoPlaybackSpeedController.defaultSpeeds,
  });

  final List<double> speeds;

  static Future<void> show(BuildContext context) async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlaybackSpeedBottomSheet(),
    );
    if (selected != null) {
      VideoPlaybackSpeedController.setSpeed(selected);
    }
  }

  Color get _backgroundColor =>
      IsrVideoReelConfig.socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
      IsrColors.white;

  Color get _textColor => IsrColors.primaryTextColor;

  Color get _selectedColor => IsrColors.appColor;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: IsrDimens.edgeInsetsSymmetric(
                  vertical: IsrDimens.sixteen,
                ),
                child: Text(
                  IsrTranslationFile.playbackSpeed,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ),
              const Divider(height: 1),
              ValueListenableBuilder<double>(
                valueListenable: VideoPlaybackSpeedController.notifier,
                builder: (context, currentSpeed, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final speed in speeds) ...[
                      _buildSpeedOption(
                        context: context,
                        speed: speed,
                        isSelected: (currentSpeed - speed).abs() < 0.001,
                      ),
                      if (speed != speeds.last) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSpeedOption({
    required BuildContext context,
    required double speed,
    required bool isSelected,
  }) {
    final label = speed == 1.0
        ? IsrTranslationFile.normalSpeed
        : VideoPlaybackSpeedController.labelFor(speed);
    return ListTile(
      titleAlignment: ListTileTitleAlignment.center,
      title: Text(
        label,
        textAlign: TextAlign.center,
        style: IsrStyles.primaryText16.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? _selectedColor : _textColor,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: _selectedColor, size: IsrDimens.twenty)
          : const SizedBox(width: 24),
      leading: const SizedBox(width: 24),
      onTap: () => Navigator.pop(context, speed),
    );
  }
}
