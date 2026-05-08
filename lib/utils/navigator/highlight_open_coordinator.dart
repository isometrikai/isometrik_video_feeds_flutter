import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/domain/models/models.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/utils/navigator/highlight_viewer_resolver.dart';

class HighlightOpenCoordinator {
  const HighlightOpenCoordinator._();

  static Future<({HighlightOpenResult result, StoryGroup? group})> resolve({
    required StoryCubit cubit,
    required String highlightId,
    String? userId,
    List<String>? storyIds,
  }) async {
    final callback =
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryActionError;
    final diagnosticsCb = IsrVideoReelConfig
        .storyConfig?.storyCallbackConfig.onHighlightOpenDiagnostics;
    final normalizedHighlightId = highlightId.trim();
    final steps = <String>[];

    void emitDiagnostics({
      required String reason,
      required bool opened,
      List<String> targetIds = const [],
      List<String> resolvedIds = const [],
    }) {
      diagnosticsCb?.call(
        HighlightOpenDiagnostics(
          highlightId: normalizedHighlightId,
          targetStoryIds: targetIds,
          resolvedStoryIds: resolvedIds,
          stepsAttempted: steps.toList(),
          reason: reason,
          opened: opened,
        ),
      );
    }

    if (normalizedHighlightId.isEmpty) {
      const reason = 'Highlight id is required.';
      callback?.call('open_highlight_viewer', reason);
      emitDiagnostics(reason: reason, opened: false);
      return (
        result: HighlightOpenResult(
          opened: false,
          reason: reason,
          resolvedStoryCount: 0,
          highlightId: normalizedHighlightId,
        ),
        group: null,
      );
    }

    steps.add('resolve_target_ids');
    final idsFromInput =
        HighlightViewerResolver.normalizedStoryIds(storyIds ?? const []);
    var highlightData =
        await cubit.getStoryHighlightById(normalizedHighlightId);
    final idsFromServer = HighlightViewerResolver.normalizedStoryIds(
      (highlightData?.items ?? const <StoryHighlightItem>[])
          .map((item) => item.storyId),
    );
    final targetIds = idsFromServer.isNotEmpty ? idsFromServer : idsFromInput;
    debugPrint(
      'HighlightOpenCoordinator: resolved ids input=${idsFromInput.length} server=${idsFromServer.length}',
    );

    if (targetIds.isEmpty) {
      steps.add('target_ids_empty');
      const reason = 'No stories available for selected highlight.';
      callback?.call('open_highlight_viewer', reason);
      emitDiagnostics(reason: reason, opened: false);
      return (
        result: HighlightOpenResult(
          opened: false,
          reason: reason,
          resolvedStoryCount: 0,
          highlightId: normalizedHighlightId,
        ),
        group: null,
      );
    }

    steps.add('resolve_from_cached_feed');
    final cachedStories =
        HighlightViewerResolver.storiesFromGroups(cubit.cachedStoryGroups);
    var resolvedStories = HighlightViewerResolver.resolveStoriesByIds(
      stories: cachedStories,
      storyIds: targetIds,
    );

    if (resolvedStories.isEmpty && (userId ?? '').trim().isNotEmpty) {
      steps.add('resolve_from_user_stories');
      final userStories = await cubit.getStoriesByUserId(userId!.trim());
      resolvedStories = HighlightViewerResolver.resolveStoriesByIds(
        stories: userStories,
        storyIds: targetIds,
      );
    }

    if (resolvedStories.isEmpty) {
      steps.add('resolve_after_feed_refresh');
      await cubit.loadStoryFeed(isLoading: false);
      final refreshedStories =
          HighlightViewerResolver.storiesFromGroups(cubit.cachedStoryGroups);
      resolvedStories = HighlightViewerResolver.resolveStoriesByIds(
        stories: refreshedStories,
        storyIds: targetIds,
      );
    }

    if (resolvedStories.isEmpty) {
      steps.add('resolve_from_story_detail');
      final fetchedStories = <StoryData>[];
      for (final storyId in targetIds) {
        final detail = await cubit.getStoryDetailById(storyId);
        if (detail != null) fetchedStories.add(detail);
      }
      resolvedStories = HighlightViewerResolver.resolveStoriesByIds(
        stories: fetchedStories,
        storyIds: targetIds,
      );
    }

    if (resolvedStories.isEmpty) {
      steps.add('resolve_failed_no_active_story');
      const reason = 'Highlight exists but has no active stories to show.';
      callback?.call('open_highlight_viewer', reason);
      emitDiagnostics(
        reason: reason,
        opened: false,
        targetIds: targetIds,
      );
      return (
        result: HighlightOpenResult(
          opened: false,
          reason: reason,
          resolvedStoryCount: 0,
          highlightId: normalizedHighlightId,
          targetStoryIds: targetIds,
          stepsAttempted: steps,
        ),
        group: null,
      );
    }

    steps.add('build_group');
    final effectiveUserId = (userId ?? highlightData?.userId ?? '').trim();
    final group = StoryGroup(
      userId: effectiveUserId,
      username: highlightData?.title ?? '',
      avatarUrl: highlightData?.coverUrl ?? resolvedStories.first.avatarUrl,
      stories: resolvedStories,
    );

    final resolvedIds = resolvedStories
        .map((story) => HighlightViewerResolver.normalizeStoryId(story.id))
        .where((id) => id.isNotEmpty)
        .toList();
    const reason = 'Highlight opened successfully.';
    emitDiagnostics(
      reason: reason,
      opened: true,
      targetIds: targetIds,
      resolvedIds: resolvedIds,
    );
    return (
      result: HighlightOpenResult(
        opened: true,
        reason: reason,
        resolvedStoryCount: resolvedStories.length,
        highlightId: normalizedHighlightId,
        targetStoryIds: targetIds,
        resolvedStoryIds: resolvedIds,
        stepsAttempted: steps,
      ),
      group: group,
    );
  }
}
