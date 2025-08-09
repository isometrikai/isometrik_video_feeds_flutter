import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  final Future<dynamic> Function(TimeLineData, String userId)? onTapMore;
  final bool? showBlur;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function(String, bool)? onPressSave;
  final Future<bool> Function(String, String, bool)? onPressLike;
  final Future<bool> Function(String)? onPressFollow;
  final Future<List<TimeLineData>> Function(PostSectionType?)? onLoadMore;
  final Future<List<SocialProductData>>? Function(String, String)? onTapCartIcon;
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
  final Set<String> _cachedImages = {};
  final VideoCacheManager _videoCacheManager = VideoCacheManager();

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
      setState(() {
        _postList = postList;
      });
      _precacheNearbyImages(0);
    }

    _subscription = _postBloc.stream.listen((state) {
      if (state is PostsLoadedState) {
        if (_postList.isEmpty) {
          final postList = state.timeLinePostList ?? [];
          // _precacheImages(postList);
          setState(() {
            _postList = postList;
          });
          _precacheNearbyImages(0);
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
    _videoCacheManager.clearAll();
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
        clipBehavior: Clip.hardEdge,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          _doMediaCaching(index);
          debugPrint('page index: $index');
          // Check if we're at 65% of the list
          final threshold = (_postList.length * 0.65).floor();
          if (index >= threshold || index == _postList.length - 1) {
            if (widget.onLoadMore != null) {
              widget.onLoadMore!(widget.postSectionType).then(
                (value) {
                  if (value.isListEmptyOrNull) return;
                  if (mounted) {
                    setState(
                      () {
                        // Filter out duplicates based on postId
                        final newPosts = value.where((newPost) =>
                            !_postList.any((existingPost) => existingPost.id == newPost.id));
                        _postList.addAll(newPosts
                            .where((post) => post.media?.first.mediaType == 'video')
                            .toList());
                        if (_postList.isNotEmpty) {
                          _doMediaCaching(0);
                        }
                      },
                    );
                  }
                },
              );
            }
          }
          if (widget.onPageChanged != null) widget.onPageChanged!(index);
        },
        itemCount: _postList.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) => IsmReelsVideoPlayerView(
          videoCacheManager: _videoCacheManager,
          // Add this parameter
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
          mediaUrl: _postList[index].media?.first.url ?? '',
          mediaType: _postList[index].media?.first.mediaType == 'image' ? 0 : 1,
          onTapUserProfilePic: () {
            if (widget.onTapUserProfilePic != null) {
              widget.onTapUserProfilePic!(_postList[index].userId ?? '');
            }
          },
          productCount: _postList[index].tags?.products?.length ?? 0,
          isSavedPost: false,
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
                final postData =
                    TimeLineData.fromMap(jsonDecode(editedPostedData) as Map<String, dynamic>);
                final index = _postList.indexWhere((element) => element.id == postData.id);
                if (index != -1) {
                  setState(() {
                    _postList[index] = postData;
                  });
                }
              }
            }
          },
          onPressFollowFollowing: () async => false,
          onPressSave: () async => false,
          isLiked: false,
          likesCount: 0,
          onPressLike: () async => false,
          onTapCartIcon: () async {
            if (widget.onTapCartIcon != null) {
              final productList = _postList[index].tags?.products;
              final jsonString = jsonEncode(productList?.map((e) => e.toJson()).toList());
              final productDataList =
                  await widget.onTapCartIcon!(jsonString, _postList[index].id ?? '');
              if (productDataList.isListEmptyOrNull) return;
              final tags = _postList[index].tags;
              if (tags == null) return;
              tags.products = productDataList;
              setState(() {
                _postList[index] = _postList[index].copyWith(tags: tags);
              });
            }
          },
          onTapComment: () async {
            if (widget.onTapComment != null) {
              final newCommentCount = await widget.onTapComment!(_postList[index].id ?? '',
                  _postList[index].engagementMetrics?.comments?.toInt() ?? 0);
              if (newCommentCount != null) {
                setState(() {
                  _postList[index].engagementMetrics?.comments = newCommentCount;
                });
              }
            }
          },
          onTapShare: () {
            if (widget.onTapShare != null) {
              widget.onTapShare!(_postList[index].id ?? '');
            }
          },
          commentCount: 0,
          isScheduledPost: false,
          postStatus: 0,
        ),
      );

  /// Background version of image caching using compute
  /// Then caches images on main thread
  /// Returns early if widget is unmounted
  Future<void> _cacheImagesInBackground(List<String> urls) async {
    debugPrint('cacheImagesInBackground:.... $urls');
    if (!mounted) return;

    // Use compute for background processing if needed
    unawaited(compute((List<String> urls) => urls, urls).then((processedUrls) {
      if (!mounted) return;
      IsrVideoReelUtility.preCacheImages(urls, context);
    }));
  }

  // Update your _doImageCaching method to handle both images and videos
  void _doMediaCaching(int index) {
    final post = _postList[index];
    final username = post.user?.username ?? 'unknown';
    final mediaType = post.media?.first.mediaType ?? 'unknown';

    debugPrint('🎯 MainWidget: Page changed to index $index (@$username - $mediaType)');

    // Precache images around current position
    _precacheNearbyImages(index);
    // Precache videos around current position
    _precacheNearbyVideos(index);

    // Print cache stats every few scrolls
    if (index % 3 == 0) {
      final stats = _videoCacheManager.getCacheStats();
      debugPrint('📊 MainWidget: Cache Stats - ${stats.toString()}');
    }
  }

  void _precacheNearbyImages(int currentIndex) {
    if (_postList.isEmpty) return;

    // Cache more aggressively ahead since users typically scroll forward
    final startIndex = math.max(0, currentIndex - 1); // 1 behind
    final endIndex = math.min(_postList.length - 1, currentIndex + 4); // 4 ahead

    final imagesToCache = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      final post = _postList[i];
      final imageUrl = post.media?.first.mediaType == 'image'
          ? post.media?.first.url ?? ''
          : (post.media?.first.previewUrl ?? '');

      // Only cache if not already cached
      if (!_cachedImages.contains(imageUrl)) {
        imagesToCache.add(imageUrl);
        _cachedImages.add(imageUrl);
      }
    }

    if (imagesToCache.isNotEmpty) {
      // Priority: cache next post first, then others
      final prioritizedImages = _prioritizeNextPost(imagesToCache, currentIndex);
      unawaited(_cacheImagesInBackground(prioritizedImages));
    }
  }

  List<String> _prioritizeNextPost(List<String> images, int currentIndex) {
    // Put next post image first in the caching queue
    final nextPostIndex = currentIndex + 1;
    if (nextPostIndex < _postList.length) {
      final nextPost = _postList[nextPostIndex];
      if (nextPost.media?.first.mediaType == 'image') {
        final nextImageUrl = nextPost.media?.first.mediaType == 'image'
            ? nextPost.media?.first.url ?? ''
            : (nextPost.media?.first.previewUrl ?? '');
        // Move next image to front
        images.remove(nextImageUrl);
        return [nextImageUrl, ...images];
      }
    }
    return images;
  }

  // Add this new method for video precaching
  void _precacheNearbyVideos(int currentIndex) {
    if (_postList.isEmpty) return;

    debugPrint('🎬 MainWidget: Starting video precaching for index $currentIndex');

    // Cache more aggressively ahead since users typically scroll forward
    final startIndex = math.max(0, currentIndex - 1); // 1 behind
    final endIndex = math.min(_postList.length - 1, currentIndex + 4); // 4 ahead

    debugPrint(
        '📍 MainWidget: Precaching range: $startIndex to $endIndex (current: $currentIndex)');

    final videosToCache = <String>[];
    final videoInfo = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      final post = _postList[i];

      // Only cache videos, not images
      if (post.media?.first.mediaType == 'video') {
        final videoUrl = post.media?.first.url ?? '';
        final username = post.user?.username ?? 'unknown';
        final position = i == currentIndex
            ? 'CURRENT'
            : i < currentIndex
                ? 'BEHIND'
                : 'AHEAD';

        videoInfo.add('[$position] Index $i: @$username');

        // Only cache if not already cached and URL is valid
        if (videoUrl.isNotEmpty && !_videoCacheManager.isVideoCached(videoUrl)) {
          videosToCache.add(videoUrl);
          debugPrint('➕ MainWidget: Added to cache queue - Index $i (@$username)');
        } else if (videoUrl.isNotEmpty) {
          debugPrint('✅ MainWidget: Already cached - Index $i (@$username)');
        } else {
          debugPrint('⚠️ MainWidget: Empty video URL - Index $i (@$username)');
        }
      } else {
        final username = post.user?.username ?? 'unknown';
        debugPrint('📷 MainWidget: Skipping image post - Index $i (@$username)');
      }
    }

    debugPrint('📊 MainWidget: Video analysis complete:');
    for (final info in videoInfo) {
      debugPrint('   $info');
    }

    if (videosToCache.isNotEmpty) {
      // Priority: cache next post first, then others
      final prioritizedVideos = _prioritizeNextVideo(videosToCache, currentIndex);
      debugPrint('🚀 MainWidget: Starting precache for ${prioritizedVideos.length} videos');

      unawaited(_videoCacheManager.precacheVideos(prioritizedVideos));
    } else {
      debugPrint('✅ MainWidget: No new videos to cache around index $currentIndex');
    }
  }

// Add this method to prioritize next video
  List<String> _prioritizeNextVideo(List<String> videos, int currentIndex) {
    debugPrint('🎯 MainWidget: Prioritizing videos for current index $currentIndex');

    // Put next post video first in the caching queue
    final nextPostIndex = currentIndex + 1;
    if (nextPostIndex < _postList.length) {
      final nextPost = _postList[nextPostIndex];
      if (nextPost.media?.first.mediaType == 'video') {
        final nextVideoUrl = nextPost.media?.first.url ?? '';
        final nextUsername = nextPost.user?.username ?? 'unknown';

        if (nextVideoUrl.isNotEmpty && videos.contains(nextVideoUrl)) {
          // Move next video to front
          videos.remove(nextVideoUrl);
          final prioritized = [nextVideoUrl, ...videos];

          debugPrint(
              '🥇 MainWidget: Prioritized next video - Index $nextPostIndex (@$nextUsername)');
          debugPrint('📋 MainWidget: Final priority order:');
          for (var i = 0; i < prioritized.length; i++) {
            final url = prioritized[i];
            // Find which post this URL belongs to
            for (var j = 0; j < _postList.length; j++) {
              final post = _postList[j];
              if (post.media?.first.url == url) {
                final username = post.user?.username ?? 'unknown';
                debugPrint('   ${i + 1}. Index $j (@$username)');
                break;
              }
            }
          }

          return prioritized;
        }
      }
    }

    debugPrint('📋 MainWidget: No next video to prioritize, using original order');
    return videos;
  }
}
