import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Three-step progress indicator for the rejected-post resubmit flow.
///
/// Matches Figma: inactive steps are grey dots, the active step is a blue pill,
/// connectors stay light grey.
///
/// [progressLevel] 1 = Replace, 2 = Review, 3 = Success.
class RejectedPostProgressStepper extends StatelessWidget {
  const RejectedPostProgressStepper({
    super.key,
    required this.primaryColor,
    required this.progressLevel,
  });

  final Color primaryColor;

  /// Current step: 1 replace, 2 review, 3 success.
  final int progressLevel;

  static const Color _inactiveColor = Color(0xFFD1D5DB);
  static const Color _connectorColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final level = progressLevel.clamp(1, 3);
    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twentyFour,
        vertical: IsrDimens.twelve,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStep(level, 1),
            _connector(),
            _buildStep(level, 2),
            _connector(),
            _buildStep(level, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int activeLevel, int step) {
    if (activeLevel == step) {
      return Container(
        width: IsrDimens.twentyEight,
        height: IsrDimens.eight,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(IsrDimens.four),
        ),
      );
    }
    return Container(
      width: IsrDimens.eight,
      height: IsrDimens.eight,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _inactiveColor,
      ),
    );
  }

  Widget _connector() => Container(
        width: IsrDimens.twentyFour,
        height: IsrDimens.two,
        margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.four),
        decoration: BoxDecoration(
          color: _connectorColor,
          borderRadius: BorderRadius.circular(IsrDimens.one),
        ),
      );
}
