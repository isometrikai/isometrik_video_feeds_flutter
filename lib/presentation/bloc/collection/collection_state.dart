part of 'collection_bloc.dart';

abstract class CollectionState {}

class CollectionInitState extends CollectionState {}

class UserCollectionLoadingState extends CollectionState {}

class UserCollectionFetchState extends CollectionState {
  UserCollectionFetchState({required this.collectionList});

  final List<CollectionData> collectionList;
}

class ModifyUserCollectionLoadingState extends CollectionState {}

class ModifyUserCollectionSuccessState extends CollectionState {
  ModifyUserCollectionSuccessState({
    required this.action,
    required this.collectionNames,
    this.isPost = false,
  });

  final DoActionOnCollection? action;
  final List<String> collectionNames;
  final bool isPost;
}

class CreateCollectionLoadingState extends CollectionState {}

class CreateCollectionSuccessState extends CollectionState {
  CreateCollectionSuccessState({
    required this.message,
    required this.collectionId,
  });

  final String message;
  final String collectionId;
}

class CreateCollectionErrorState extends CollectionState {
  CreateCollectionErrorState(this.error);

  final String error;
}

class EditCollectionLoadingState extends CollectionState {}

class EditCollectionSuccessState extends CollectionState {
  EditCollectionSuccessState({
    required this.message,
    required this.editCollectionRequestModel,
  });

  final String message;
  final EditCollectionRequestModel editCollectionRequestModel;
}

class EditCollectionErrorState extends CollectionState {
  EditCollectionErrorState(this.error);

  final String error;
}

class CollectionImageLoadingState extends CollectionState {}

class CollectionImageUpdateSuccessState extends CollectionState {
  CollectionImageUpdateSuccessState({
    required this.imageString,
    required this.localFile,
  });

  final String imageString;
  final File localFile;
}

class SavedPostDataLoadingState extends CollectionState {}

class SavedPostDataSuccessState extends CollectionState {
  SavedPostDataSuccessState({
    this.totalPosts = 0,
    this.profilePic = '',
  });

  final num totalPosts;
  final String profilePic;
}

//Error

class UserCollectionErrorState extends CollectionState {
  UserCollectionErrorState(this.error);

  final String error;
}

class ModifyUserCollectionErrorState extends CollectionState {
  ModifyUserCollectionErrorState(this.error);

  final String error;
}

class CollectionImageUpdateErrorState extends CollectionState {
  CollectionImageUpdateErrorState(this.error);

  final String error;
}

class SavePostLoadingState extends CollectionState {
  SavePostLoadingState({
    required this.postId,
  });
  final String postId;
}

class SavePostSuccessState extends CollectionState {
  SavePostSuccessState({
    required this.postId,
    required this.socialPostAction,
  });
  final String postId;
  final SocialPostAction socialPostAction;
}

class SavePostErrorState extends CollectionState {
  SavePostErrorState({required this.message});
  final String message;
}

class SavedPostDataErrorState extends CollectionState {}

// Collection Posts States
class GetCollectionPostsLoadingState extends CollectionState {}

class GetCollectionPostsSuccessState extends CollectionState {
  GetCollectionPostsSuccessState({
    required this.posts,
    required this.totalPosts,
  });

  final List<TimeLineData> posts;
  final int totalPosts;
}

class GetCollectionPostsErrorState extends CollectionState {
  GetCollectionPostsErrorState({required this.error});

  final String error;
}

// Delete Collection States
class DeleteCollectionLoadingState extends CollectionState {}

class DeleteCollectionSuccessState extends CollectionState {
  DeleteCollectionSuccessState({required this.message});

  final String message;
}

class DeleteCollectionErrorState extends CollectionState {
  DeleteCollectionErrorState({required this.error});

  final String error;
}

// Remove Post From Collection States
class RemovePostFromCollectionLoadingState extends CollectionState {}

class RemovePostFromCollectionSuccessState extends CollectionState {
  RemovePostFromCollectionSuccessState({required this.postId});

  final String postId;
}

class RemovePostFromCollectionErrorState extends CollectionState {
  RemovePostFromCollectionErrorState({required this.error});

  final String error;
}
