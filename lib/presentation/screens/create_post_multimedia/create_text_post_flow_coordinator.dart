import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/navigator/ism_page_transition.dart';

/// Coordinates the text-only post creation flow.
abstract final class CreateTextPostFlowCoordinator {
  CreateTextPostFlowCoordinator._();

  static Future<dynamic> run(
    BuildContext context, {
    TransitionType? transitionType,
  }) {
    // Text post compose screen — implement on feature/text_post_feature.
    return Future<dynamic>.value();
  }
}
