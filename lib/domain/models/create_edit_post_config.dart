import 'package:ism_video_reel_player/domain/domain.dart';

class CreateEditPostConfig {
  const CreateEditPostConfig({
    this.createEditPostCallBackConfig,
    this.createEditPostUIConfig,
    this.autoMoveToNextPost = true,
  });

  final CreateEditPostCallBackConfig? createEditPostCallBackConfig;
  final CreateEditPostUIConfig? createEditPostUIConfig;
  final bool autoMoveToNextPost;

  CreateEditPostConfig copyWith({
    CreateEditPostCallBackConfig? createEditPostCallBackConfig,
    CreateEditPostUIConfig? createEditPostUIConfig,
  }) =>
      CreateEditPostConfig(
        createEditPostCallBackConfig:
            createEditPostCallBackConfig ?? this.createEditPostCallBackConfig,
        createEditPostUIConfig:
            createEditPostUIConfig ?? this.createEditPostUIConfig,
      );
}

class CreateEditPostUIConfig {
  const CreateEditPostUIConfig();

  CreateEditPostUIConfig copyWith() => const CreateEditPostUIConfig();
}

class CreateEditPostCallBackConfig {
  const CreateEditPostCallBackConfig({this.onLinkProduct});

  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
      onLinkProduct;

  CreateEditPostCallBackConfig copyWith(
          {Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
              onLinkProduct}) =>
      CreateEditPostCallBackConfig(
        onLinkProduct: onLinkProduct ?? this.onLinkProduct,
      );
}
