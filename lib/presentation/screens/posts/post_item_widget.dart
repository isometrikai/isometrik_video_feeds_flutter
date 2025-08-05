import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    this.onPageChanged,
  });

  final Future<String?> Function()? onCreatePost;
  final Future<dynamic> Function(PostDataModel, String userId)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String, bool)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<List<TimeLineData>> Function(PostSectionType?)? onLoadMore;
  final void Function(String)? onTapCartIcon;
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
  final Function(int)? onPageChanged;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> {
  final _postBloc = IsmInjectionUtils.getBloc<PostBloc>();

  // List<PostDataModel> _postList = [];
  List<TimeLineData> _postList = [];
  StreamSubscription<dynamic>? _subscription;
  late PageController _pageController;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _pageController = PageController(initialPage: widget.startingPostIndex ?? 0);

    // Check current state
    final currentState = _postBloc.state;
    if (currentState is PostsLoadedState) {
      final postList = currentState.timeLinePostList ?? [];
      _precacheImages(postList);
      setState(() {
        _postList = postList;
      });
    }

    _subscription = _postBloc.stream.listen((state) {
      if (state is PostsLoadedState) {
        if (_postList.isEmpty) {
          final postList = state.timeLinePostList ?? [];
          _precacheImages(postList);
          setState(() {
            _postList = postList;
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetPage = _pageController.initialPage >= _postList.length
          ? _postList.length - 1
          : _pageController.initialPage;
      if (targetPage > 0) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 1),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        controller: _pageController,
        clipBehavior: Clip.none,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          debugPrint('page index: $index');
          // Check if we're at 65% of the list
          final threshold = (_postList.length * 0.65).floor();
          if (index >= threshold) {
            if (widget.onLoadMore != null) {
              widget.onLoadMore!(widget.postSectionType).then((value) {
                if (value.isListEmptyOrNull) return;
                if (mounted) {
                  setState(() {
                    // Filter out duplicates based on postId
                    final newPosts = value.where((newPost) =>
                        !_postList.any((existingPost) => existingPost.id == newPost.id));
                    _postList.addAll(newPosts);
                    // _precacheImages(newPosts as List<TimeLineData>);
                  });
                }
              });
            }
          }
          if (widget.onPageChanged != null) widget.onPageChanged!(index);
        },
        itemCount: _postList.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) => IsmReelsVideoPlayerView(
          isFirstPost: widget.startingPostIndex == index,
          isCreatePostButtonVisible: widget.isCreatePostButtonVisible,
          thumbnail: _postList[index].media?.first.previewUrl ?? '',
          key: Key(_postList[index].id ?? ''),
          onCreatePost: () async {
            if (widget.onCreatePost == null) return;
            final postDataModelJsonString = await widget.onCreatePost!();
            if (postDataModelJsonString.isStringEmptyOrNull) return;
            final postDataMap = jsonDecode(postDataModelJsonString!) as Map<String, dynamic>;
            final postDataModel = PostDataModel.fromJson(postDataMap);
            setState(() {
              // _postList.insert(0, postDataModel);
            });
          },
          postId: _postList[index].id,
          description: _postList[index].caption ?? '',
          isAssetUploading: false,
          isFollow: false,
          isSelfProfile: widget.loggedInUserId.isStringEmptyOrNull == false &&
              widget.loggedInUserId == _postList[index].userId,
          firstName: _postList[index].user?.displayName ?? '',
          lastName: '',
          name: '@${_postList[index].user?.username ?? ''}',
          hasTags: [],
          profilePhoto: _postList[index].user?.avatarUrl ?? '',
          onTapVolume: () {},
          isReelsMuted: false,
          isReelsLongPressed: false,
          onLongPressEnd: () {},
          onDoubleTap: () async {},
          onLongPressStart: () {},
          mediaUrl: _postList[index].media?.first.mediaType == 'image'
              ? 'https://cdn.trulyfreehome.dev/tenant_001/project_001/user_007/${_postList[index].media?.first.url ?? ''}'
              : _postList[index].media?.first.url ?? '',
          mediaType: _postList[index].media?.first.mediaType == 'image' ? 0 : 1,
          onTapUserProfilePic: () {
            if (widget.onTapUserProfilePic != null) {
              widget.onTapUserProfilePic!(_postList[index].userId ?? '');
            }
          },
          productCount: _postList[index].tags?.products?.length ?? 0,
          isSavedPost: false,
          onPressMoreButton: () async {
            // if (widget.onTapMore == null) return;
            // final result = await widget.onTapMore!(_postList[index], _postList[index].userId ?? '');
            // if (result == null) return;
            // if (result is bool) {
            //   final isSuccess = result;
            //   if (isSuccess) {
            //     setState(() {
            //       _postList.removeAt(index);
            //     });
            //   }
            // }
            // if (result is String) {
            //   final editedPostedData = result;
            //   if (editedPostedData.isStringEmptyOrNull == false) {
            //     final postData =
            //         PostDataModel.fromJson(jsonDecode(editedPostedData) as Map<String, dynamic>);
            //     final index = _postList.indexWhere((element) => element.postId == postData.postId);
            //     if (index != -1) {
            //       setState(() {
            //         _postList[index] = postData;
            //       });
            //     }
            //   }
            // }
          },
          onPressFollowFollowing: () async {
            // if (_postList[index].userId != null) {
            //   if (widget.onPressFollow == null) return false;
            //   final isFollow = await widget.onPressFollow!(_postList[index].userId!);
            //
            //   setState(() {
            //     _postList[index] = _postList[index].copyWith(followStatus: isFollow ? 1 : 0);
            //   });
            //   return isFollow;
            // }
            return false;
          },
          onPressSave: () async {
            // if (_postList[index].postId != null) {
            //   if (widget.onPressSave == null) return false;
            //   final isSaved = await widget.onPressSave!(
            //       _postList[index].postId!, _postList[index].isSavedPost == true);
            //
            //   if (isSaved) {
            //     setState(() {
            //       _postList[index] =
            //           _postList[index].copyWith(isSavedPost: _postList[index].isSavedPost == false);
            //     });
            //   }
            //   return isSaved;
            // }
            return false;
          },
          isLiked: false,
          likesCount: 0,
          onPressLike: () async {
            // if (_postList[index].id != null) {
            //   if (widget.onPressLike == null) return false;
            //   final currentLikeStatus = _postList[index].liked == true;
            //   final isSuccess = await widget.onPressLike!(
            //     _postList[index].postId!,
            //     _postList[index].userId!,
            //     currentLikeStatus,
            //   );
            //
            //   if (isSuccess == false) return false;
            //   setState(() {
            //     final newLikesCount = currentLikeStatus
            //         ? _postList[index].likesCount?.toInt() == 0
            //             ? 0
            //             : (_postList[index].likesCount ?? 0) - 1
            //         : (_postList[index].likesCount ?? 0) + 1;
            //
            //     _postList[index] = _postList[index].copyWith(
            //       liked: !currentLikeStatus,
            //       likesCount: newLikesCount,
            //     );
            //   });
            //   return isSuccess;
            // }
            return false;
          },
          onTapCartIcon: () async {
            if (widget.onTapCartIcon != null) {
              final productList = _postList[index].tags?.products;
              final jsonString = jsonEncode(productList?.map((e) => e.toJson()).toList());
              widget.onTapCartIcon!(jsonString);
            }
          },
          onTapComment: () async {
            // if (widget.onTapComment != null) {
            //   final newCommentCount = await widget.onTapComment!(
            //       _postList[index].postId ?? '', _postList[index].totalComments?.toInt() ?? 0);
            //   if (newCommentCount != null) {
            //     setState(() {
            //       _postList[index].totalComments = newCommentCount;
            //     });
            //   }
            // }
          },
          onTapShare: () {
            // if (widget.onTapShare != null) {
            //   widget.onTapShare!(_postList[index].postId ?? '');
            // }
          },
          commentCount: 0,
          isScheduledPost: false,
          postStatus: 0,
        ),
      );

  void _precacheImages(List<TimeLineData> postList) async {
    if (postList.isNotEmpty) {
      var imageUrls = <String>[];
      for (final post in postList) {
        imageUrls.add(
            'https://cdn.trulyfreehome.dev/tenant_001/project_001/user_007/${post.media?.first.url ?? ''}');
      }
      unawaited(_cacheImagesInBackground(imageUrls));
    }
  }

  /// Background version of image caching using compute
  /// Then caches images on main thread
  /// Returns early if widget is unmounted
  Future<void> _cacheImagesInBackground(List<String> urls) async {
    if (!mounted) return;

    // Use compute for background processing if needed
    unawaited(compute((List<String> urls) => urls, urls).then((processedUrls) {
      if (!mounted) return;
      IsrVideoReelUtility.preCacheImages(urls, context);
    }));
  }
}
