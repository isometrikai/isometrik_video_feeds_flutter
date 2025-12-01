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
    this.mediaDataList,
  });

  final String? postDataModel;
  final String? postSuccessMessage;
  final String? postSuccessTitle;
  final List<MediaData>? mediaDataList;
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
    this.currentFileIndex = 0,
    this.totalFiles = 0,
    this.currentFileName = '',
    this.isAllFilesUploaded = false,
  });

  final double? progress;
  final String? title;
  final String? subTitle;
  final int currentFileIndex;
  final int totalFiles;
  final String currentFileName;
  final bool isAllFilesUploaded;
}

class MentionedUsersUpdatedState extends CreatePostState {
  MentionedUsersUpdatedState({
    required this.mentionedUsers,
    required this.hashTags,
    required this.locationTags,
  });

  final List<MentionData> mentionedUsers;
  final List<MentionData> hashTags;
  final List<TaggedPlace> locationTags;
}

class PostAttributionUpdatedState extends CreatePostState {
  PostAttributionUpdatedState({
    this.postAttributeClass,
  });

  final PostAttributeClass? postAttributeClass;
}
