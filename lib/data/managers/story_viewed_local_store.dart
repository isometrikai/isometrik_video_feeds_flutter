import 'package:ism_video_reel_player/data/managers/local_storage_keys.dart';
import 'package:ism_video_reel_player/data/managers/local_storage_manager.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Persists story IDs the user has opened so rings stay "seen" after app restart.
class StoryViewedLocalStore {
  StoryViewedLocalStore([LocalStorageManager? storage])
      : _storage = storage ??
            IsmInjectionUtils.getOtherClass<LocalStorageManager>();

  final LocalStorageManager _storage;

  String _key(String userId) => '${LocalStorageKeys.viewedStoryIds}_$userId';

  Set<String> readStoryIds(String userId) {
    if (userId.isEmpty) return {};
    final raw = _storage.getValue(_key(userId), SavedValueDataType.stringList);
    if (raw is! List) return {};
    return raw
        .map((e) => e.toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> addStoryId(String userId, String storyId) async {
    if (userId.isEmpty || storyId.isEmpty) return;
    final ids = readStoryIds(userId)..add(storyId);
    await _storage.saveValue(
      _key(userId),
      ids.toList(),
      SavedValueDataType.stringList,
    );
  }

  Future<void> pruneStoryIds(String userId, Set<String> activeStoryIds) async {
    if (userId.isEmpty) return;
    final ids = readStoryIds(userId);
    final pruned = ids.where(activeStoryIds.contains).toSet();
    if (pruned.length == ids.length) return;
    await _storage.saveValue(
      _key(userId),
      pruned.toList(),
      SavedValueDataType.stringList,
    );
  }
}
