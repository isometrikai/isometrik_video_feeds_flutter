part of 'create_post_bloc.dart';

abstract class CreatePostEvent {}

class CreatePostInitialEvent extends CreatePostEvent {
  CreatePostInitialEvent({this.isLoading = false});

  final bool? isLoading;
}

class PostCreateEvent extends CreatePostEvent {}

class MediaSourceEvent extends CreatePostEvent {
  MediaSourceEvent({
    required this.context,
    required this.mediaType,
    required this.mediaSource,
    this.isCoverImage = false,
  });

  final BuildContext context;
  final MediaType mediaType;
  final MediaSource mediaSource;
  final bool isCoverImage;
}
