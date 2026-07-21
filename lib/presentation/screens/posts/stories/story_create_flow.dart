import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_compose_view.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_image_cropper.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/add_to_story_bottom_sheet.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';

class StoryCreateFlow {
  const StoryCreateFlow._();

  static Future<void> open(BuildContext context) async {
    final storyConfig = IsrVideoReelConfig.storyConfig;
    final custom = storyConfig?.storyCallbackConfig.navigateToCreateStory;
    if (custom != null) {
      await custom(context);
      return;
    }

    final pick = await AddToStoryBottomSheet.show(context);
    if (pick == null || !context.mounted) return;
    final file = await AddToStoryBottomSheet.pickFile(context, pick);
    if (file == null || !context.mounted) return;

    final mediaType = pick == StoryMediaPick.video ? 'video' : 'image';
    var mediaFile = File(file.path);
    if (mediaType == 'image') {
      final cropped = await StoryImageCropper.crop(file.path);
      if (!context.mounted) return;
      if (cropped == null) return;
      mediaFile = cropped;
    }
    final cubit = IsrAppNavigator.hasStoryCubitInContext(context)
        ? context.read<StoryCubit>()
        : IsmInjectionUtils.getBloc<StoryCubit>();

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<StoryCubit>.value(
          value: cubit,
          child: StoryComposeView(
            file: mediaFile,
            mediaType: mediaType,
          ),
        ),
      ),
    );
  }
}
