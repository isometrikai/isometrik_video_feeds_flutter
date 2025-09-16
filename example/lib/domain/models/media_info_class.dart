import 'package:camera/camera.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class MediaInfoClass {
  MediaInfoClass({
    this.mediaFile,
    this.duration,
    this.mediaType,
    this.mediaSource,
  });

  XFile? mediaFile;
  final int? duration;
  final MediaType? mediaType;
  final MediaSource? mediaSource;
}
