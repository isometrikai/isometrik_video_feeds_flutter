import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

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
    this.onTapCartIcon,
    this.onRefresh,
    this.placeHolderWidget,
    this.postSectionType,
    this.onTapPlaceHolder,
    this.onTapShare,
    this.onTapComment,
  });

  final Future<String?> Function()? onCreatePost;
  final Future<bool> Function(String postId)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<List<PostDataModel>> Function()? onLoadMore;
  final Function(String)? onTapCartIcon;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final Function(String)? onTapComment;
  final Function(String)? onTapShare;

  @override
  State<FollowingPostWidget> createState() => _FollowingPostWidgetState();
}

class _FollowingPostWidgetState extends State<FollowingPostWidget> {
  final _postBloc = IsmInjectionUtils.getBloc<PostBloc>();
  List<PostDataModel> _followingPostList = [];

  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();

    // Check current state
    final currentState = _postBloc.state;
    if (currentState is FollowingPostsLoadedState) {
      setState(() {
        _followingPostList = currentState.followingPosts ?? [];
      });
    }

    _subscription = _postBloc.stream.listen((state) {
      if (state is FollowingPostsLoadedState) {
        if (_followingPostList.isEmpty) {
          setState(() {
            _followingPostList = state.followingPosts ?? [];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            await widget.onRefresh?.call();
          }
        },
        child: _followingPostList.isListEmptyOrNull == true
            ? Center(
                child: widget.placeHolderWidget ??
                    PostPlaceHolderView(
                      postSectionType: widget.postSectionType,
                      onTap: () {
                        if (widget.onTapPlaceHolder != null) {
                          widget.onTapPlaceHolder!();
                        }
                      },
                    ),
              )
            : PageView.builder(
                allowImplicitScrolling: true,
                controller: _postBloc.reelsPageFollowingController,
                clipBehavior: Clip.none,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  // Check if we're at 75% of the list
                  final threshold = (_followingPostList.length * 0.65).floor();
                  if (index >= threshold) {
                    if (widget.onLoadMore != null) {
                      widget.onLoadMore!().then((value) {
                        if (value.isListEmptyOrNull) return;
                        if (mounted) {
                          setState(() {
                            // Filter out duplicates based on postId
                            final newPosts = value.where((newPost) =>
                                !_followingPostList.any((existingPost) => existingPost.postId == newPost.postId));
                            _followingPostList.addAll(newPosts);
                          });
                        }
                      });
                    }
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
                    if (postDataModelJsonString.isStringEmptyOrNull) return;
                    final postDataMap = jsonDecode(postDataModelJsonString!) as Map<String, dynamic>;
                    final postDataModel = PostDataModel.fromJson(postDataMap);
                    setState(() {
                      _followingPostList.insert(0, postDataModel);
                    });
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
                        _followingPostList[index] = _followingPostList[index].copyWith(followStatus: isFollow ? 1 : 0);
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
                  onTapCartIcon: () {
                    if (widget.onTapCartIcon != null) {
                      final productList = _followingPostList[index].productData;
                      final jsonString = jsonEncode(productList?.map((e) => e.toJson()).toList());
                      widget.onTapCartIcon!(jsonString);
                    }
                  },
                  onTapComment: () {
                    if (widget.onTapComment != null) {
                      widget.onTapComment!(_followingPostList[index].postId ?? '');
                    }
                  },
                  onTapShare: () {
                    if (widget.onTapShare != null) {
                      widget.onTapShare!(_followingPostList[index].postId ?? '');
                    }
                  },
                  commentCount: _followingPostList[index].commentCount?.toInt() ?? 0,
                ),
              ),
      );
}
