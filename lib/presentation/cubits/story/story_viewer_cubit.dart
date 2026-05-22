import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/models/models.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story_viewer_state.dart';
import 'package:ism_video_reel_player/utils/enums.dart';

class StoryViewerCubit extends Cubit<StoryViewerState> {
  StoryViewerCubit({
    required int initialGroupIndex,
    required int totalGroups,
  }) : super(
          StoryViewerState(
            groupIndex: totalGroups == 0
                ? 0
                : initialGroupIndex.clamp(0, totalGroups - 1),
            storyIndex: 0,
          ),
        );

  void setViewerUserId(String userId) {
    emit(state.copyWith(viewerUserId: userId));
  }

  void setProgress(double progress) {
    final next = progress.clamp(0.0, 1.0);
    if ((state.storyProgress - next).abs() < 0.001) return;
    emit(state.copyWith(storyProgress: next));
  }

  void resetProgress() {
    if (state.storyProgress == 0) return;
    emit(state.copyWith(storyProgress: 0));
  }

  void jumpToStory(int storyIndex) {
    if (storyIndex == state.storyIndex) return;
    emit(
      state.copyWith(
        storyIndex: storyIndex,
        storyProgress: 0,
      ),
    );
  }

  bool markViewedIfNeeded(String storyId) {
    final next = state.markedViewedWith(storyId);
    if (identical(next, state.markedViewedStoryIds)) return false;
    emit(state.copyWith(markedViewedStoryIds: next));
    return true;
  }

  StoryViewerNavResult goNext(List<StoryGroup> groups) {
    if (groups.isEmpty || state.groupIndex >= groups.length) {
      return StoryViewerNavResult.completed;
    }
    final group = groups[state.groupIndex];
    if (state.storyIndex < group.stories.length - 1) {
      emit(
        state.copyWith(
          storyIndex: state.storyIndex + 1,
          storyProgress: 0,
        ),
      );
      return StoryViewerNavResult.advanced;
    }
    if (state.groupIndex < groups.length - 1) {
      emit(
        state.copyWith(
          groupIndex: state.groupIndex + 1,
          storyIndex: 0,
          storyProgress: 0,
        ),
      );
      return StoryViewerNavResult.advanced;
    }
    return StoryViewerNavResult.completed;
  }

  StoryViewerNavResult goPrev(List<StoryGroup> groups) {
    if (groups.isEmpty) return StoryViewerNavResult.noChange;
    if (state.storyIndex > 0) {
      emit(
        state.copyWith(
          storyIndex: state.storyIndex - 1,
          storyProgress: 0,
        ),
      );
      return StoryViewerNavResult.movedBack;
    }
    if (state.groupIndex > 0) {
      final prevGroup = groups[state.groupIndex - 1];
      emit(
        state.copyWith(
          groupIndex: state.groupIndex - 1,
          storyIndex:
              prevGroup.stories.isEmpty ? 0 : prevGroup.stories.length - 1,
          storyProgress: 0,
        ),
      );
      return StoryViewerNavResult.movedBack;
    }
    return StoryViewerNavResult.noChange;
  }
}
