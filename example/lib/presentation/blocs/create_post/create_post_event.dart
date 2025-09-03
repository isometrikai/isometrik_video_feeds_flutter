part of 'create_post_bloc.dart';

abstract class CreatePostEvent {}

class CreatePostInitialEvent extends CreatePostEvent {
  CreatePostInitialEvent({this.isLoading = false});

  final bool? isLoading;
}

class PostCreateEvent extends CreatePostEvent {
  PostCreateEvent({
    this.isForEdit = false,
    this.createPostRequest,
  });

  final bool? isForEdit;
  final CreatePostRequest? createPostRequest;
}

class PostAttributeNavigationEvent extends CreatePostEvent {}

class MediaSourceEvent extends CreatePostEvent {
  MediaSourceEvent({
    required this.context,
    required this.mediaType,
    required this.mediaSource,
    this.isCoverImage = false,
    this.mediaData,
  });

  final BuildContext context;
  final MediaType mediaType;
  final MediaSource mediaSource;
  final bool isCoverImage;
  final MediaData? mediaData;
}

class GetProductsEvent extends CreatePostEvent {
  GetProductsEvent({
    this.isFromPagination = false,
  });

  final bool? isFromPagination;
}

class GetSocialPostDetailsEvent extends CreatePostEvent {
  GetSocialPostDetailsEvent({required this.postId});

  final String postId;
}

class EditPostEvent extends CreatePostEvent {
  EditPostEvent({required this.postData});

  final TimeLineData postData;
}

class MediaUploadEvent extends CreatePostEvent {
  MediaUploadEvent({required this.mediaDataList, required this.postId});

  final List<MediaData> mediaDataList;
  final String postId;
}

class MediaProcessingEvent extends CreatePostEvent {
  MediaProcessingEvent({required this.postId});

  final String postId;
}

class RemoveMediaEvent extends CreatePostEvent {
  RemoveMediaEvent({required this.mediaData});

  final MediaData mediaData;
}
