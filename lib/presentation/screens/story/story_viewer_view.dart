import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/story_viewer_actions.dart';
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
  late final StoryViewerCubit _viewerCubit;
  Timer? _imageTimer;
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _viewerCubit = StoryViewerCubit(
      initialGroupIndex: widget.initialGroupIndex,
      totalGroups: widget.groups.length,
    );
    _loadViewerUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMedia());
  }

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

  StoryGroup? get _group => widget.groups.isEmpty ||
          _viewerCubit.state.groupIndex >= widget.groups.length
      ? null
      : widget.groups[_viewerCubit.state.groupIndex];

  StoryData? get _story {
    final g = _group;
    if (g == null || g.stories.isEmpty) return null;
    if (_viewerCubit.state.storyIndex >= g.stories.length) return null;
    return g.stories[_viewerCubit.state.storyIndex];
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
    _imageTimer?.cancel();
    _disposeVideo();
    _viewerCubit.resetProgress();
    final story = _story;
    if (story == null) {
      Navigator.of(context).maybePop();
      return;
    }

    _markViewed(story.id);

    if (_isVideo(story)) {
      _video = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      _video!
        ..initialize().then((_) {
          if (!mounted || _story?.id != story.id) return;
          setState(() {});
          _video!.play();
        })
        ..addListener(_onVideoTick);
    } else {
      const total = Duration(seconds: 6);
      const tick = Duration(milliseconds: 50);
      final totalMs = total.inMilliseconds;
      var elapsedMs = 0;
      _imageTimer = Timer.periodic(tick, (timer) {
        elapsedMs += tick.inMilliseconds;
        final nextProgress = (elapsedMs / totalMs).clamp(0.0, 1.0);
        if (mounted) _viewerCubit.setProgress(nextProgress);
        if (elapsedMs >= totalMs) {
          timer.cancel();
          if (mounted) _goNext();
        }
      });
    }
  }

  void _markViewed(String id) {
    if (!_viewerCubit.markViewedIfNeeded(id)) return;
    unawaited(context.read<StoryCubit>().markStoryViewed(id));
  }

  void _goNext() {
    _imageTimer?.cancel();
    _video?.removeListener(_onVideoTick);
    final g = _group;
    if (g == null) {
      Navigator.of(context).pop();
      return;
    }
    final result = _viewerCubit.goNext(widget.groups);
    if (result == StoryViewerNavResult.advanced) {
      _syncMedia();
      return;
    }
    if (result == StoryViewerNavResult.completed) {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    _imageTimer?.cancel();
    _video?.removeListener(_onVideoTick);
    final result = _viewerCubit.goPrev(widget.groups);
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

  bool get _canManageCurrentStory {
    final story = _story;
    return _viewerCubit.state.isCurrentStoryOwner(story: story, group: _group);
  }

  Future<void> _onMoreActionsPressed() async {
    await StoryViewerActions.handleMoreActions(
      context: context,
      story: _story,
      canManageCurrentStory: _canManageCurrentStory,
      highlightId: widget.highlightId,
      onAdvanceAfterMutation: _goNext,
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _viewerCubit,
        child: BlocBuilder<StoryViewerCubit, StoryViewerState>(
          builder: (context, _) {
            final g = _group;
            final story = _story;
            return Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTapUp,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (story != null)
                      StoryViewerMediaContent(
                        story: story,
                        isVideo: _isVideo,
                        videoController: _video,
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
                                state: _viewerCubit.state,
                              ),
                            SizedBox(height: IsrDimens.eight),
                            StoryViewerHeader(
                              group: g,
                              story: story,
                              canManageCurrentStory: _canManageCurrentStory,
                              onClose: () => Navigator.of(context).pop(),
                              onMoreActionsPressed: _onMoreActionsPressed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
