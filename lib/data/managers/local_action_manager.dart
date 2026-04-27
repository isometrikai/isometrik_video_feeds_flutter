class LocalActionManager {
  factory LocalActionManager() => _instance;
  LocalActionManager._internal();

  static final LocalActionManager _instance =
      LocalActionManager._internal();

  final actionExpireDuration = const Duration(seconds: 10);

  /// key => "${viewerId}_${actionType.name}_$relevantId"
  final Map<String, CacheActionState> _cache = {};

  String _key({
    required String viewerId,
    required CacheActionType action,
    required String relevantId,
  }) =>
      '${viewerId.trim()}_${action.name}_$relevantId';

  void storeAction({
    required CacheActionType action,
    required String relevantId,
    Map<String, String>? metaData,
    String viewerId = '',
  }) {
    _removeExpiredActions();

    final normalizedViewerId = viewerId.trim();
    final key = _key(
      viewerId: normalizedViewerId,
      action: action,
      relevantId: relevantId,
    );

    // Remove counterpart if exists for same viewer + target.
    final counterpart = action.counterpart;
    if (counterpart != null) {
      final counterpartKey = _key(
        viewerId: normalizedViewerId,
        action: counterpart,
        relevantId: relevantId,
      );
      _cache.remove(counterpartKey);
    }

    // Store latest action
    _cache[key] = CacheActionState(
      actionType: action,
      relevantId: relevantId,
      timestamp: DateTime.now(),
      metaData: Map<String, String>.from(metaData ?? const {}),
    );
  }

  /// Get latest action for a given entity (post/user) and current viewer.
  CacheActionState? getLatestAction({
    required String relevantId,
    required List<CacheActionType> types,
    String viewerId = '',
  }) {
    _removeExpiredActions();
    final normalizedViewerId = viewerId.trim();

    // Find latest among matching types.
    CacheActionState? latest;

    for (final type in types) {
      final key = _key(
        viewerId: normalizedViewerId,
        action: type,
        relevantId: relevantId,
      );
      final action = _cache[key];

      if (action == null) continue;

      if (latest == null ||
          action.timestamp.isAfter(latest.timestamp)) {
        latest = action;
      }
    }

    return latest;
  }

  void clear() => _cache.clear();

  void clearForViewer(String viewerId) {
    final normalizedViewerId = viewerId.trim();
    if (normalizedViewerId.isEmpty) {
      clear();
      return;
    }
    final keyPrefix = '${normalizedViewerId}_';
    _cache.removeWhere((key, _) => key.startsWith(keyPrefix));
  }

  void _removeExpiredActions() {
    final now = DateTime.now();

    _cache.removeWhere(
      (_, action) => now.difference(action.timestamp) > actionExpireDuration,
    );
  }
}

class CacheActionState {
  CacheActionState({
    required this.actionType,
    required this.timestamp,
    required this.relevantId,
    required this.metaData,
  });

  final CacheActionType actionType;
  final DateTime timestamp;
  final String relevantId;
  final Map<String, String> metaData;

  CacheActionState copyWith({
    DateTime? timestamp,
    Map<String, String>? metaData,
  }) => CacheActionState(
      actionType: actionType,
      relevantId: relevantId,
      timestamp: timestamp ?? this.timestamp,
      metaData: metaData ?? this.metaData,
    );
}

enum CacheActionType {
  followingUser,
  unFollowingUser,
  savePost,
  unSavePost,
  likePost,
  deLikePost,
}

extension LocalActionManagerExtention on String {
  bool? isFollowing({String viewerId = ''}) {
    final manager = LocalActionManager();

    final action = manager.getLatestAction(
      viewerId: viewerId,
      relevantId: this,
      types: [
        CacheActionType.followingUser,
        CacheActionType.unFollowingUser,
      ],
    );

    if (action == null) return null;

    switch (action.actionType) {
      case CacheActionType.followingUser:
        return true;
      case CacheActionType.unFollowingUser:
        return false;
      default:
        return null;
    }
  }

  bool? isLiked({String viewerId = ''}) {
    final manager = LocalActionManager();

    final action = manager.getLatestAction(
      viewerId: viewerId,
      relevantId: this,
      types: [
        CacheActionType.likePost,
        CacheActionType.deLikePost,
      ],
    );

    if (action == null) return null;

    switch (action.actionType) {
      case CacheActionType.likePost:
        return true;
      case CacheActionType.deLikePost:
        return false;
      default:
        return null;
    }
  }

  bool? isSaved({String viewerId = ''}) {
    final manager = LocalActionManager();

    final action = manager.getLatestAction(
      viewerId: viewerId,
      relevantId: this,
      types: [
        CacheActionType.savePost,
        CacheActionType.unSavePost,
      ],
    );

    if (action == null) return null;

    switch (action.actionType) {
      case CacheActionType.savePost:
        return true;
      case CacheActionType.unSavePost:
        return false;
      default:
        return null;
    }
  }
}

extension CacheActionTypeExt on CacheActionType {
  CacheActionType? get counterpart {
    switch (this) {
      case CacheActionType.followingUser:
        return CacheActionType.unFollowingUser;

      case CacheActionType.unFollowingUser:
        return CacheActionType.followingUser;

      case CacheActionType.likePost:
        return CacheActionType.deLikePost;

      case CacheActionType.deLikePost:
        return CacheActionType.likePost;

      case CacheActionType.savePost:
        return CacheActionType.unSavePost;

      case CacheActionType.unSavePost:
        return CacheActionType.savePost;
    }
  }
}