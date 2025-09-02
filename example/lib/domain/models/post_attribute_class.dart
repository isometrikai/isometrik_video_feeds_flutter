import 'package:ism_video_reel_player_example/domain/domain.dart';

class PostAttributeClass {
  PostAttributeClass({
    this.price,
    this.caption,
    this.mediaDataList,
    this.allowDownload,
    this.allowComment,
  });

  String? price;
  String? caption;
  List<MediaData>? mediaDataList;
  bool? allowDownload;
  bool? allowComment;
}
