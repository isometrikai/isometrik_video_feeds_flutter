import 'package:ism_video_reel_player/domain/models/models.dart';

class HighlightViewerResolver {
  const HighlightViewerResolver._();

  static String normalizeStoryId(String? id) => (id ?? '').trim();

  static List<String> normalizedStoryIds(Iterable<String?> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      final normalized = normalizeStoryId(id);
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      out.add(normalized);
    }
    return out;
  }

  static List<StoryData> storiesFromGroups(List<StoryGroup> groups) =>
      groups.expand((group) => group.stories).toList();

  static List<StoryData> resolveStoriesByIds({
    required List<StoryData> stories,
    required List<String> storyIds,
  }) {
    if (stories.isEmpty || storyIds.isEmpty) return const [];
    final byId = <String, StoryData>{};
    for (final story in stories) {
      final id = normalizeStoryId(story.id);
      if (id.isEmpty) continue;
      byId[id] = story;
    }

    final resolved = <StoryData>[];
    for (final id in normalizedStoryIds(storyIds)) {
      final story = byId[id];
      if (story == null) continue;
      if (story.mediaUrl.trim().isEmpty) continue;
      resolved.add(story);
    }
    return resolved;
  }
}
