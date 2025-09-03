import 'package:ism_video_reel_player_example/domain/domain.dart';

class PostAttributeClass {
  PostAttributeClass({
    this.price = 0,
    this.caption = '',
    this.mediaDataList = const [],
    this.allowDownload = false,
    this.allowComment = false,
    this.allowSave = false,
    this.createPostRequest,
  });

  double? price;
  String? caption;
  List<MediaData>? mediaDataList;
  bool? allowDownload;
  bool? allowComment;
  bool? allowSave;
  CreatePostRequest? createPostRequest;
}
