import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/report_reason_dialog.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/add_to_highlights_bottom_sheet.dart';
import 'package:ism_video_reel_player/presentation/screens/story/widgets/delete_story_confirmation_dialog.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:ism_video_reel_player/utils/utility.dart';

class StoryViewerActions {
  const StoryViewerActions._();

  /// Opens the highlight picker sheet (star action on own story).
  static Future<void> openAddToHighlights({
    required BuildContext context,
    required StoryData story,
    required StoryCubit storyCubit,
  }) =>
      _addToHighlight(context: context, story: story, storyCubit: storyCubit);

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

  static Future<void> _addToHighlight({
    required BuildContext context,
    required StoryData story,
    required StoryCubit storyCubit,
  }) async {
    final highlights = await storyCubit.getHighlightsForCurrentUser();
    if (!context.mounted) return;

    await AddToHighlightsBottomSheet.show(
      context: context,
      highlights: highlights,
      onCreateNewHighlight: () => _createNewHighlightForStory(
        context: context,
        story: story,
        storyCubit: storyCubit,
      ),
      onHighlightSelected: (selected) async {
        final fresh = await storyCubit.addStoryToHighlight(
          highlightId: selected.id,
          storyId: story.id,
        );
        if (!context.mounted) return;
        final callback =
            IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onHighlightTap;
        if (callback != null) {
          await callback(fresh ?? selected);
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to highlight.')),
        );
      },
    );
  }

  static Future<void> _createNewHighlightForStory({
    required BuildContext context,
    required StoryData story,
    required StoryCubit storyCubit,
  }) async {
    var title = '';
    String? pickedCoverUrl;
    var uploadingCover = false;
    final picker = ImagePicker();
    final theme = StoryThemeResolver.of(context);

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) => Padding(
              padding: IsrDimens.edgeInsets(
                left: IsrDimens.sixteen,
                top: IsrDimens.sixteen,
                right: IsrDimens.sixteen,
                bottom: IsrDimens.twelve,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    IsrTranslationFile.createNewHighlight,
                    style: IsrStyles.primaryText16.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: IsrDimens.twelve),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(IsrDimens.eight),
                        child: (pickedCoverUrl != null &&
                                pickedCoverUrl!.isNotEmpty)
                            ? Image.network(
                                pickedCoverUrl!,
                                width: IsrDimens.fiftySix,
                                height: IsrDimens.fiftySix,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                story.mediaUrl,
                                width: IsrDimens.fiftySix,
                                height: IsrDimens.fiftySix,
                                fit: BoxFit.cover,
                              ),
                      ),
                      SizedBox(width: IsrDimens.twelve),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          onChanged: (value) => title = value,
                          style: IsrStyles.primaryText14.copyWith(
                            color: theme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Highlight name',
                            hintStyle: IsrStyles.primaryText14.copyWith(
                              color: theme.textSecondary,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.textSecondary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: theme.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: uploadingCover
                          ? null
                          : () async {
                              final x = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (x == null || !sheetContext.mounted) return;
                              setModalState(() => uploadingCover = true);
                              final url = await storyCubit
                                  .uploadHighlightCoverFile(File(x.path));
                              if (!sheetContext.mounted) return;
                              setModalState(() {
                                uploadingCover = false;
                                if (url != null && url.isNotEmpty) {
                                  pickedCoverUrl = url;
                                }
                              });
                            },
                      icon: Icon(
                        Icons.photo_library_outlined,
                        color: theme.primary,
                        size: 20,
                      ),
                      label: Text(
                        uploadingCover ? 'Uploading…' : 'Pick cover image',
                        style: IsrStyles.primaryText14.copyWith(
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: IsrDimens.sixteen),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: uploadingCover
                              ? null
                              : () => Navigator.of(sheetContext).pop(false),
                          child: Text(
                            'Cancel',
                            style: IsrStyles.primaryText14.copyWith(
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: IsrDimens.twelve),
                      Expanded(
                        child: FilledButton(
                          onPressed: uploadingCover
                              ? null
                              : () async {
                                  final highlightTitle = title.trim();
                                  if (highlightTitle.isEmpty) return;
                                  final coverForApi =
                                      pickedCoverUrl ?? story.mediaUrl;
                                  final ok = await storyCubit
                                      .createHighlightWithStories(
                                    title: highlightTitle,
                                    coverUrl: coverForApi,
                                    sortOrder: 0,
                                    storyIds: [story.id],
                                  );
                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop(ok);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: theme.onPrimary,
                          ),
                          child: Text(
                            'Create',
                            style: IsrStyles.white14.copyWith(
                              color: theme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!context.mounted || created != true) return;
    IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onHighlightsChanged
        ?.call();
    final highlights = await storyCubit.getHighlightsForCurrentUser();
    if (!context.mounted) return;
    final callback =
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onHighlightTap;
    if (callback != null) {
      final coverForMatch = pickedCoverUrl ?? story.mediaUrl;
      final matched = highlights.where((h) {
        final hasStory = h.items.any((item) => item.storyId == story.id);
        if (!hasStory) return false;
        return h.coverUrl == coverForMatch || h.title == title.trim();
      }).toList();
      final tapped = matched.isNotEmpty
          ? matched.first
          : (highlights.isNotEmpty ? highlights.first : null);
      if (tapped != null) {
        await callback(tapped);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Highlight created.')),
    );
  }
}
