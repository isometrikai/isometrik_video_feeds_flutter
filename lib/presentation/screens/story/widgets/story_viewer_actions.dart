import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/res/res.dart';

class StoryViewerActions {
  const StoryViewerActions._();

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
    if (!canManageCurrentStory && !canReactToStory) return;
    final storyCubit = context.read<StoryCubit>();
    final trimmedHighlightId = (highlightId ?? '').trim();
    final inHighlight = trimmedHighlightId.isNotEmpty;
    final storiesInHighlight = highlightStoryCount ?? 0;
    final singleStoryHighlight = inHighlight && storiesInHighlight <= 1;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1D1D1D),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReactToStory)
              ListTile(
                leading: Icon(
                  viewerHasLovedStory
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: viewerHasLovedStory
                      ? const Color(0xFFE91E63)
                      : IsrColors.white,
                ),
                title: Text(
                  viewerHasLovedStory ? 'Remove love' : 'Love',
                  style: IsrStyles.white14,
                ),
                onTap: () => Navigator.of(context).pop(
                  viewerHasLovedStory ? 'remove_love' : 'add_love',
                ),
              ),
            if (canManageCurrentStory) ...[
              if (canReactToStory)
                const Divider(height: 1, color: Colors.white12),
              if (!inHighlight)
                ListTile(
                  leading:
                      Icon(Icons.bookmark_add_outlined, color: IsrColors.white),
                  title: Text(
                    'Add to highlight',
                    style: IsrStyles.white14,
                  ),
                  onTap: () => Navigator.of(context).pop('add_to_highlight'),
                ),
              if (inHighlight)
                ListTile(
                  leading: Icon(
                    singleStoryHighlight
                        ? Icons.delete_outline
                        : Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    singleStoryHighlight
                        ? 'Delete highlight'
                        : 'Delete story from highlight',
                    style: IsrStyles.white14.copyWith(color: Colors.redAccent),
                  ),
                  onTap: () => Navigator.of(context).pop(
                    singleStoryHighlight
                        ? 'delete_highlight'
                        : 'remove_story_from_highlight',
                  ),
                )
              else
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: Text(
                    'Delete story',
                    style: IsrStyles.white14.copyWith(color: Colors.redAccent),
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
    if (action == 'add_to_highlight') {
      await _addToHighlight(
          context: context, story: story, storyCubit: storyCubit);
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
      // Last story in highlight: delete the highlight (not remove story) to avoid
      // empty highlights and API edge cases.
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
      await storyCubit.deleteStory(story.id);
      if (!context.mounted) return;
      onAdvanceAfterMutation();
    }
  }

  static Future<void> _addToHighlight({
    required BuildContext context,
    required StoryData story,
    required StoryCubit storyCubit,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1D1D1D),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: IsrColors.white),
              title: Text(
                'Create new highlight',
                style: IsrStyles.white14,
              ),
              onTap: () => Navigator.of(context).pop('create'),
            ),
            ListTile(
              leading: const Icon(
                Icons.collections_bookmark_outlined,
                color: Colors.white,
              ),
              title: Text(
                'Add to existing highlight',
                style: IsrStyles.white14,
              ),
              onTap: () => Navigator.of(context).pop('existing'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'create') {
      await _createNewHighlightForStory(
        context: context,
        story: story,
        storyCubit: storyCubit,
      );
      return;
    }

    final highlights = await storyCubit.getHighlightsForCurrentUser();
    if (!context.mounted) return;
    if (highlights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No highlights found. Create one first.')),
      );
      return;
    }
    final selected = await showModalBottomSheet<StoryHighlightData>(
      context: context,
      backgroundColor: const Color(0xFF1D1D1D),
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: highlights.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, index) {
            final highlight = highlights[index];
            return ListTile(
              leading: const Icon(
                Icons.collections_bookmark_outlined,
                color: Colors.white,
              ),
              title: Text(
                highlight.title.isEmpty
                    ? 'Untitled highlight'
                    : highlight.title,
                style: IsrStyles.white14,
              ),
              onTap: () => Navigator.of(context).pop(highlight),
            );
          },
        ),
      ),
    );
    if (!context.mounted || selected == null) return;
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

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D1D),
      builder: (sheetContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
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
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create highlight',
                      style: IsrStyles.white16
                          .copyWith(fontWeight: FontWeight.w600),
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
                                errorBuilder: (_, __, ___) => Container(
                                  width: IsrDimens.fiftySix,
                                  height: IsrDimens.fiftySix,
                                  color: Colors.white12,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            : Image.network(
                                story.mediaUrl,
                                width: IsrDimens.fiftySix,
                                height: IsrDimens.fiftySix,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: IsrDimens.fiftySix,
                                  height: IsrDimens.fiftySix,
                                  color: Colors.white12,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(width: IsrDimens.twelve),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          onChanged: (value) => title = value,
                          style: IsrStyles.primaryText14,
                          decoration: InputDecoration(
                            hintText: 'Highlight name',
                            hintStyle: IsrStyles.primaryText14,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
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
                              if (url == null || url.isEmpty) {
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not upload cover image. Check upload configuration.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: uploadingCover
                          ? SizedBox(
                              width: IsrDimens.sixteen,
                              height: IsrDimens.sixteen,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                      label: Text(
                        uploadingCover
                            ? 'Uploading cover…'
                            : 'Pick cover image',
                        style: IsrStyles.white14,
                      ),
                    ),
                  ),
                  if (pickedCoverUrl != null && pickedCoverUrl!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: uploadingCover
                            ? null
                            : () => setModalState(() => pickedCoverUrl = null),
                        child: Text(
                          'Use story as cover',
                          style: IsrStyles.white14.copyWith(
                            color: Colors.white54,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white54,
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
                          child: Text('Cancel', style: IsrStyles.white14),
                        ),
                      ),
                      SizedBox(width: IsrDimens.twelve),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: uploadingCover
                              ? null
                              : () async {
                                  final highlightTitle = title.trim();
                                  if (highlightTitle.isEmpty) return;
                                  final coverForApi =
                                      pickedCoverUrl ?? story.mediaUrl;
                                  final ok =
                                      await storyCubit.createHighlightWithStories(
                                    title: highlightTitle,
                                    coverUrl: coverForApi,
                                    sortOrder: 0,
                                    storyIds: [story.id],
                                  );
                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop(ok);
                                },
                          child: Text('Create', style: IsrStyles.white14),
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
