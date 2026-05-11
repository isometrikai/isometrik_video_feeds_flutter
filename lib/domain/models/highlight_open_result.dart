/// Result contract returned by highlight open helpers.
class HighlightOpenResult {
  const HighlightOpenResult({
    required this.opened,
    required this.reason,
    required this.resolvedStoryCount,
    required this.highlightId,
    this.targetStoryIds = const [],
    this.resolvedStoryIds = const [],
    this.stepsAttempted = const [],
  });

  final bool opened;
  final String reason;
  final int resolvedStoryCount;
  final String highlightId;
  final List<String> targetStoryIds;
  final List<String> resolvedStoryIds;
  final List<String> stepsAttempted;
}

