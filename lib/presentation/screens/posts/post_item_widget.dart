import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/media_cache_factory.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class PostItemWidget extends StatefulWidget {
  const PostItemWidget({
    super.key,
    this.onLoadMore,
    this.onRefresh,
    this.placeHolderWidget,
    this.postSectionType,
    this.onTapPlaceHolder,
    this.startingPostIndex = 0,
    this.loggedInUserId,
    this.allowImplicitScrolling = true,
    this.onPageChanged,
    required this.reelsDataList,
    this.videoCacheManager,
  });

  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;
  final Function(int, String)? onPageChanged;
  final List<ReelsData> reelsDataList;
  final VideoCacheManager? videoCacheManager;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  final Set<String> _cachedImages = {};
  late final VideoCacheManager _videoCacheManager;
  List<ReelsData> _reelsDataList = [];

  bool _isInitialized = false;

  // Track refresh count for each index to force rebuild
  final Map<int, int> _refreshCounts = {};

  @override
  void initState() {
    super.initState();
    _videoCacheManager = widget.videoCacheManager ?? VideoCacheManager();
    _reelsDataList = widget.reelsDataList;
    _pageController = PageController(initialPage: widget.startingPostIndex ?? 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeContent();
    }
  }

  void _initializeContent() async {
    if (_reelsDataList.isListEmptyOrNull == false) {
      await _doMediaCaching(0);
    }

    if (!mounted) return;

    final targetPage = _pageController.initialPage >= _reelsDataList.length
        ? _reelsDataList.length - 1
        : _pageController.initialPage;
    if (targetPage > 0) {
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Don't clear all cache on dispose, only clear controllers
    // _videoCacheManager.clearControllers();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.loggedInUserId.isStringEmptyOrNull == true) return;
        try {
          if (widget.onRefresh != null) {
            final result = await widget.onRefresh?.call();
            if (result == true) {
              // Get current index before refresh
              final currentIndex = _pageController.page?.toInt() ?? 0;
              debugPrint('🔄 MainWidget: Starting refresh at index $currentIndex');

              // Increment refresh count to force rebuild
              setState(() {
                _refreshCounts[currentIndex] = (_refreshCounts[currentIndex] ?? 0) + 1;
              });

              // Re-initialize caching for current index after successful refresh
              await _doMediaCaching(currentIndex);
              debugPrint(
                  '✅ MainWidget: Posts refreshed successfully with count: ${_refreshCounts[currentIndex]}');
            } else {
              debugPrint('⚠️ MainWidget: Refresh returned false');
            }
          }
        } catch (e) {
          debugPrint('❌ MainWidget: Error during refresh - $e');
        }
        return;
      },
      child: _reelsDataList.isListEmptyOrNull == true
          ? _buildPlaceHolder(context)
          : _buildContent(context),
    );
  }

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
        // key: _pageStorageKey,
        allowImplicitScrolling: widget.allowImplicitScrolling ?? true,
        controller: _pageController,
        clipBehavior: Clip.none,
        padEnds: false,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          _doMediaCaching(index);
          debugPrint('page index: $index');
          // Check if we're at 65% of the list
          final threshold = (_reelsDataList.length * 0.65).floor();
          if (index >= threshold || index == _reelsDataList.length - 1) {
            if (widget.onLoadMore != null) {
              widget.onLoadMore!().then(
                (value) {
                  if (value.isListEmptyOrNull) return;
                  if (mounted) {
                    setState(() {
                      final newReels = value.where((newReel) => !_reelsDataList
                          .any((existingReel) => existingReel.postId == newReel.postId));
                      _reelsDataList.addAll(newReels);
                      if (_reelsDataList.isNotEmpty) {
                        _doMediaCaching(0);
                      }
                    });
                  }
                },
              );
            }
          }
          if (widget.onPageChanged != null) {
            widget.onPageChanged!(index, _reelsDataList[index].postId ?? '');
          }
        },
        itemCount: _reelsDataList.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          final reelsData = _reelsDataList[index];
          return RepaintBoundary(
            child: IsmReelsVideoPlayerView(
              reelsData: reelsData,
              videoCacheManager: _videoCacheManager,
              // Add refresh count to force rebuild
              key: ValueKey('${reelsData.postId}_${_refreshCounts[index] ?? 0}'),
              onPressMoreButton: () async {
                if (reelsData.onPressMoreButton == null) return;
                final result = await reelsData.onPressMoreButton!.call();
                if (result == null) return;
                if (result is bool) {
                  final isSuccess = result;
                  if (isSuccess) {
                    final postIndex =
                        _reelsDataList.indexWhere((element) => element.postId == reelsData.postId);
                    if (postIndex != -1) {
                      setState(() {
                        _reelsDataList.removeAt(postIndex);
                      });
                      final imageUrl = _reelsDataList[postIndex].mediaMetaDataList[0].mediaUrl;
                      final thumbnailUrl =
                          _reelsDataList[postIndex].mediaMetaDataList[0].thumbnailUrl;
                      if (_reelsDataList[postIndex].mediaMetaDataList[0].mediaType == 0) {
                        // For image post
                        await _evictDeletedPostImage(imageUrl);
                      } else {
                        // For video post
                        await _evictDeletedPostImage(thumbnailUrl);
                        // Clear video controller
                        _videoCacheManager.clearMedia(imageUrl);
                      }
                    }
                  }
                }
                if (result is ReelsData) {
                  final index =
                      _reelsDataList.indexWhere((element) => element.postId == result.postId);
                  if (index != -1) {
                    setState(() {
                      _reelsDataList[index] = result;
                    });
                  }
                }
              },
              onCreatePost: () async {
                if (reelsData.onCreatePost != null) {
                  final result = await reelsData.onCreatePost!();
                  if (result != null) {
                    setState(() {
                      _reelsDataList.insert(index, result);
                    });
                  }
                }
              },
              onPressFollowButton: () async {
                if (reelsData.onPressFollow != null) {
                  final result = await reelsData.onPressFollow!(
                      reelsData.userId ?? '', reelsData.isFollow ?? false);
                  if (result == true) {
                    setState(() {
                      reelsData.isFollow = reelsData.isFollow == true ? false : true;
                    });
                  }
                }
              },
              onPressLikeButton: () async {
                if (reelsData.onPressLike != null) {
                  final result = await reelsData.onPressLike!(reelsData.isLiked ?? false);
                  if (result == true) {
                    reelsData.isLiked = reelsData.isLiked == false;
                    if (reelsData.isLiked == true) {
                      reelsData.likesCount = (reelsData.likesCount ?? 0) + 1;
                    } else {
                      if ((reelsData.likesCount ?? 0) > 0) {
                        reelsData.likesCount = (reelsData.likesCount ?? 0) - 1;
                      }
                    }
                    setState(() {});
                  }
                }
              },
              onDoubleTap: () async {
                if (reelsData.onDoubleTap != null && reelsData.isLiked == false) {
                  final result = await reelsData.onDoubleTap!(reelsData.isLiked ?? false);
                  if (result == true) {
                    reelsData.isLiked = reelsData.isLiked == false;
                    if (reelsData.isLiked == true) {
                      reelsData.likesCount = (reelsData.likesCount ?? 0) + 1;
                    } else {
                      if ((reelsData.likesCount ?? 0) > 0) {
                        reelsData.likesCount = (reelsData.likesCount ?? 0) - 1;
                      }
                    }
                    setState(() {});
                  }
                }
              },
              onPressSaveButton: () async {
                if (reelsData.onPressSave != null) {
                  final result = await reelsData.onPressSave!(reelsData.isSavedPost ?? false);
                  if (result == true) {
                    reelsData.isSavedPost = reelsData.isSavedPost == false;
                    setState(() {});
                  }
                }
              },
            ),
          );
        },
      );

  // Handle media caching for both images and videos
  Future<void> _doMediaCaching(int index) async {
    if (_reelsDataList.isEmpty || index >= _reelsDataList.length) return;

    final reelsData = _reelsDataList[index];
    final username = reelsData.userName;

    debugPrint('🎯 MainWidget: Page changed to index $index (@$username)');

    // Collect all media URLs from current post
    final currentMediaUrls = <String>[];
    for (var mediaItem in reelsData.mediaMetaDataList) {
      if (mediaItem.thumbnailUrl.isNotEmpty) {
        currentMediaUrls.add(mediaItem.thumbnailUrl);
      }
      if (mediaItem.mediaUrl.isNotEmpty) {
        currentMediaUrls.add(mediaItem.mediaUrl);
      }
    }

    // Immediately cache current post's media with high priority
    await MediaCacheFactory.precacheMedia(currentMediaUrls, highPriority: true);

    // Start precaching nearby content in parallel
    unawaited(_precacheNearbyMedia(index));

    // Print cache stats every few scrolls
    if (index % 3 == 0) {
      final stats = MediaCacheFactory.getCombinedStats();
      debugPrint('📊 MainWidget: Cache Stats - ${stats.toString()}');
    }
  }

  Future<void> _precacheNearbyMedia(int currentIndex) async {
    if (_reelsDataList.isEmpty) return;

    // Cache more aggressively ahead since users typically scroll forward
    final startIndex = math.max(0, currentIndex - 4); // 4 behind
    final endIndex = math.min(_reelsDataList.length - 1, currentIndex + 4); // 4 ahead

    final mediaUrls = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      if (i == currentIndex) {
        continue; // Skip current index as it's already cached
      }

      final reelData = _reelsDataList[i];
      for (var mediaItem in reelData.mediaMetaDataList) {
        if (mediaItem.thumbnailUrl.isNotEmpty) {
          mediaUrls.add(mediaItem.thumbnailUrl);
        }
        if (mediaItem.mediaUrl.isNotEmpty) {
          mediaUrls.add(mediaItem.mediaUrl);
        }
      }
    }

    if (mediaUrls.isNotEmpty) {
      final prioritizedUrls = _prioritizeNextPostAllMedia(mediaUrls, currentIndex);
      await MediaCacheFactory.precacheMedia(prioritizedUrls);
    }
  }

// Updated _prioritizeNextPost method to handle all media items
  List<String> _prioritizeNextPostAllMedia(List<String> images, int currentIndex) {
    // Put next post images first in the caching queue
    final nextPostIndex = currentIndex + 1;
    if (nextPostIndex < _reelsDataList.length) {
      final reelsData = _reelsDataList[nextPostIndex];
      final nextPostImages = <String>[];

      // Collect all images from the next post
      for (var mediaIndex = 0; mediaIndex < reelsData.mediaMetaDataList.length; mediaIndex++) {
        final mediaItem = reelsData.mediaMetaDataList[mediaIndex];
        final imageUrl = mediaItem.mediaType == 0 ? mediaItem.mediaUrl : mediaItem.thumbnailUrl;

        if (imageUrl.isNotEmpty && images.contains(imageUrl)) {
          nextPostImages.add(imageUrl);
          images.remove(imageUrl);
        }
      }

      // Put next post images at the front
      return [...nextPostImages, ...images];
    }
    return images;
  }

// Updated _evictDeletedPostImage method to handle all media items
  Future<void> evictDeletedPostMedia(ReelsData deletedPost) async {
    // Loop through all media items in the deleted post
    for (var mediaIndex = 0; mediaIndex < deletedPost.mediaMetaDataList.length; mediaIndex++) {
      final mediaItem = deletedPost.mediaMetaDataList[mediaIndex];

      // Evict image or thumbnail
      final imageUrl = mediaItem.mediaType == 0 ? mediaItem.mediaUrl : mediaItem.thumbnailUrl;

      if (imageUrl.isNotEmpty) {
        // Evict from Flutter's memory cache
        await NetworkImage(imageUrl).evict();
        _cachedImages.remove(imageUrl);

        // Also evict from disk cache if using CachedNetworkImage
        try {
          await DefaultCacheManager().removeFile(imageUrl);
          debugPrint(
              '🗑️ MainWidget: Evicted deleted post image from cache - Media $mediaIndex: $imageUrl');
        } catch (_) {}
      }

      // For videos, also evict from video cache
      if (mediaItem.mediaType == 1 && mediaItem.mediaUrl.isNotEmpty) {
        // await _videoCacheManager.evictVideo(mediaItem.mediaUrl);
        debugPrint(
            '🗑️ MainWidget: Evicted deleted post video from cache - Media $mediaIndex: ${mediaItem.mediaUrl}');
      }
    }
  }

  Future<void> clearAllCache() async {
    PaintingBinding.instance.imageCache.clear(); // removes decoded images
    PaintingBinding.instance.imageCache.clearLiveImages(); // removes "live" references

    // Clear disk cache from CachedNetworkImage
    await DefaultCacheManager().emptyCache();
  }

  Future<void> _evictDeletedPostImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    // Evict from Flutter's memory cache
    await NetworkImage(imageUrl).evict();

    // Also evict from disk cache if using CachedNetworkImage
    try {
      await DefaultCacheManager().removeFile(imageUrl);
      debugPrint('🗑️ MainWidget: Evicted deleted post image from cache - $imageUrl');
    } catch (_) {}
  }
}
