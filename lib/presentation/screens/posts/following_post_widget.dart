import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class FollowingPostWidget extends StatefulWidget {
  const FollowingPostWidget({
    super.key,
    this.onCreatePost,
    this.showBlur,
    this.productList,
    this.onPressSave,
    this.onPressLike,
    this.onTapMore,
    this.onPressFollow,
    this.onLoadMore,
  });

  final Future<String?> Function()? onCreatePost;
  final Future<bool> Function(String postId)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<List<PostDataModel>> Function()? onLoadMore;

  @override
  State<FollowingPostWidget> createState() => _FollowingPostWidgetState();
}

class _FollowingPostWidgetState extends State<FollowingPostWidget> {
  final _postBloc = IsmInjectionUtils.getBloc<PostBloc>();
  List<PostDataModel> _followingPostList = [];

  @override
  Widget build(BuildContext context) => BlocBuilder<PostBloc, PostState>(
        buildWhen: (previousState, currentState) => currentState is FollowingPostsLoadedState,
        builder: (context, state) {
          if (state is FollowingPostsLoadedState) {
            _followingPostList = state.followingPosts ?? [];
          } else if (state is SavePostSuccessState) {
            // ... handle save state
          } else if (state is FollowSuccessState) {
            // ... handle follow state
          } else if (state is LikeSuccessState) {
            // ... handle like state
          }

          return _followingPostList.isEmptyOrNull == false
              ? RefreshIndicator(
                  onRefresh: () async {
                    // _postBloc.add(GetFollowingPostEvent(isLoading: false, isPagination: false));
                  },
                  child: PageView.builder(
                    allowImplicitScrolling: true,
                    controller: _postBloc.reelsPageFollowingController,
                    clipBehavior: Clip.none,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      // Check if we're at 75% of the list
                      final threshold = (_followingPostList.length * 0.75).floor();
                      if (index >= threshold) {
                        // _postBloc.add(GetFollowingPostEvent(
                        //   isLoading: false,
                        //   isPagination: true,
                        // ));
                      }
                    },
                    itemCount: _followingPostList.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) => IsrReelsVideoPlayerView(
                      thumbnail: _followingPostList[index].thumbnailUrl1 ?? '',
                      key: Key(_followingPostList[index].postId ?? ''),
                      onCreatePost: () async {
                        if (widget.onCreatePost == null) return;
                        final postDataModelJsonString = await widget.onCreatePost!();
                        if (postDataModelJsonString.isEmptyOrNull) return;
                        final postDataModel = PostDataModel.fromJson(postDataModelJsonString as Map<String, dynamic>);
                        _followingPostList.insert(0, postDataModel);
                        _postBloc.add(FollowingPostsLoadedEvent(_followingPostList));
                      },
                      postId: _followingPostList[index].postId,
                      description: '',
                      isAssetUploading: false,
                      isFollow: _followingPostList[index].followStatus == 1,
                      isSelfProfile: false,
                      firstName: _followingPostList[index].firstName ?? '',
                      lastName: _followingPostList[index].lastName ?? '',
                      name: '@${_followingPostList[index].userName ?? ''}',
                      hasTags: _followingPostList[index].hashTags ?? [],
                      profilePhoto: _followingPostList[index].profilePic ?? '',
                      onTapVolume: () {},
                      isReelsMuted: false,
                      isReelsLongPressed: false,
                      onLongPressEnd: () {},
                      onDoubleTap: () async {},
                      onLongPressStart: () {},
                      mediaUrl: _followingPostList[index].imageUrl1 ?? '',
                      mediaType: _followingPostList[index].mediaType1?.toInt() ?? 0,
                      onTapUserProfilePic: () => {},
                      productList: _followingPostList[index].productData,
                      isSavedPost: _followingPostList[index].isSavedPost,
                      onPressMoreButton: () async {
                        if (widget.onTapMore == null) return false;
                        return await widget.onTapMore!(_followingPostList[index].postId!);
                      },
                      onPressFollowFollowing: () async {
                        if (_followingPostList[index].userId != null) {
                          if (widget.onPressFollow == null) return false;
                          final isFollow = await widget.onPressFollow!(_followingPostList[index].userId!);

                          setState(() {
                            _followingPostList[index] =
                                _followingPostList[index].copyWith(followStatus: isFollow ? 1 : 0);
                          });
                          return isFollow;
                        }
                        return false;
                      },
                      onPressSave: () async {
                        if (_followingPostList[index].postId != null) {
                          if (widget.onPressSave == null) return false;
                          final isSaved = await widget.onPressSave!(_followingPostList[index].postId!);

                          setState(() {
                            _followingPostList[index] = _followingPostList[index].copyWith(isSavedPost: isSaved);
                          });
                          return isSaved;
                        }
                        return false;
                      },
                      isLiked: _followingPostList[index].liked ?? false,
                      likesCount: _followingPostList[index].likesCount ?? 0,
                      onPressLike: () async {
                        if (_followingPostList[index].postId != null) {
                          if (widget.onPressLike == null) return false;
                          final isLiked = await widget.onPressLike!(
                            _followingPostList[index].postId!,
                            _followingPostList[index].userId!,
                            _followingPostList[index].liked == true,
                          );

                          setState(() {
                            _followingPostList[index] = _followingPostList[index].copyWith(liked: isLiked);
                          });
                          return isLiked;
                        }
                        return false;
                      },
                    ),
                  ),
                )
              : const PostPlaceHolderView(
                  postSectionType: PostSectionType.following,
                );
        },
      );
}
