import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ism_video_reel_player/data/data.dart';
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
    _onStartInit();
    super.initState();
  }

  /// Initialize the widget
  void _onStartInit() {
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
      // Immediately initialize ALL media from first post with highest priority
      final firstPost = _reelsDataList[0];
      final urlsToCache = <String>[];

      // Process ALL media items in the first post
      for (var mediaItem in firstPost.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          // Video
          // For video, cache both video and thumbnail
          urlsToCache.add(mediaItem.mediaUrl);
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            urlsToCache.add(mediaItem.thumbnailUrl);
            debugPrint(
                '🚀 MainWidget: Pre-initializing video and thumbnail: ${mediaItem.mediaUrl}');
          }
        } else {
          // Image
          // For image, just cache the image
          urlsToCache.add(mediaItem.mediaUrl);
          debugPrint('🚀 MainWidget: Pre-initializing image: ${mediaItem.mediaUrl}');
        }
      }

      // Initialize all first post media with maximum priority
      if (urlsToCache.isNotEmpty) {
        await MediaCacheFactory.precacheMedia(urlsToCache, highPriority: true);
        debugPrint(
            '🚀 MainWidget: Pre-initialized ${urlsToCache.length} media items for first post');
      }

      // Then start caching other media in parallel
      unawaited(_doMediaCaching(0));

      // Start background preloading of remaining posts (low priority)
      unawaited(_backgroundPreloadPosts());
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
    return _reelsDataList.isListEmptyOrNull == true
        ? _buildPlaceHolder(context)
        : _buildContent(context);
  }

  Widget _buildPlaceHolder(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: widget.postSectionType == PostSectionType.trending
                        ? const Text('No Data')
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
              ),
            ),
          ),
        ],
      );

  Widget _buildContent(BuildContext context) => Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshPost();
              },
              child: PageView.builder(
                // key: _pageStorageKey,
                allowImplicitScrolling: widget.allowImplicitScrolling ?? true,
                controller: _pageController,
                physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                onPageChanged: (index) {
                  _doMediaCaching(index);
                  final post = _reelsDataList[index];

                  EventQueueProvider.instance.addEvent({
                    'type': EventType.view.value,
                    'postId': post.postId,
                    'userId': widget.loggedInUserId,
                    'timestamp': DateTime.now().toUtc().toIso8601String(),
                  });
                  debugPrint('page index: $index');
                  // Check if we're at 65% of the list
                  final threshold = (_reelsDataList.length * 0.65).floor();
                  if (index >= threshold || index == _reelsDataList.length - 1) {
                    if (widget.onLoadMore != null) {
                      widget.onLoadMore!().then(
                        (value) {
                          if (value.isListEmptyOrNull) return;
                          final newReels = value.where((newReel) => !_reelsDataList
                              .any((existingReel) => existingReel.postId == newReel.postId));
                          _reelsDataList.addAll(newReels);
                          if (_reelsDataList.isNotEmpty) {
                            _doMediaCaching(0);
                          }
                          _updateState();
                        },
                      );
                    }
                  }
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(index, post.postId ?? '');
                  }
                },
                itemCount: _reelsDataList.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final reelsData = _reelsDataList[index];
                  return RepaintBoundary(
                    child: IsmReelsVideoPlayerView(
                      reelsData: reelsData,
                      loggedInUserId: widget.loggedInUserId,
                      videoCacheManager: _videoCacheManager,
                      // Add refresh count to force rebuild
                      key: ValueKey('${reelsData.postId}_${_refreshCounts[index] ?? 0}'),
                      onVideoCompleted: () => _handleVideoCompletion(index),
                      onPressMoreButton: () async {
                        if (reelsData.onPressMoreButton == null) return;
                        final result = await reelsData.onPressMoreButton!.call();
                        if (result == null) return;
                        if (result is bool) {
                          final isSuccess = result;
                          if (isSuccess) {
                            final postIndex = _reelsDataList
                                .indexWhere((element) => element.postId == reelsData.postId);
                            if (postIndex != -1) {
                              _reelsDataList.removeAt(postIndex);
                              final imageUrl =
                                  _reelsDataList[postIndex].mediaMetaDataList[0].mediaUrl;
                              final thumbnailUrl =
                                  _reelsDataList[postIndex].mediaMetaDataList[0].thumbnailUrl;
                              if (_reelsDataList[postIndex].mediaMetaDataList[0].mediaType ==
                                  MediaType.image.value) {
                                // For image post
                                await _evictDeletedPostImage(imageUrl);
                              } else {
                                // For video post
                                await _evictDeletedPostImage(thumbnailUrl);
                                // Clear video controller
                                _videoCacheManager.clearMedia(imageUrl);
                              }
                            }
                            _updateState();
                          }
                        }
                        if (result is ReelsData) {
                          final index = _reelsDataList
                              .indexWhere((element) => element.postId == result.postId);
                          if (index != -1) {
                            _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
                            _reelsDataList[index] = result;
                            _updateState();
                          }
                        }
                      },
                      onCreatePost: () async {
                        if (reelsData.onCreatePost != null) {
                          final result = await reelsData.onCreatePost!();
                          if (result != null) {
                            _reelsDataList.insert(index, result);
                            _updateState();
                          }
                        }
                      },
                      onPressFollowButton: () async {
                        if (reelsData.onPressFollow != null) {
                          final result = await reelsData.onPressFollow!(
                              reelsData.userId ?? '', reelsData.isFollow ?? false);
                          if (result == true && mounted) {
                            final index = _reelsDataList
                                .indexWhere((element) => element.postId == reelsData.postId);
                            if (index != -1) {
                              _reelsDataList[index].isFollow =
                                  reelsData.isFollow == true ? false : true;
                              _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
                              _updateState();
                            }
                          }
                          // ✅ Log event locally
                          unawaited(EventQueueProvider.instance.addEvent({
                            'type': EventType.follow.value,
                            'postId': reelsData.postId,
                            'userId': widget.loggedInUserId,
                            'isFollow': reelsData.isFollow,
                            'timestamp': DateTime.now().toUtc().toIso8601String(),
                          }));
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
                            _updateState();
                          }
                          // ✅ Log event locally
                          unawaited(EventQueueProvider.instance.addEvent({
                            'type': EventType.like.value,
                            'postId': reelsData.postId,
                            'userId': widget.loggedInUserId,
                            'isLiked': reelsData.isLiked,
                            'timestamp': DateTime.now().toUtc().toIso8601String(),
                          }));
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
                            _updateState();
                          }
                          // ✅ Log event locally
                          unawaited(EventQueueProvider.instance.addEvent({
                            'type': EventType.like.value,
                            'postId': reelsData.postId,
                            'userId': widget.loggedInUserId,
                            'isLiked': reelsData.isLiked,
                            'timestamp': DateTime.now().toUtc().toIso8601String(),
                          }));
                        }
                      },
                      onPressSaveButton: () async {
                        if (reelsData.onPressSave != null) {
                          final result =
                              await reelsData.onPressSave!(reelsData.isSavedPost ?? false);
                          if (result == true) {
                            reelsData.isSavedPost = reelsData.isSavedPost == false;
                            _updateState();
                          }
                          unawaited(EventQueueProvider.instance.addEvent({
                            'type': EventType.save.value,
                            'postId': reelsData.postId,
                            'isSaved': reelsData.isSavedPost,
                            'userId': widget.loggedInUserId,
                            'timestamp': DateTime.now().toUtc().toIso8601String(),
                          }));
                        }
                      },
                      onTapMentionTag: (mentionedList) async {
                        if (reelsData.onTapMentionTag != null) {
                          final result = await reelsData.onTapMentionTag!(mentionedList);
                          if (result.isListEmptyOrNull == false) {
                            final index = _reelsDataList
                                .indexWhere((element) => element.postId == reelsData.postId);
                            if (index != -1) {
                              _reelsDataList[index].mentions = result ?? [];
                              _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
                              _updateState();
                            }
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );

  /// Background preloading of posts that are not immediately visible
  Future<void> _backgroundPreloadPosts() async {
    if (_reelsDataList.length <= 5) return; // Skip if not enough posts

    final backgroundUrls = <String>[];

    // Preload posts 5-10 positions away (low priority)
    final startIndex = 5;
    final endIndex = math.min(_reelsDataList.length - 1, 10);

    for (var i = startIndex; i <= endIndex; i++) {
      final post = _reelsDataList[i];
      for (var mediaItem in post.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          backgroundUrls.add(mediaItem.mediaUrl);
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            backgroundUrls.add(mediaItem.thumbnailUrl);
          }
        } else {
          backgroundUrls.add(mediaItem.mediaUrl);
        }
      }
    }

    if (backgroundUrls.isNotEmpty) {
      debugPrint('🔄 Background preloading ${backgroundUrls.length} media items');
      unawaited(MediaCacheFactory.precacheMedia(backgroundUrls, highPriority: false));
    }
  }

  // Handle media caching for both images and videos
  Future<void> _doMediaCaching(int index) async {
    if (_reelsDataList.isEmpty || index >= _reelsDataList.length) return;

    final reelsData = _reelsDataList[index];
    final username = reelsData.userName;

    debugPrint('🎯 MainWidget: Page changed to index $index (@$username)');

    // Collect media URLs for current and nearby posts
    final mediaUrls = <String>[];
    final startIndex = math.max(0, index - 4); // 4 behind
    final endIndex = math.min(_reelsDataList.length - 1, index + 4); // 4 ahead

    // First process current post with high priority
    for (var mediaItem in reelsData.mediaMetaDataList) {
      if (mediaItem.mediaUrl.isEmpty) continue;

      if (mediaItem.mediaType == MediaType.video.value) {
        // Video
        // For videos, cache both video and thumbnail with high priority
        mediaUrls.insert(0, mediaItem.mediaUrl); // Add to start for high priority
        if (mediaItem.thumbnailUrl.isNotEmpty) {
          mediaUrls.insert(1, mediaItem.thumbnailUrl);
          debugPrint('🚀 Adding current video and thumbnail: ${mediaItem.mediaUrl}');
        }
      } else {
        // Image
        // For images, just cache the image with high priority
        mediaUrls.insert(0, mediaItem.mediaUrl); // Add to start for high priority
        debugPrint('🚀 Adding current image: ${mediaItem.mediaUrl}');
      }
    }

    // Then process nearby posts
    for (var i = startIndex; i <= endIndex; i++) {
      if (i == index) continue; // Skip current post as it's already added

      final nearbyPost = _reelsDataList[i];
      for (var mediaItem in nearbyPost.mediaMetaDataList) {
        if (mediaItem.mediaUrl.isEmpty) continue;

        if (mediaItem.mediaType == MediaType.video.value) {
          // Video
          mediaUrls.add(mediaItem.mediaUrl);
          if (mediaItem.thumbnailUrl.isNotEmpty) {
            mediaUrls.add(mediaItem.thumbnailUrl);
            debugPrint('➕ Adding nearby video and thumbnail for post $i');
          }
        } else {
          // Image
          mediaUrls.add(mediaItem.mediaUrl);
          debugPrint('➕ Adding nearby image for post $i');
        }
      }
    }

    // Cache all media with current post's media having priority
    if (mediaUrls.isNotEmpty) {
      debugPrint('🚀 MainWidget: Caching media: ${mediaUrls.length} items');

      // Split current post media (high priority) from nearby posts (low priority)
      final currentPostMedia = <String>[];
      final nearbyPostsMedia = <String>[];

      // Current post media (first few items) - HIGH PRIORITY
      final currentPostItemCount = reelsData.mediaMetaDataList.length * 2; // video + thumbnail
      for (var i = 0; i < currentPostItemCount && i < mediaUrls.length; i++) {
        currentPostMedia.add(mediaUrls[i]);
      }

      // Nearby posts media - LOW PRIORITY
      for (var i = currentPostItemCount; i < mediaUrls.length; i++) {
        nearbyPostsMedia.add(mediaUrls[i]);
      }

      // Cache current post with high priority (blocking)
      if (currentPostMedia.isNotEmpty) {
        await MediaCacheFactory.precacheMedia(currentPostMedia, highPriority: true);
      }

      // Cache nearby posts with low priority (non-blocking)
      if (nearbyPostsMedia.isNotEmpty) {
        unawaited(MediaCacheFactory.precacheMedia(nearbyPostsMedia, highPriority: false));
      }
    }

    // Print cache stats every few scrolls
    if (index % 3 == 0) {
      final stats = MediaCacheFactory.getCombinedStats();
      debugPrint('📊 MainWidget: Cache Stats - ${stats.toString()}');
    }
  }

// Updated _evictDeletedPostImage method to handle all media items
  Future<void> evictDeletedPostMedia(ReelsData deletedPost) async {
    // Loop through all media items in the deleted post
    for (var mediaIndex = 0; mediaIndex < deletedPost.mediaMetaDataList.length; mediaIndex++) {
      final mediaItem = deletedPost.mediaMetaDataList[mediaIndex];

      // Evict image or thumbnail
      final imageUrl = mediaItem.mediaType == MediaType.image.value
          ? mediaItem.mediaUrl
          : mediaItem.thumbnailUrl;

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
      if (mediaItem.mediaType == MediaType.video.value && mediaItem.mediaUrl.isNotEmpty) {
        // Clear from appropriate cache manager based on media type
        final imageCacheManager = MediaCacheFactory.getCacheManager(MediaType.image);
        final videoCacheManager = MediaCacheFactory.getCacheManager(MediaType.video);

        imageCacheManager.clearMedia(mediaItem.mediaUrl);
        videoCacheManager.clearMedia(mediaItem.mediaUrl);

        debugPrint(
            '🗑️ MainWidget: Evicted deleted post video from cache - Media $mediaIndex: ${mediaItem.mediaUrl}');
      }
    }
  }

  Future<void> clearAllCache() async {
    PaintingBinding.instance.imageCache.clear(); // removes decoded images
    PaintingBinding.instance.imageCache.clearLiveImages(); // removes "live" references

    // Clear all media caches using MediaCacheFactory
    MediaCacheFactory.clearAllCaches();

    // Clear disk cache from CachedNetworkImage
    await DefaultCacheManager().emptyCache();
  }

  Future<void> _evictDeletedPostImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    // Evict from Flutter's memory cache
    await NetworkImage(imageUrl).evict();

    // Clear from appropriate cache manager based on media type
    final mediaType = MediaTypeUtil.getMediaType(imageUrl);
    final cacheManager = MediaCacheFactory.getCacheManager(mediaType);
    cacheManager.clearMedia(imageUrl);

    // Also evict from disk cache if using CachedNetworkImage
    try {
      await DefaultCacheManager().removeFile(imageUrl);
      debugPrint('🗑️ MainWidget: Evicted deleted post image from cache - $imageUrl');
    } catch (_) {}
  }

  /// Handles video completion - navigates to next post if available
  void _handleVideoCompletion(int currentIndex) {
    debugPrint('🎬 PostItemWidget: _handleVideoCompletion called with index $currentIndex');
    debugPrint(
        '🎬 PostItemWidget: mounted: $mounted, reelsDataList length: ${_reelsDataList.length}');

    if (!mounted || _reelsDataList.isEmpty) {
      debugPrint('🎬 PostItemWidget: Early return - not mounted or empty list');
      return;
    }

    // Check if there's a next post available
    if (currentIndex < _reelsDataList.length - 1) {
      final nextIndex = currentIndex + 1;
      debugPrint('🎬 PostItemWidget: Video completed, moving to next post at index $nextIndex');

      // Animate to next page
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint('🎬 PostItemWidget: Video completed, but no more posts available');
      // Optionally trigger load more if we're at the end
      if (widget.onLoadMore != null) {
        debugPrint('🎬 PostItemWidget: Triggering load more...');
        widget.onLoadMore!().then((value) {
          if (value.isListEmptyOrNull) return;
          final newReels = value.where((newReel) =>
              !_reelsDataList.any((existingReel) => existingReel.postId == newReel.postId));
          _reelsDataList.addAll(newReels);
          if (_reelsDataList.isNotEmpty) {
            _doMediaCaching(0);
          }
          _updateState();
        });
      }
    }
  }

  Future<void> _refreshPost() async {
    if (widget.loggedInUserId.isStringEmptyOrNull == true) return;
    try {
      if (widget.onRefresh != null) {
        final result = await widget.onRefresh?.call();
        if (result == true) {
          // Get current index before refresh
          final currentIndex = _pageController.page?.toInt() ?? 0;
          debugPrint('🔄 MainWidget: Starting refresh at index $currentIndex');

          // Increment refresh count to force rebuild
          _refreshCounts[currentIndex] = (_refreshCounts[currentIndex] ?? 0) + 1;
          _updateState();
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
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }
}
