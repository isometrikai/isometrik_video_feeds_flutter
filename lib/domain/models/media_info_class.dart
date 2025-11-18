import 'package:camera/camera.dart';
import 'package:ism_video_reel_player/utils/enums.dart';

class MediaInfoClass {
  MediaInfoClass({
    this.mediaFile,
    this.duration,
    this.mediaType,
    this.mediaSource,
  });

  final XFile? mediaFile;
  final int? duration;
  final MediaType? mediaType;
  final MediaSource? mediaSource;
}
