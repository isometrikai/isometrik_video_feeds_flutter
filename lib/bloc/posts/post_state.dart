part of 'post_bloc.dart';

abstract class PostState {}

class PostInitial extends PostState {}

class PostDataLoadedState extends PostState {
  PostDataLoadedState({required this.postDataList});

  final List<PostData> postDataList;
}
