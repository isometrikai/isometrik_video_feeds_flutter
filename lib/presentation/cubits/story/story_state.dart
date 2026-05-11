import 'package:ism_video_reel_player/ism_video_reel_player.dart';

/// Story cubit states representing feed/highlight/actions lifecycle.
abstract class StoryState {
  const StoryState();
}

class StoryInitial extends StoryState {
  const StoryInitial();
}

class StoryLoading extends StoryState {
  const StoryLoading();
}

class StoryFeedLoaded extends StoryState {
  const StoryFeedLoaded({
    required this.unViewed,
    required this.viewed,
    this.nextCursor,
  });

  final List<StoryGroup> unViewed;
  final List<StoryGroup> viewed;
  final String? nextCursor;
}

class StoryHighlightsLoaded extends StoryState {
  const StoryHighlightsLoaded(this.highlights);

  final List<StoryHighlightData> highlights;
}

class StoryActionSuccess extends StoryState {
  const StoryActionSuccess(this.actionName);

  final String actionName;
}

class StoryError extends StoryState {
  const StoryError(this.message);

  final String message;
}
