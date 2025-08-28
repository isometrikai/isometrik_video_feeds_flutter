import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
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
  });

  final Future<List<ReelsData>> Function()? onLoadMore;
  final Future<bool> Function()? onRefresh;
  final Widget? placeHolderWidget;
  final PostSectionType? postSectionType;
  final VoidCallback? onTapPlaceHolder;
  final int? startingPostIndex;
  final String? loggedInUserId;
  final bool? allowImplicitScrolling;
  final Function(int)? onPageChanged;
  final List<ReelsData> reelsDataList;

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  final Set<String> _cachedImages = {};
  final VideoCacheManager _videoCacheManager = VideoCacheManager();
  List<ReelsData> _reelsDataList = [];
  final PageStorageKey<dynamic> _pageStorageKey = const PageStorageKey('_PostItemWidgetState');

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() async {
    _reelsDataList = widget.reelsDataList;
    _pageController = PageController(initialPage: widget.startingPostIndex ?? 0);

    if (_reelsDataList.isListEmptyOrNull == false) {
      await _doMediaCaching(0);
    }

    // Check current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetPage = _pageController.initialPage >= _reelsDataList.length
          ? _reelsDataList.length - 1
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
    _videoCacheManager.clearAll();
    // _clearAllCache();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _reelsDataList.isListEmptyOrNull == true
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

  Widget _buildContent(BuildContext context) {
    debugPrint('reelsDataList length: ${_reelsDataList.length}');
    return PageView.builder(
      key: _pageStorageKey,
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
        if (widget.onPageChanged != null) widget.onPageChanged!(index);
      },
      itemCount: _reelsDataList.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        final reelsData = _reelsDataList[index];
        return RepaintBoundary(
          child: IsmReelsVideoPlayerView(
            reelsData: reelsData,
            videoCacheManager: _videoCacheManager,
            key: ValueKey(index),
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
                    final imageUrl = _reelsDataList[postIndex].mediaUrl;
                    final thumbnailUrl = _reelsDataList[postIndex].thumbnailUrl;
                    if (_reelsDataList[postIndex].mediaType == 0) {
                      await _evictDeletedPostImage(imageUrl);
                    } else {
                      await _evictDeletedPostImage(thumbnailUrl);
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
          ),
        );
      },
    );
  }

  /// Background version of image caching using compute
  /// Then caches images on main thread
  /// Returns early if widget is unmounted
  Future<void> _cacheImagesInBackground(List<String> urls) async {
    debugPrint('cacheImagesInBackground:.... $urls');
    if (!mounted) return;

    // Use compute for background processing if needed
    await compute((List<String> urls) => urls, urls).then((processedUrls) {
      if (!mounted) return;
      IsrVideoReelUtility.preCacheImages(urls, context);
    });
  }

  // Update your _doImageCaching method to handle both images and videos
  Future<void> _doMediaCaching(int index) async {
    final reelsData = _reelsDataList[index];
    final username = reelsData.userName;
    final mediaType = reelsData.mediaType;

    debugPrint('🎯 MainWidget: Page changed to index $index (@$username - $mediaType)');

    // Precache images around current position
    await _precacheNearbyImages(index);
    // Precache videos around current position
    await _precacheNearbyVideos(index);

    // Print cache stats every few scrolls
    if (index % 3 == 0) {
      final stats = _videoCacheManager.getCacheStats();
      debugPrint('📊 MainWidget: Cache Stats - ${stats.toString()}');
    }
  }

  Future<void> _precacheNearbyImages(int currentIndex) async {
    if (_reelsDataList.isEmpty) return;

    // Cache more aggressively ahead since users typically scroll forward
    final startIndex = math.max(0, currentIndex - 1); // 1 behind
    final endIndex = math.min(_reelsDataList.length - 1, currentIndex + 4); // 4 ahead

    final imagesToCache = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      final reelData = _reelsDataList[i];
      final imageUrl = reelData.mediaType == 0 ? reelData.mediaUrl : reelData.thumbnailUrl;

      // Only cache if not already cached
      if (!_cachedImages.contains(imageUrl)) {
        imagesToCache.add(imageUrl);
        _cachedImages.add(imageUrl);
      }
    }

    if (imagesToCache.isNotEmpty) {
      // Priority: cache next post first, then others
      final prioritizedImages = _prioritizeNextPost(imagesToCache, currentIndex);
      await _cacheImagesInBackground(prioritizedImages);
    }
  }

  List<String> _prioritizeNextPost(List<String> images, int currentIndex) {
    // Put next post image first in the caching queue
    final nextPostIndex = currentIndex + 1;
    if (nextPostIndex < _reelsDataList.length) {
      final reelsData = _reelsDataList[nextPostIndex];
      final nextImageUrl = reelsData.mediaType == 0 ? reelsData.mediaUrl : reelsData.thumbnailUrl;
      // Move next image to front
      if (reelsData.mediaType == 0) {
        images.remove(nextImageUrl);
      }
      return [nextImageUrl, ...images];
    }
    return images;
  }

  // Add this new method for video precaching
  Future<void> _precacheNearbyVideos(int currentIndex) async {
    if (_reelsDataList.isEmpty) return;

    debugPrint('🎬 MainWidget: Starting video precaching for index $currentIndex');

    // Cache more aggressively ahead since users typically scroll forward
    final startIndex = math.max(0, currentIndex - 1); // 1 behind
    final endIndex = math.min(_reelsDataList.length - 1, currentIndex + 2); // 4 ahead

    debugPrint(
        '📍 MainWidget: Precaching range: $startIndex to $endIndex (current: $currentIndex)');

    final videosToCache = <String>[];
    final videoInfo = <String>[];

    for (var i = startIndex; i <= endIndex; i++) {
      final reelsData = _reelsDataList[i];

      // Only cache videos, not images
      if (reelsData.mediaType == 1) {
        final videoUrl = reelsData.mediaUrl;
        final username = reelsData.userName;
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
        final username = reelsData.userName;
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

      await _videoCacheManager.precacheVideos(prioritizedVideos);
    } else {
      debugPrint('✅ MainWidget: No new videos to cache around index $currentIndex');
    }
  }

// Add this method to prioritize next video
  List<String> _prioritizeNextVideo(List<String> videos, int currentIndex) {
    debugPrint('🎯 MainWidget: Prioritizing videos for current index $currentIndex');

    // Put next post video first in the caching queue
    final nextPostIndex = currentIndex + 1;
    if (nextPostIndex < _reelsDataList.length) {
      final reelsData = _reelsDataList[nextPostIndex];
      if (reelsData.mediaType == 1) {
        final nextVideoUrl = reelsData.mediaUrl;
        final nextUsername = reelsData.userName;

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
            for (var j = 0; j < _reelsDataList.length; j++) {
              final post = _reelsDataList[j];
              if (post.mediaUrl == url) {
                final username = post.userName;
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

  Future<void> _clearAllCache() async {
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

class PageViewItemWidget extends StatefulWidget {
  const PageViewItemWidget(
      {super.key, required this.reelsData, required this.index, required this.videoCacheManager});

  final ReelsData reelsData;
  final int index;
  final VideoCacheManager videoCacheManager;
  @override
  State<PageViewItemWidget> createState() => _PageViewItemWidgetState();
}

class _PageViewItemWidgetState extends State<PageViewItemWidget> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IsmReelsVideoPlayerView(
        reelsData: widget.reelsData,
        videoCacheManager: widget.videoCacheManager,
        key: ValueKey(widget.index),
        onPressMoreButton: () async {
          if (widget.reelsData.onPressMoreButton == null) return;
          final result = await widget.reelsData.onPressMoreButton!.call();
          if (result == null) return;
          if (result is bool) {
            // final isSuccess = result;
            // if (isSuccess) {
            //   final postIndex =
            //   _reelsDataList.indexWhere((element) => element.postId == reelsData.postId);
            //   if (postIndex != -1) {
            //     setState(() {
            //       _reelsDataList.removeAt(postIndex);
            //     });
            //     final imageUrl = _reelsDataList[postIndex].mediaUrl;
            //     final thumbnailUrl = _reelsDataList[postIndex].thumbnailUrl;
            //     if (_reelsDataList[postIndex].mediaType == 0) {
            //       await _evictDeletedPostImage(imageUrl);
            //     } else {
            //       await _evictDeletedPostImage(thumbnailUrl);
            //     }
            //   }
            // }
          }
          if (result is ReelsData) {
            // final index =
            // _reelsDataList.indexWhere((element) => element.postId == result.postId);
            // if (index != -1) {
            //   setState(() {
            //     _reelsDataList[index] = result;
            //   });
            // }
          }
        },
        onCreatePost: () async {
          // if (reelsData.onCreatePost != null) {
          //   final result = await reelsData.onCreatePost!();
          //   if (result != null) {
          //     setState(() {
          //       _reelsDataList.insert(index, result);
          //     });
          //   }
          // }
        },
      ),
    );
  }
}
