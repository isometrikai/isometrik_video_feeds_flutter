part of 'create_post_bloc.dart';

abstract class CreatePostState {}

class CreatePostInitialState extends CreatePostState {
  CreatePostInitialState({this.isLoading = false});

  final bool? isLoading;
}

class MediaSelectedState extends CreatePostState {
  MediaSelectedState({
    this.mediaDataList,
    this.isPostButtonEnable = false,
  });

  final List<MediaData>? mediaDataList;
  final bool? isPostButtonEnable;
}

class CompressionProgressState extends CreatePostState {
  CompressionProgressState({
    required this.progress,
    required this.mediaKey,
  });

  final double progress;
  final String mediaKey;
}

class UploadingCoverImageState extends CreatePostState {
  // Progress for cover image
  UploadingCoverImageState(this.progress);

  final double progress;
}

class UploadingMediaState extends CreatePostState {
  // Progress for media
  UploadingMediaState(this.progress);

  final double progress;
}

class CoverImageSelected extends CreatePostState {
  CoverImageSelected({
    this.coverImage,
    this.isPostButtonEnable = false,
  });

  final String? coverImage;
  final bool? isPostButtonEnable;
}

class PostCreatedState extends CreatePostState {
  PostCreatedState({
    required this.postDataModel,
    this.postSuccessMessage,
    this.postSuccessTitle,
  });

  final String? postDataModel;
  final String? postSuccessMessage;
  final String? postSuccessTitle;
}

class GetProductsLoadingState extends CreatePostState {
  GetProductsLoadingState({this.isLoading = false});

  final bool? isLoading;
}

class GetProductsState extends CreatePostState {
  GetProductsState({
    required this.productList,
    this.totalProductsCount = 0,
  });

  final List<ProductDataModel>? productList;
  final int? totalProductsCount;
}

class LoadLinkedProductsState extends CreatePostState {
  LoadLinkedProductsState({
    required this.productList,
    this.totalProductsCount = 0,
  });

  final List<ProductDataModel>? productList;
  final int? totalProductsCount;
}

class ShowProgressDialogState extends CreatePostState {
  ShowProgressDialogState({
    this.progress = 0,
    this.title,
    this.subTitle,
  });

  final double? progress;
  final String? title;
  final String? subTitle;
}
