import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class PostItemWidget extends StatefulWidget {
  const PostItemWidget({
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
    this.isCreatePostButtonVisible = false,
    this.startingPostIndex = 0,
    this.onTapUserProfilePic,
    this.loggedInUserId,
    this.allowImplicitScrolling = true,
  });

  final Future<String?> Function()? onCreatePost;
  final Future<dynamic> Function(PostDataModel, String userId)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String, bool)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<List<PostDataModel>> Function(PostSectionType?)? onLoadMore;
  final Future<List<FeaturedProductDataItem>>? Function(String, String)? onTapCartIcon;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final Future<num>? Function(String, int)? onTapComment;
  final Function(String)? onTapShare;
  final Function(String)? onTapUserProfilePic;
  final bool? isCreatePostButtonVisible;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> {
  final _postBloc = IsmInjectionUtils.getBloc<PostBloc>();
  List<PostDataModel> _postList = [];
  var _currentPageIndex = 0;
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    // Check current state
    final currentState = _postBloc.state;
    if (currentState is PostsLoadedState) {
      setState(() {
        _postList = currentState.postsList ?? [];
      });
    }

    _subscription = _postBloc.stream.listen((state) {
      if (state is PostsLoadedState) {
        if (_postList.isEmpty) {
          setState(() {
            _postList = state.postsList ?? [];
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentPageIndex = widget.startingPostIndex ?? 0;
      _currentPageIndex = _currentPageIndex >= _postList.length ? 0 : _currentPageIndex;
      if (_currentPageIndex > 0) {
        _postBloc.reelsPageFollowingController
            .animateToPage(_currentPageIndex, duration: const Duration(milliseconds: 1), curve: Curves.easeIn);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _postList.isListEmptyOrNull == true
      ? _buildPlaceHolder(context)
      : RefreshIndicator(
          onRefresh: () async {
            if (widget.loggedInUserId.isStringEmptyOrNull == true) return;
            if (widget.onRefresh != null) {
              await widget.onRefresh?.call();
            }
          },
          child: _buildContent(context),
        );

  Widget _buildPlaceHolder(BuildContext context) => CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            fillOverscroll: true,
            hasScrollBody: false,
            child: Center(
              child: widget.postSectionType == PostSectionType.trending
                  ? const SizedBox.shrink()
                  : widget.placeHolderWidget ??
                      PostPlaceHolderView(
                        postSectionType: widget.postSectionType,
                        onTap: () {
                          if (widget.onTapPlaceHolder != null) {
                            widget.onTapPlaceHolder!();
                          }
                        },
                      ),
            ),
          ),
        ],
      );

  Widget _buildContent(BuildContext context) => PageView.builder(
        allowImplicitScrolling: widget.allowImplicitScrolling ?? true,
        controller: _postBloc.reelsPageFollowingController,
        clipBehavior: Clip.none,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          debugPrint('FollowingPostWidget ...post list size... ${_postList.length}');
          debugPrint('FollowingPostWidget ...index $index');
          debugPrint(
              'FollowingPostWidget ...Post by ...${_postList[index].userName}\n Post url ${_postList[index].imageUrl1}');
          // Check if we're at 65% of the list
          final threshold = (_postList.length * 0.65).floor();
          if (index >= threshold) {
            if (widget.onLoadMore != null) {
              widget.onLoadMore!(widget.postSectionType).then((value) {
                if (value.isListEmptyOrNull) return;
                if (mounted) {
                  setState(() {
                    // Filter out duplicates based on postId
                    final newPosts = value
                        .where((newPost) => !_postList.any((existingPost) => existingPost.postId == newPost.postId));
                    _postList.addAll(newPosts);
                  });
                }
              });
            }
          }
        },
        itemCount: _postList.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) => IsmReelsVideoPlayerView(
          isCreatePostButtonVisible: widget.isCreatePostButtonVisible,
          thumbnail: _postList[index].thumbnailUrl1 ?? '',
          key: Key(_postList[index].postId ?? ''),
          onCreatePost: () async {
            if (widget.onCreatePost == null) return;
            final postDataModelJsonString = await widget.onCreatePost!();
            if (postDataModelJsonString.isStringEmptyOrNull) return;
            final postDataMap = jsonDecode(postDataModelJsonString!) as Map<String, dynamic>;
            final postDataModel = PostDataModel.fromJson(postDataMap);
            setState(() {
              _postList.insert(0, postDataModel);
            });
          },
          postId: _postList[index].postId,
          description: _postList[index].title ?? '',
          isAssetUploading: false,
          isFollow: _postList[index].followStatus == 1,
          isSelfProfile:
              widget.loggedInUserId.isStringEmptyOrNull == false && widget.loggedInUserId == _postList[index].userId,
          firstName: _postList[index].firstName ?? '',
          lastName: _postList[index].lastName ?? '',
          name: '@${_postList[index].userName ?? ''}',
          hasTags: _postList[index].hashTags ?? [],
          profilePhoto: _postList[index].profilePic ?? '',
          onTapVolume: () {},
          isReelsMuted: false,
          isReelsLongPressed: false,
          onLongPressEnd: () {},
          onDoubleTap: () async {},
          onLongPressStart: () {},
          mediaUrl: _postList[index].imageUrl1 ?? '',
          mediaType: _postList[index].mediaType1?.toInt() ?? 0,
          onTapUserProfilePic: () {
            if (widget.onTapUserProfilePic != null) {
              widget.onTapUserProfilePic!(_postList[index].userId ?? '');
            }
          },
          productCount: _postList[index].productCount?.toInt() ?? 0,
          isSavedPost: _postList[index].isSavedPost,
          onPressMoreButton: () async {
            if (widget.onTapMore == null) return;
            final result = await widget.onTapMore!(_postList[index], _postList[index].userId ?? '');
            if (result == null) return;
            if (result is bool) {
              final isSuccess = result;
              if (isSuccess) {
                setState(() {
                  _postList.removeAt(index);
                });
              }
            }
            if (result is String) {
              final editedPostedData = result;
              if (editedPostedData.isStringEmptyOrNull == false) {
                final postData = PostDataModel.fromJson(jsonDecode(editedPostedData) as Map<String, dynamic>);
                final index = _postList.indexWhere((element) => element.postId == postData.postId);
                if (index != -1) {
                  setState(() {
                    _postList[index] = postData;
                  });
                }
              }
            }
          },
          onPressFollowFollowing: () async {
            if (_postList[index].userId != null) {
              if (widget.onPressFollow == null) return false;
              final isFollow = await widget.onPressFollow!(_postList[index].userId!);

              setState(() {
                _postList[index] = _postList[index].copyWith(followStatus: isFollow ? 1 : 0);
              });
              return isFollow;
            }
            return false;
          },
          onPressSave: () async {
            if (_postList[index].postId != null) {
              if (widget.onPressSave == null) return false;
              final isSaved = await widget.onPressSave!(_postList[index].postId!, _postList[index].isSavedPost == true);

              if (isSaved) {
                setState(() {
                  _postList[index] = _postList[index].copyWith(isSavedPost: _postList[index].isSavedPost == false);
                });
              }
              return isSaved;
            }
            return false;
          },
          isLiked: _postList[index].liked ?? false,
          likesCount: _postList[index].likesCount ?? 0,
          onPressLike: () async {
            if (_postList[index].postId != null) {
              if (widget.onPressLike == null) return false;
              final currentLikeStatus = _postList[index].liked == true;
              final isSuccess = await widget.onPressLike!(
                _postList[index].postId!,
                _postList[index].userId!,
                currentLikeStatus,
              );

              if (isSuccess == false) return false;
              setState(() {
                final newLikesCount = currentLikeStatus
                    ? _postList[index].likesCount?.toInt() == 0
                        ? 0
                        : (_postList[index].likesCount ?? 0) - 1
                    : (_postList[index].likesCount ?? 0) + 1;

                _postList[index] = _postList[index].copyWith(
                  liked: !currentLikeStatus,
                  likesCount: newLikesCount,
                );
              });
              return isSuccess;
            }
            return false;
          },
          onTapCartIcon: () async {
            if (widget.onTapCartIcon != null) {
              final productList = _postList[index].productData;
              final jsonString = jsonEncode(productList?.map((e) => e.toJson()).toList());
              final productDataList = await widget.onTapCartIcon!(jsonString, _postList[index].postId ?? '');
              if (productDataList.isListEmptyOrNull) return;
              setState(() {
                _postList[index] = _postList[index].copyWith(productData: productDataList);
              });
            }
          },
          onTapComment: () async {
            if (widget.onTapComment != null) {
              final newCommentCount = await widget.onTapComment!(
                  _postList[index].postId ?? '', _postList[index].totalComments?.toInt() ?? 0);
              if (newCommentCount != null) {
                setState(() {
                  _postList[index].totalComments = newCommentCount;
                });
              }
            }
          },
          onTapShare: () {
            if (widget.onTapShare != null) {
              widget.onTapShare!(_postList[index].postId ?? '');
            }
          },
          commentCount: _postList[index].totalComments?.toInt() ?? 0,
          isScheduledPost: _postList[index].scheduleTime != null && _postList[index].scheduleTime != 0,
        ),
      );
}
