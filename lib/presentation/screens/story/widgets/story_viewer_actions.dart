import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    required String? highlightId,
    required VoidCallback onAdvanceAfterMutation,
  }) async {
    if (story == null || story.id.isEmpty || !canManageCurrentStory) return;
    final storyCubit = context.read<StoryCubit>();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1D1D1D),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(Icons.bookmark_add_outlined, color: IsrColors.white),
              title: Text(
                'Add to highlight',
                style: IsrStyles.white14,
              ),
              onTap: () => Navigator.of(context).pop('add_to_highlight'),
            ),
            if ((highlightId ?? '').trim().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent),
                title: Text(
                  'Remove from highlight',
                  style: IsrStyles.white14.copyWith(color: Colors.redAccent),
                ),
                onTap: () => Navigator.of(context).pop('remove_from_highlight'),
              )
            else
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  'Delete story',
                  style: IsrStyles.white14.copyWith(color: Colors.redAccent),
                ),
                onTap: () => Navigator.of(context).pop('delete_story'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'add_to_highlight') {
      await _addToHighlight(
          context: context, story: story, storyCubit: storyCubit);
      return;
    }
    if (action == 'remove_from_highlight') {
      final targetHighlightId = highlightId?.trim() ?? '';
      if (targetHighlightId.isEmpty) return;
      await storyCubit.removeStoryFromHighlight(
        highlightId: targetHighlightId,
        storyId: story.id,
      );
      if (!context.mounted) return;
      onAdvanceAfterMutation();
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
    final callback =
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onHighlightTap;
    if (callback != null) {
      await callback(selected);
    }
    if (!context.mounted) return;
    await storyCubit.addStoryToHighlight(
        highlightId: selected.id, storyId: story.id);
  }

  static Future<void> _createNewHighlightForStory({
    required BuildContext context,
    required StoryData story,
    required StoryCubit storyCubit,
  }) async {
    var title = '';
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D1D),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
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
                    style:
                        IsrStyles.white16.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: IsrDimens.twelve),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(IsrDimens.eight),
                      child: Image.network(
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
                SizedBox(height: IsrDimens.sixteen),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel', style: IsrStyles.white14),
                      ),
                    ),
                    SizedBox(width: IsrDimens.twelve),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final highlightTitle = title.trim();
                          if (highlightTitle.isEmpty) return;
                          final created =
                              await storyCubit.createHighlightWithStories(
                            title: highlightTitle,
                            coverUrl: story.mediaUrl,
                            sortOrder: 0,
                            storyIds: [story.id],
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop(created);
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
    );
    if (!context.mounted || created != true) return;
    final highlights = await storyCubit.getHighlightsForCurrentUser();
    if (!context.mounted) return;
    final callback =
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onHighlightTap;
    if (callback != null) {
      final matched = highlights.where((h) {
        final hasStory = h.items.any((item) => item.storyId == story.id);
        if (!hasStory) return false;
        return h.coverUrl == story.mediaUrl || h.title == title.trim();
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
