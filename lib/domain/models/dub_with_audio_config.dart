import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/models/response/response.dart';

class DubWithAudioConfig {
  const DubWithAudioConfig({
    this.canStart,
    this.onLockedPost,
  });

  final Future<bool> Function(BuildContext context, TimeLineData post)?
      canStart;

  final void Function(BuildContext context, TimeLineData post)? onLockedPost;
}
