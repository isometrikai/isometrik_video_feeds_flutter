import 'dart:io';
import 'dart:typed_data';

import 'package:ism_video_reel_player/export.dart';

class PostAttributeClass {
  PostAttributeClass({
    this.description,
    this.file,
    this.postType,
    this.price,
    this.url,
    this.imageBaseUrl,
    this.thumbnailUrl,
    this.duration,
    this.isCaptionRequired,
    this.videoBytes,
    this.thumbnailBytes,
  });

  File? file;
  String? description;
  String? price;
  String? url;
  String? imageBaseUrl;
  String? thumbnailUrl;
  int? duration;
  bool? isCaptionRequired;
  Uint8List? videoBytes;
  Uint8List? thumbnailBytes;
  PostType? postType;
}
