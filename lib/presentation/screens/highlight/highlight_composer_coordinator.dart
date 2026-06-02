import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/create_highlight_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/highlight_choice_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/highlight_story_item.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/pick_existing_highlight_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/pick_stories_for_highlight_screen.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';

/// Orchestrates pick stories → create new or add to existing → highlight APIs.
class HighlightComposerCoordinator {
  HighlightComposerCoordinator._();

  static Future<void> run({
    required BuildContext context,
    required StoryCubit cubit,
    StoryData? seedStory,
    List<String>? preselectedStoryIds,
    bool openViewerAfterAdd = false,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    final selected = await _resolveSelectedStories(
      context: context,
      cubit: cubit,
      seedStory: seedStory,
      preselectedStoryIds: preselectedStoryIds,
      messenger: messenger,
    );
    if (!context.mounted || selected == null || selected.isEmpty) return;

    final storyIds = selected
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (storyIds.isEmpty) return;

    final coverUrl = selected.first.thumbUrl;

    if (!context.mounted) return;
    final choice = await HighlightChoiceScreen.push(context);
    if (!context.mounted || choice == null) return;

    if (choice == 'create') {
      final created = await _pushWithCubit<bool>(
        context,
        cubit,
        CreateHighlightScreen(
          storyIds: storyIds,
          initialCoverUrl: coverUrl,
        ),
      );
      if (!context.mounted) return;
      if (created == true) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Highlight created.')),
        );
      }
      return;
    }

    if (choice != 'existing') return;

    final highlights = await cubit.getHighlightsForCurrentUser();
    if (!context.mounted) return;
    if (highlights.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('No highlights yet. Create one first.')),
      );
      return;
    }

    if (!context.mounted) return;
    final chosen = await PickExistingHighlightScreen.push(
      context,
      highlights: highlights,
    );
    if (!context.mounted || chosen == null) return;

    final ok = await cubit.addStoriesToHighlight(
      highlightId: chosen.id,
      storyIds: storyIds,
    );
    if (!context.mounted) return;
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not add stories to highlight')),
      );
      return;
    }

    messenger?.showSnackBar(
      const SnackBar(content: Text('Added to highlight.')),
    );

    if (!openViewerAfterAdd) return;

    final detail = await cubit.getStoryHighlightById(chosen.id);
    if (!context.mounted) return;

    final storyIdsForViewer = _storyIdsForViewer(
      detail: detail,
      highlight: chosen,
      addedIds: storyIds,
    );

    final viewerUserId = (detail?.userId.trim().isNotEmpty ?? false)
        ? detail!.userId.trim()
        : chosen.userId.trim();

    await IsrAppNavigator.presentHighlightViewer(
      context,
      highlightId: chosen.id,
      userId: viewerUserId.isNotEmpty ? viewerUserId : null,
      storyIds: storyIdsForViewer,
      highlightPreview: detail ?? chosen,
    );
  }

  static Future<List<HighlightStoryItem>?> _resolveSelectedStories({
    required BuildContext context,
    required StoryCubit cubit,
    StoryData? seedStory,
    List<String>? preselectedStoryIds,
    ScaffoldMessengerState? messenger,
  }) async {
    if (seedStory != null) {
      return [HighlightStoryItem.fromStory(seedStory)];
    }

    final myStories = await cubit.getMyStories();
    if (!context.mounted) return null;

    if (myStories == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not load stories')),
      );
      return null;
    }

    if (myStories.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('No stories to add to a highlight yet')),
      );
      return null;
    }

    final allItems =
        myStories.map(HighlightStoryItem.fromStory).toList(growable: false);

    if (preselectedStoryIds != null && preselectedStoryIds.isNotEmpty) {
      final idSet = preselectedStoryIds.map((e) => e.trim()).toSet();
      final filtered =
          allItems.where((s) => idSet.contains(s.id.trim())).toList();
      if (filtered.isNotEmpty) return filtered;
    }

    if (!context.mounted) return null;
    return PickStoriesForHighlightScreen.push(
      context,
      stories: allItems,
    );
  }

  /// Adds archived stories to an existing highlight (profile empty state / +).
  static Future<bool> addStoriesToHighlight({
    required BuildContext context,
    required StoryCubit cubit,
    required StoryHighlightData highlight,
    bool openViewerAfterAdd = false,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final highlightId = highlight.id.trim();
    if (highlightId.isEmpty) return false;

    final selected = await _resolveSelectedStories(
      context: context,
      cubit: cubit,
      messenger: messenger,
    );
    if (!context.mounted || selected == null || selected.isEmpty) return false;

    final storyIds = selected
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (storyIds.isEmpty) return false;

    final ok = await cubit.addStoriesToHighlight(
      highlightId: highlightId,
      storyIds: storyIds,
    );
    if (!context.mounted) return false;
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not add stories to highlight')),
      );
      return false;
    }

    messenger?.showSnackBar(
      const SnackBar(content: Text('Added to highlight.')),
    );

    if (!openViewerAfterAdd) return true;

    final detail = await cubit.getStoryHighlightById(highlightId);
    if (!context.mounted) return true;

    final storyIdsForViewer = _storyIdsForViewer(
      detail: detail,
      highlight: highlight,
      addedIds: storyIds,
    );

    final viewerUserId = (detail?.userId.trim().isNotEmpty ?? false)
        ? detail!.userId.trim()
        : highlight.userId.trim();

    await IsrAppNavigator.presentHighlightViewer(
      context,
      highlightId: highlightId,
      userId: viewerUserId.isNotEmpty ? viewerUserId : null,
      storyIds: storyIdsForViewer,
    );
    return true;
  }

  static List<String> _storyIdsForViewer({
    required StoryHighlightData? detail,
    required StoryHighlightData highlight,
    required List<String> addedIds,
  }) {
    if (detail?.embeddedStories.isNotEmpty ?? false) {
      return detail!.embeddedStories
          .map((s) => s.id.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (detail?.items.isNotEmpty ?? false) {
      return detail!.items
          .map((e) => e.storyId.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>{
      ...highlight.items.map((e) => e.storyId.trim()).where((e) => e.isNotEmpty),
      ...addedIds,
    }.toList();
  }

  static Future<T?> _pushWithCubit<T>(
    BuildContext context,
    StoryCubit cubit,
    Widget child,
  ) =>
      Navigator.of(context, rootNavigator: true).push<T>(
        MaterialPageRoute<T>(
          builder: (_) => BlocProvider<StoryCubit>.value(
            value: cubit,
            child: child,
          ),
          fullscreenDialog: true,
        ),
      );
}
