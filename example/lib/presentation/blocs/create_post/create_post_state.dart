part of 'create_post_bloc.dart';

abstract class CreatePostState {}

class CreatePostInitialState extends CreatePostState {
  CreatePostInitialState({this.isLoading = false});

  final bool? isLoading;
}

class MediaSelectedState extends CreatePostState {
  MediaSelectedState({
    this.postAttributeClass,
  });
  final PostAttributeClass? postAttributeClass;
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
  });
  final String? coverImage;
}

class PostCreatedState extends CreatePostState {
  PostCreatedState({
    required this.postDataModel,
  });
  final String? postDataModel;
}
