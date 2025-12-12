part of 'collection_bloc.dart';

abstract class CollectionEvent {}

class CollectionInitEvent extends CollectionEvent {}

class GetUserCollectionEvent extends CollectionEvent {
  GetUserCollectionEvent({
    required this.skip,
    required this.limit,
  });
  final int skip;
  final int limit;
}

class CreateUserCollectionEvent extends CollectionEvent {
  CreateUserCollectionEvent({
    required this.createCollectionRequestModel,
  });
  final CreateCollectionRequestModel createCollectionRequestModel;
}

class ModifyUserCollectionEvent extends CollectionEvent {
  ModifyUserCollectionEvent({
    required this.collectionRequestModel,
    this.collectionId = '',
    this.isPost = false,
  });
  final CollectionRequestModel collectionRequestModel;
  final String collectionId;
  final bool isPost;
}

class MoveToCollectionEvent extends CollectionEvent {
  MoveToCollectionEvent({
    this.collectionId = '',
    this.postId = '',
    this.onMoveToCollection,
  });
  final String collectionId;
  final String postId;
  final VoidCallback? onMoveToCollection;
}

class EditUserCollectionEvent extends CollectionEvent {
  EditUserCollectionEvent(this.editedCollectionRequestModel, this.collectionId);
  final EditCollectionRequestModel editedCollectionRequestModel;
  final String collectionId;
}

class CollectionImageUploadEvent extends CollectionEvent {
  CollectionImageUploadEvent({required this.imageSource});
  final ImageSource? imageSource;
}

class CollectionImageRemoveEvent extends CollectionEvent {}

class GetSavedPostEvent extends CollectionEvent {
  GetSavedPostEvent({
    required this.skip,
    required this.limit,
  });
  final int skip;
  final int limit;
}

class SavePostActionEvent extends CollectionEvent {
  SavePostActionEvent({
    required this.postId,
    // required this.onComplete,
    required this.isSaved,
  });

  final String postId;
  // final Function(bool) onComplete;
  final bool isSaved;
}

class SaveCollectionPostEvent extends CollectionEvent {
  SaveCollectionPostEvent({
    required this.postId,
    this.completer,
  });
  final String postId;
  final Completer<void>? completer;
}

class GetWishlistProductsEvent extends CollectionEvent {
  GetWishlistProductsEvent();
}

/// Event to get posts in a collection by collectionId
class GetCollectionPostsEvent extends CollectionEvent {
  GetCollectionPostsEvent({
    required this.collectionId,
    required this.page,
    required this.pageSize,
  });

  final String collectionId;
  final int page;
  final int pageSize;
}

/// Event to delete a collection
class DeleteCollectionEvent extends CollectionEvent {
  DeleteCollectionEvent({required this.collectionId});

  final String collectionId;
}

/// Event to remove a post from collection
class RemovePostFromCollectionEvent extends CollectionEvent {
  RemovePostFromCollectionEvent({
    required this.collectionId,
    required this.postId,
  });

  final String collectionId;
  final String postId;
}
