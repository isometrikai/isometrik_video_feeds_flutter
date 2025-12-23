import 'package:ism_video_reel_player/utils/utils.dart';

class CollectionRequestModel {
  CollectionRequestModel({
    this.collectionIds,
    this.productIds,
    this.action,
    this.collectionName,
  });

  final List<String>? collectionIds;
  final List<String>? productIds;
  final DoActionOnCollection? action;
  final List<String>? collectionName;

  Map<String, dynamic> toJson() => {
        'ids': collectionIds,
        'action': action?.value,
        'productIds': productIds,
      };
}

class CreateCollectionRequestModel {
  CreateCollectionRequestModel({
    this.imageUrl,
    required this.name,
    required this.isPrivate,
    this.description,
  });

  final String? imageUrl;
  final String name;
  final bool isPrivate;
  final String? description;

  // Convert object to JSON
  Map<String, dynamic> toJson() => {
        'image_url': imageUrl,
        'name': name,
        'isPrivate': isPrivate,
        'description': description,
      };
}

class EditCollectionRequestModel {
  EditCollectionRequestModel({
    this.id,
    this.image,
    required this.name,
    required this.isPrivate,
    this.description,
  });

  final String? image;
  final String name;
  final String? id;
  final bool isPrivate;
  final String? description;

  // Convert object to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image!.isEmpty ? null : image,
        'name': name,
        'isPrivate': isPrivate,
        'description': description,
      };
}
