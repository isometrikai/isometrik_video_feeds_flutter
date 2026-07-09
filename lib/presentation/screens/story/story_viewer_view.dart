import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/delete_story_confirmation_dialog.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/story_viewer_actions.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/story_viewer_footer.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/story_viewer_header.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/story_viewer_media_content.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/story_viewer_progress_bar.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:video_player/video_player.dart';

class StoryViewerView extends StatefulWidget {
  const StoryViewerView({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
    this.highlightId,
  });

  final List<StoryGroup> groups;
  final int initialGroupIndex;
  final String? highlightId;

  @override
  State<StoryViewerView> createState() => _StoryViewerViewState();
}

class _StoryViewerViewState extends State<StoryViewerView> {
  static const String _storyLoveReactionType = 'love';

  late final StoryViewerCubit _viewerCubit;
  late List<StoryGroup> _groups;
  Timer? _imageTimer;
  VideoPlayerController? _video;

  int _playbackPauseDepth = 0;

  @override
  void initState() {
    super.initState();
    _groups = widget.groups.map(_copyStoryGroup).toList();
    _viewerCubit = StoryViewerCubit(
      initialGroupIndex: widget.initialGroupIndex,
      totalGroups: _groups.length,
    );
    _loadViewerUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMedia());
  }

  StoryGroup _copyStoryGroup(StoryGroup group) => StoryGroup(
        userId: group.userId,
        username: group.username,
        avatarUrl: group.avatarUrl,
        isViewed: group.isViewed,
        stories: List<StoryData>.from(group.stories),
      );

  Future<void> _loadViewerUserId() async {
    try {
      final userId =
          await IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>().getUserId();
      if (!mounted) return;
      _viewerCubit.setViewerUserId(userId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _disposeVideo();
    _viewerCubit.close();
    super.dispose();
  }

  StoryGroup? get _group =>
      _groups.isEmpty || _viewerCubit.state.groupIndex >= _groups.length
          ? null
          : _groups[_viewerCubit.state.groupIndex];

  int get _highlightStoryCount {
    if ((widget.highlightId ?? '').trim().isEmpty) return 0;
    return _group?.stories.length ?? 0;
  }

  void _onHighlightStoryRemoved(String storyId) {
    final removeIndex =
        _group?.stories.indexWhere((s) => s.id == storyId) ?? -1;
    setState(() {
      _groups = _groups
          .map(
            (g) => StoryGroup(
              userId: g.userId,
              username: g.username,
              avatarUrl: g.avatarUrl,
              isViewed: g.isViewed,
              stories: g.stories.where((s) => s.id != storyId).toList(),
            ),
          )
          .where((g) => g.stories.isNotEmpty)
          .toList();
    });
    if (!mounted) return;
    if (_groups.isEmpty) {
      _closeViewer();
      return;
    }
    final g = _group;
    if (g == null || g.stories.isEmpty) {
      _closeViewer();
      return;
    }
    var nextIndex = _viewerCubit.state.storyIndex;
    if (removeIndex >= 0 && removeIndex < nextIndex) {
      nextIndex -= 1;
    } else if (removeIndex == nextIndex) {
      nextIndex = nextIndex.clamp(0, g.stories.length - 1);
    }
    if (nextIndex != _viewerCubit.state.storyIndex) {
      _viewerCubit.jumpToStory(nextIndex);
    }
    _syncMedia();
  }

  StoryData? get _story {
    final g = _group;
    if (g == null || g.stories.isEmpty) return null;
    if (_viewerCubit.state.storyIndex >= g.stories.length) return null;
    return g.stories[_viewerCubit.state.storyIndex];
  }

  void _closeViewer() {
    if (!mounted) return;

    // Story viewer is pushed on the root navigator (see presentStoryViewer).
    // With GoRouter, an unguarded popUntil can empty the route stack when the
    // viewer route identity does not match (nested navigators / overlays),
    // triggering: currentConfiguration.isNotEmpty assertion.
    final navigator = Navigator.of(context, rootNavigator: true);
    if (!navigator.canPop()) return;

    final viewerRoute = ModalRoute.of(context);
    if (viewerRoute == null) {
      navigator.pop<List<StoryGroup>>(_groups);
      return;
    }

    var reachedViewer = false;
    navigator.popUntil((route) {
      if (identical(route, viewerRoute)) {
        reachedViewer = true;
        return true;
      }
      // Never pop the last GoRouter page.
      return route.isFirst;
    });
    if (!mounted) return;
    if (reachedViewer && navigator.canPop()) {
      navigator.pop<List<StoryGroup>>(_groups);
      return;
    }
    if (navigator.canPop()) {
      navigator.pop<List<StoryGroup>>(_groups);
    }
  }

  bool _isVideo(StoryData s) {
    final t = s.mediaType.toLowerCase();
    final u = s.mediaUrl.toLowerCase();
    return t.contains('video') ||
        u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.contains('.m3u8');
  }

  void _disposeVideo() {
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _video = null;
  }

  void _onVideoTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized || !mounted) return;
    final totalMs = v.value.duration.inMilliseconds;
    if (totalMs > 0) {
      final currentMs = v.value.position.inMilliseconds.clamp(0, totalMs);
      final nextProgress = (currentMs / totalMs).clamp(0.0, 1.0);
      _viewerCubit.setProgress(nextProgress);
    }
    if (v.value.isCompleted) {
      v.removeListener(_onVideoTick);
      _goNext();
    }
  }

  void _syncMedia() {
    if (!mounted) return;
    _playbackPauseDepth = 0;
    _imageTimer?.cancel();
    _disposeVideo();
    _viewerCubit.resetProgress();
    final story = _story;
    if (story == null) {
      _closeViewer();
      return;
    }

    _markViewed(story.id);

    if (_isVideo(story)) {
      _video = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      _video!
        ..initialize().then((_) {
          if (!mounted || _story?.id != story.id) return;
          setState(() {});
          if (_playbackPauseDepth == 0) {
            _video!.play();
          }
        })
        ..addListener(_onVideoTick);
    } else {
      _startImageProgressTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_precacheAdjacentStories());
      });
    }
  }

  Future<void> _precacheAdjacentStories() async {
    if (!mounted) return;
    final g = _group;
    if (g == null || g.stories.isEmpty) return;
    final index = _viewerCubit.state.storyIndex;
    final targets = <int>[
      index,
      if (index + 1 < g.stories.length) index + 1,
      if (index > 0) index - 1,
    ];
    for (final i in targets) {
      final candidate = g.stories[i];
      if (_isVideo(candidate)) continue;
      final url = candidate.mediaUrl.trim();
      if (url.isEmpty) continue;
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (_) {}
      if (!mounted) return;
    }
  }

  void _startImageProgressTimer() {
    _imageTimer?.cancel();
    _viewerCubit.resetProgress();
    const total = Duration(seconds: 6);
    const tick = Duration(milliseconds: 50);
    final totalMs = total.inMilliseconds;
    var elapsedMs = 0;
    _imageTimer = Timer.periodic(tick, (timer) {
      if (_playbackPauseDepth > 0) return;
      elapsedMs += tick.inMilliseconds;
      final nextProgress = (elapsedMs / totalMs).clamp(0.0, 1.0);
      if (mounted) _viewerCubit.setProgress(nextProgress);
      if (elapsedMs >= totalMs) {
        timer.cancel();
        if (mounted) _goNext();
      }
    });
  }

  StoryGroup _markStoryViewedInGroup(StoryGroup group, String storyId) {
    final nextStories = group.stories
        .map(
          (s) => s.id == storyId ? s.copyWith(isViewed: true) : s,
        )
        .toList();
    final allDone =
        nextStories.isNotEmpty && nextStories.every((s) => s.isViewed);
    return StoryGroup(
      userId: group.userId,
      username: group.username,
      avatarUrl: group.avatarUrl,
      isViewed: allDone,
      stories: nextStories,
    );
  }

  void _markViewed(String id) {
    if (!_viewerCubit.markViewedIfNeeded(id)) return;
    setState(() {
      _groups = _groups.map((g) => _markStoryViewedInGroup(g, id)).toList();
    });
    unawaited(context.read<StoryCubit>().markStoryViewed(id));
  }

  void _goNext() {
    _imageTimer?.cancel();
    _video?.removeListener(_onVideoTick);
    final g = _group;
    if (g == null) {
      _closeViewer();
      return;
    }
    final result = _viewerCubit.goNext(_groups);
    if (result == StoryViewerNavResult.advanced) {
      _syncMedia();
      return;
    }
    if (result == StoryViewerNavResult.completed) {
      _closeViewer();
    }
  }

  void _goPrev() {
    _imageTimer?.cancel();
    _video?.removeListener(_onVideoTick);
    final result = _viewerCubit.goPrev(_groups);
    if (result == StoryViewerNavResult.movedBack) {
      _syncMedia();
    }
  }

  void _onTapUp(TapUpDetails d) {
    if (_story == null) return;
    final w = MediaQuery.sizeOf(context).width;
    if (d.globalPosition.dx < w / 3) {
      _goPrev();
    } else {
      _goNext();
    }
  }

  void _pausePlayback() {
    if (_playbackPauseDepth == 0) {
      _video?.pause();
    }
    _playbackPauseDepth++;
  }

  void _resumePlayback() {
    if (_playbackPauseDepth <= 0) return;
    _playbackPauseDepth--;
    if (_playbackPauseDepth != 0) return;
    final story = _story;
    final v = _video;
    if (v != null &&
        story != null &&
        _isVideo(story) &&
        v.value.isInitialized &&
        !v.value.isCompleted) {
      v.play();
    }
  }

  bool get _canManageCurrentStory {
    final story = _story;
    return _viewerCubit.state.isCurrentStoryOwner(story: story, group: _group);
  }

  /// Reactions are only for signed-in viewers who are not the story owner.
  bool get _canReactToStory {
    final story = _story;
    final vu = _viewerCubit.state.viewerUserId;
    if (story == null || story.id.isEmpty || vu.isEmpty) return false;
    return !_viewerCubit.state.isCurrentStoryOwner(story: story, group: _group);
  }

  /// True when the viewer has reacted to the current story (from API or toggle).
  bool get _storyIsLoved => _story?.isReacted ?? false;

  void _setStoryReacted(String storyId, bool isReacted) {
    setState(() {
      _groups = _groups
          .map(
            (g) => StoryGroup(
              userId: g.userId,
              username: g.username,
              avatarUrl: g.avatarUrl,
              isViewed: g.isViewed,
              stories: g.stories
                  .map(
                    (s) =>
                        s.id == storyId ? s.copyWith(isReacted: isReacted) : s,
                  )
                  .toList(),
            ),
          )
          .toList();
    });
  }

  // Future<void> _sendStoryReaction(String reactionType) async {
  //   final story = _story;
  //   if (story == null || !_canReactToStory) return;
  //   _pausePlayback();
  //   try {
  //     await context.read<StoryCubit>().addReaction(
  //           storyId: story.id,
  //           reactionType: reactionType,
  //         );
  //   } finally {
  //     if (mounted) _resumePlayback();
  //   }
  // }

  // Future<void> _toggleStoryLove() async {
  //   final story = _story;
  //   if (story == null || !_canReactToStory) return;
  //   _pausePlayback();
  //   try {
  //     if (_storyIsLoved) {
  //       final ok = await context.read<StoryCubit>().removeReaction(story.id);
  //       if (mounted && ok) {
  //         setState(() => _viewerLovedStoryIds.remove(story.id));
  //       }
  //     } else {
  //       final ok = await context.read<StoryCubit>().addReaction(
  //             storyId: story.id,
  //             reactionType: _storyLoveReactionType,
  //           );
  //       if (mounted && ok) {
  //         setState(() => _viewerLovedStoryIds.add(story.id));
  //       }
  //     }
  //   } finally {
  //     if (mounted) _resumePlayback();
  //   }
  // }

  bool get _inHighlightViewer => (widget.highlightId ?? '').trim().isNotEmpty;

  bool get _showAddToHighlight => _canManageCurrentStory && !_inHighlightViewer;

  Future<void> _onAddToHighlightPressed() async {
    final story = _story;
    if (story == null || !_canManageCurrentStory) return;
    _pausePlayback();
    try {
      await StoryViewerActions.openAddToHighlights(
        context: context,
        story: story,
        storyCubit: context.read<StoryCubit>(),
      );
    } finally {
      if (mounted) _resumePlayback();
    }
  }

  Future<void> _onDeleteStoryPressed() async {
    final story = _story;
    if (story == null || !_canManageCurrentStory) return;
    _pausePlayback();
    try {
      final confirmed = await DeleteStoryConfirmationDialog.show(context);
      if (!mounted || !confirmed) return;
      await context.read<StoryCubit>().deleteStory(story.id);
      if (!mounted) return;
      _goNext();
    } finally {
      if (mounted) _resumePlayback();
    }
  }

  Future<void> _onMoreActionsPressed() async {
    _pausePlayback();
    try {
      await StoryViewerActions.handleMoreActions(
        context: context,
        story: _story,
        canManageCurrentStory: _canManageCurrentStory,
        canReactToStory: _canReactToStory,
        viewerHasLovedStory: _storyIsLoved,
        onViewerLoveUpdated: (loved) {
          if (!mounted) return;
          final id = _story?.id;
          if (id == null || id.isEmpty) return;
          _setStoryReacted(id, loved);
        },
        highlightId: widget.highlightId,
        highlightStoryCount: (widget.highlightId ?? '').trim().isNotEmpty
            ? _highlightStoryCount
            : null,
        onAdvanceAfterMutation: _goNext,
        onHighlightStoryRemoved: (widget.highlightId ?? '').trim().isNotEmpty
            ? _onHighlightStoryRemoved
            : null,
      );
    } finally {
      if (mounted) _resumePlayback();
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _viewerCubit,
        child: BlocBuilder<StoryViewerCubit, StoryViewerState>(
          builder: (context, viewerState) {
            final g = _group;
            final story = _story;
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  if (story != null)
                    Positioned.fill(
                      child: StoryViewerMediaContent(
                        key: ValueKey(story.id),
                        story: story,
                        isVideo: _isVideo,
                        videoController: _video,
                      ),
                    ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: _onTapUp,
                      onLongPressStart: (_) => _pausePlayback(),
                      onLongPressEnd: (_) => _resumePlayback(),
                      onLongPressCancel: _resumePlayback,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.45, 1],
                          ),
                        ),
                        child: SizedBox(
                          height: MediaQuery.paddingOf(context).top + 140,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: IsrDimens.edgeInsetsSymmetric(
                        horizontal: IsrDimens.eight,
                        vertical: IsrDimens.eight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (g != null)
                            StoryViewerProgressBar(
                              group: g,
                              state: viewerState,
                            ),
                          SizedBox(height: IsrDimens.eight),
                          StoryViewerHeader(
                            group: g,
                            story: story,
                            canManageCurrentStory: _canManageCurrentStory,
                            canReactToStory: _canReactToStory,
                            showAddToHighlight: _showAddToHighlight,
                            inHighlightViewer: _inHighlightViewer,
                            onAddToHighlightPressed: _showAddToHighlight
                                ? _onAddToHighlightPressed
                                : null,
                            onDeleteStoryPressed:
                                _canManageCurrentStory && !_inHighlightViewer
                                    ? _onDeleteStoryPressed
                                    : null,
                            onClose: _closeViewer,
                            onMoreActionsPressed: _onMoreActionsPressed,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: SafeArea(
                        child: Padding(
                          padding: IsrDimens.edgeInsets(
                            bottom: IsrDimens.sixteen,
                          ),
                          child: StoryViewerFooter(
                            story: story,
                            showViewCount: _canManageCurrentStory,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // if (_canReactToStory)
                  //   Positioned(
                  //     left: 0,
                  //     right: 0,
                  //     bottom: 0,
                  //     child: SafeArea(
                  //       child: Padding(
                  //         padding: IsrDimens.edgeInsets(
                  //           bottom: IsrDimens.sixteen,
                  //         ),
                  //         child: Row(
                  //           mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             Material(
                  //               color: Colors.black45,
                  //               shape: const CircleBorder(),
                  //               clipBehavior: Clip.antiAlias,
                  //               child: IconButton(
                  //                 tooltip: 'Like',
                  //                 icon: const Icon(
                  //                   Icons.favorite_border,
                  //                   color: Colors.white,
                  //                 ),
                  //                 onPressed: () =>
                  //                     unawaited(_sendStoryReaction('like')),
                  //               ),
                  //             ),
                  //             SizedBox(width: IsrDimens.sixteen),
                  //             Material(
                  //               color: Colors.black45,
                  //               shape: const CircleBorder(),
                  //               clipBehavior: Clip.antiAlias,
                  //               child: IconButton(
                  //                 tooltip: _storyIsLoved ? 'Remove love' : 'Love',
                  //                 icon: Icon(
                  //                   _storyIsLoved
                  //                       ? Icons.favorite
                  //                       : Icons.favorite_border,
                  //                   color: _storyIsLoved
                  //                       ? const Color(0xFFE91E63)
                  //                       : Colors.white,
                  //                 ),
                  //                 onPressed: () =>
                  //                     unawaited(_toggleStoryLove()),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            );
          },
        ),
      );
}
