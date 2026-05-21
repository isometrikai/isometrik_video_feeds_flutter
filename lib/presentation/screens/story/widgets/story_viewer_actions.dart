import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/report_reason_dialog.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/delete_story_confirmation_dialog.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';
import 'package:ism_video_reel_player/utils/utility.dart';

class StoryViewerActions {
  const StoryViewerActions._();

  /// Opens the full-screen highlight composer (star action on own story).
  static Future<void> openAddToHighlights({
    required BuildContext context,
    required StoryData story,
    required StoryCubit storyCubit,
  }) =>
      IsrAppNavigator.presentHighlightComposerFlow(
        context,
        seedStory: story,
      );

  static Future<void> handleMoreActions({
    required BuildContext context,
    required StoryData? story,
    required bool canManageCurrentStory,
    required bool canReactToStory,
    required bool viewerHasLovedStory,
    ValueChanged<bool>? onViewerLoveUpdated,
    required String? highlightId,
    int? highlightStoryCount,
    required VoidCallback onAdvanceAfterMutation,
    ValueChanged<String>? onHighlightStoryRemoved,
  }) async {
    if (story == null || story.id.isEmpty) return;

    final canReportStory = !canManageCurrentStory;
    if (!canManageCurrentStory && !canReactToStory && !canReportStory) return;

    final storyCubit = context.read<StoryCubit>();
    final trimmedHighlightId = (highlightId ?? '').trim();
    final inHighlight = trimmedHighlightId.isNotEmpty;
    final storiesInHighlight = highlightStoryCount ?? 0;
    final singleStoryHighlight = inHighlight && storiesInHighlight <= 1;

    final theme = StoryThemeResolver.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReactToStory)
              ListTile(
                leading: Icon(
                  viewerHasLovedStory ? Icons.favorite : Icons.favorite_border,
                  color: viewerHasLovedStory
                      ? const Color(0xFFE91E63)
                      : theme.textPrimary,
                ),
                title: Text(
                  viewerHasLovedStory ? 'Remove love' : 'Love',
                  style: IsrStyles.primaryText14.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(
                  viewerHasLovedStory ? 'remove_love' : 'add_love',
                ),
              ),
            if (canReportStory) ...[
              if (canReactToStory)
                Divider(
                  height: 1,
                  color: theme.textSecondary.withValues(alpha: 0.2),
                ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: theme.textPrimary),
                title: Text(
                  IsrTranslationFile.reportStory,
                  style: IsrStyles.primaryText14.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('report_story'),
              ),
            ],
            if (canManageCurrentStory) ...[
              if (canReactToStory || canReportStory)
                Divider(
                  height: 1,
                  color: theme.textSecondary.withValues(alpha: 0.2),
                ),
              if (inHighlight)
                ListTile(
                  leading: Icon(
                    singleStoryHighlight
                        ? Icons.delete_outline
                        : Icons.remove_circle_outline,
                    color: theme.destructive,
                  ),
                  title: Text(
                    singleStoryHighlight
                        ? 'Delete highlight'
                        : 'Delete story from highlight',
                    style: IsrStyles.primaryText14.copyWith(
                      color: theme.destructive,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(
                    singleStoryHighlight
                        ? 'delete_highlight'
                        : 'remove_story_from_highlight',
                  ),
                )
              else
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.destructive),
                  title: Text(
                    'Delete story',
                    style: IsrStyles.primaryText14.copyWith(
                      color: theme.destructive,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop('delete_story'),
                ),
            ],
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'add_love') {
      final ok = await storyCubit.addReaction(
        storyId: story.id,
        reactionType: 'love',
      );
      if (context.mounted && ok) onViewerLoveUpdated?.call(true);
      return;
    }
    if (action == 'remove_love') {
      final ok = await storyCubit.removeReaction(story.id);
      if (context.mounted && ok) onViewerLoveUpdated?.call(false);
      return;
    }
    if (action == 'report_story') {
      await _reportStory(context: context, story: story);
      return;
    }
    if (action == 'delete_highlight') {
      if (trimmedHighlightId.isEmpty) return;
      final ok = await storyCubit.deleteHighlight(trimmedHighlightId);
      if (!context.mounted || !ok) return;
      Navigator.of(context).pop();
      return;
    }
    if (action == 'remove_story_from_highlight') {
      if (trimmedHighlightId.isEmpty) return;
      if (singleStoryHighlight) {
        final ok = await storyCubit.deleteHighlight(trimmedHighlightId);
        if (!context.mounted || !ok) return;
        Navigator.of(context).pop();
        return;
      }
      await storyCubit.removeStoryFromHighlight(
        highlightId: trimmedHighlightId,
        storyId: story.id,
      );
      if (!context.mounted) return;
      if (onHighlightStoryRemoved != null) {
        onHighlightStoryRemoved(story.id);
      } else {
        onAdvanceAfterMutation();
      }
      return;
    }
    if (action == 'delete_story') {
      final confirmed = await DeleteStoryConfirmationDialog.show(context);
      if (!context.mounted || !confirmed) return;
      await storyCubit.deleteStory(story.id);
      if (!context.mounted) return;
      onAdvanceAfterMutation();
    }
  }

  static Future<void> _reportStory({
    required BuildContext context,
    required StoryData story,
  }) async {
    final hostCallback =
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onReportStory;
    if (hostCallback != null) {
      await hostCallback(story);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ReportReasonDialog(
        reasonFor: ReasonsFor.story,
        contentId: story.id,
        onReportSuccess: (_) {
          Utility.showToastMessage(
            IsrTranslationFile.reportedSuccessfully('story'),
          );
        },
      ),
    );
  }

}
