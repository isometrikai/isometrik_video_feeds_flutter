import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/res/res.dart';

class StoryViewerProgressBar extends StatelessWidget {
  const StoryViewerProgressBar({
    super.key,
    required this.group,
    required this.state,
  });

  final StoryGroup group;
  final StoryViewerState state;

  @override
  Widget build(BuildContext context) {
    final stories = group.stories;
    if (stories.isEmpty) return const SizedBox.shrink();
    return Row(
      children: List.generate(stories.length, (index) {
        final value = index < state.storyIndex
            ? 1.0
            : (index > state.storyIndex ? 0.0 : state.storyProgress);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == stories.length - 1 ? IsrDimens.zero : IsrDimens.four,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(IsrDimens.eight),
              child: LinearProgressIndicator(
                value: value,
                minHeight: IsrDimens.three,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}

