import 'package:ism_video_reel_player/domain/domain.dart';

class PostAttributeClass {
  PostAttributeClass({
    this.price = 0,
    this.caption = '',
    this.mediaDataList = const [],
    this.allowDownload = true,
    this.allowComment = true,
    this.allowSave = true,
    this.createPostRequest,
    this.mentionedUserList,
    this.hashTagDataList,
    this.taggedPlaces,
    this.linkedProducts,
  });

  double? price;
  String? caption;
  List<MediaData>? mediaDataList;
  bool? allowDownload;
  bool? allowComment;
  bool? allowSave;
  CreatePostRequest? createPostRequest;
  List<MentionData>? mentionedUserList;
  List<MentionData>? hashTagDataList;
  List<TaggedPlace>? taggedPlaces;
  List<ProductDataModel>? linkedProducts;
}
