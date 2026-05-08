import 'dart:collection';

import 'package:ism_video_reel_player/domain/models/models.dart';

class StoryViewerState {
  const StoryViewerState({
    required this.groupIndex,
    required this.storyIndex,
    this.storyProgress = 0,
    this.viewerUserId = '',
    this.markedViewedStoryIds = const <String>{},
  });

  final int groupIndex;
  final int storyIndex;
  final double storyProgress;
  final String viewerUserId;
  final Set<String> markedViewedStoryIds;

  StoryViewerState copyWith({
    int? groupIndex,
    int? storyIndex,
    double? storyProgress,
    String? viewerUserId,
    Set<String>? markedViewedStoryIds,
  }) =>
      StoryViewerState(
        groupIndex: groupIndex ?? this.groupIndex,
        storyIndex: storyIndex ?? this.storyIndex,
        storyProgress: storyProgress ?? this.storyProgress,
        viewerUserId: viewerUserId ?? this.viewerUserId,
        markedViewedStoryIds: markedViewedStoryIds ?? this.markedViewedStoryIds,
      );

  bool isCurrentStoryOwner({
    required StoryData? story,
    required StoryGroup? group,
  }) {
    if (story == null || viewerUserId.isEmpty) return false;
    final ownerId =
        story.userId.isNotEmpty ? story.userId : (group?.userId ?? '');
    return ownerId.isNotEmpty && ownerId == viewerUserId;
  }

  Set<String> markedViewedWith(String storyId) {
    if (storyId.isEmpty || markedViewedStoryIds.contains(storyId)) {
      return markedViewedStoryIds;
    }
    return UnmodifiableSetView({...markedViewedStoryIds, storyId});
  }
}
