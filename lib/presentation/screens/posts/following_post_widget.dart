import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class FollowingPostWidget extends StatefulWidget {
  const FollowingPostWidget({super.key});

  @override
  State<FollowingPostWidget> createState() => _FollowingPostWidgetState();
}

class _FollowingPostWidgetState extends State<FollowingPostWidget> {
  final _postBloc = isrGetIt<PostBloc>();
  List<PostData> _followingPostList = [];

  @override
  Widget build(BuildContext context) => BlocBuilder<PostBloc, PostState>(
        buildWhen: (previousState, currentState) => currentState is PostDataLoadedState,
        builder: (context, state) {
          if (state is PostDataLoadedState && state.postDataList.isEmptyOrNull == false) {
            _followingPostList = state.postDataList;
          }
          return state is PostDataLoadedState && state.postDataList.isEmptyOrNull == false
              ? RefreshIndicator(
                  onRefresh: () async {
                    _postBloc.add(GetFollowingPostEvent(isLoading: false, isPagination: false));
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
                        _postBloc.add(GetFollowingPostEvent(
                          isLoading: false,
                          isPagination: true,
                        ));
                      }
                    },
                    itemCount: _followingPostList.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) => IsrReelsVideoPlayerView(
                      thumbnail: _followingPostList[index].thumbnailUrl1 ?? '',
                      key: Key(_followingPostList[index].postId ?? ''),
                      onCreatePost: () async {},
                      postId: _followingPostList[index].postId,
                      description: '',
                      isAssetUploading: false,
                      isFollow: _followingPostList[index].followStatus == 1,
                      isSelfProfile: false,
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
                      onPressFollowFollowing: () async {
                        if (_followingPostList[index].userId != null) {
                          try {
                            final completer = Completer<bool>();

                            _postBloc.add(FollowUserEvent(
                              followingId: _followingPostList[index].userId!,
                              onComplete: (success) {
                                if (success) {
                                  setState(() {
                                    _followingPostList[index] = _followingPostList[index].copyWith(
                                      followStatus: 1,
                                    );
                                  });
                                }
                                completer.complete(success);
                              },
                            ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        }
                        return false;
                      },
                      onPressSave: () async {
                        if (_followingPostList[index].postId != null) {
                          try {
                            final completer = Completer<bool>();

                            _postBloc.add(SavePostEvent(
                              postId: _followingPostList[index].postId!,
                              onComplete: (success) {
                                if (success) {
                                  setState(() {
                                    _followingPostList[index] = _followingPostList[index].copyWith(
                                      isSavedPost: true,
                                    );
                                  });
                                }
                                completer.complete(success);
                              },
                            ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        }
                        return false;
                      },
                      isLiked: _followingPostList[index].liked ?? false,
                      likesCount: _followingPostList[index].likesCount ?? 0,
                      onPressLike: () async {
                        if (_followingPostList[index].postId != null) {
                          try {
                            final completer = Completer<bool>();

                            _postBloc.add(LikePostEvent(
                              postId: _followingPostList[index].postId!,
                              userId: _followingPostList[index].userId!,
                              likeAction: _followingPostList[index].liked == true ? LikeAction.unlike : LikeAction.like,
                              onComplete: (success) {
                                if (success) {
                                  setState(() {
                                    _followingPostList[index] = _followingPostList[index].copyWith(
                                      liked: !(_followingPostList[index].liked ?? false),
                                      likesCount: (_followingPostList[index].liked ?? false)
                                          ? (_followingPostList[index].likesCount ?? 0) - 1
                                          : (_followingPostList[index].likesCount ?? 0) + 1,
                                    );
                                  });
                                }
                                completer.complete(success);
                              },
                            ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
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
