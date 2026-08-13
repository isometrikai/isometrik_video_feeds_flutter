import 'package:ism_video_reel_player/domain/domain.dart';

/// Helpers for post mention / tag payloads.
abstract final class MentionUtil {
  MentionUtil._();

  /// Merges duplicate mentions for the same user into a single API entry.
  ///
  /// When a user is @mentioned in the caption and tagged on media, both
  /// [textPosition] and [mediaPosition] are kept on one [MentionData].
  static List<MentionData> dedupeForApi(List<MentionData> mentions) {
    if (mentions.length <= 1) return List<MentionData>.from(mentions);

    final merged = <String, MentionData>{};

    for (final mention in mentions) {
      final key = _mentionKey(mention);
      final existing = merged[key];
      if (existing == null) {
        merged[key] = mention;
        continue;
      }
      _mergeMention(existing, mention);
    }

    return merged.values.toList(growable: false);
  }

  static String _mentionKey(MentionData mention) {
    final userId = mention.userId?.trim() ?? '';
    if (userId.isNotEmpty) return 'id:$userId';

    final username = (mention.username ?? '').replaceFirst('@', '').trim().toLowerCase();
    if (username.isNotEmpty) return 'user:$username';

    return 'ref:${identityHashCode(mention)}';
  }

  static bool _hasTextPosition(MentionData mention) {
    final textPosition = mention.textPosition;
    if (textPosition == null) return false;
    final start = textPosition.start?.toInt() ?? 0;
    final end = textPosition.end?.toInt() ?? 0;
    return start != 0 || end != 0;
  }

  static bool _hasMediaPosition(MentionData mention) {
    final mediaPosition = mention.mediaPosition;
    if (mediaPosition == null) return false;
    final position = mediaPosition.position?.toInt() ?? 0;
    if (position > 0) return true;
    final x = mediaPosition.x ?? 0;
    final y = mediaPosition.y ?? 0;
    return x != 0 || y != 0;
  }

  static void _mergeMention(MentionData target, MentionData source) {
    if (_hasTextPosition(source)) {
      target.textPosition = source.textPosition;
    }
    if (_hasMediaPosition(source)) {
      target.mediaPosition = source.mediaPosition;
    }

    target.userId = _firstNonEmpty(target.userId, source.userId);
    target.username = _firstNonEmpty(target.username, source.username);
    target.name = _firstNonEmpty(target.name, source.name);
    target.avatarUrl = _firstNonEmpty(target.avatarUrl, source.avatarUrl);
    target.tag = _firstNonEmpty(target.tag, source.tag);
  }

  static String? _firstNonEmpty(String? primary, String? secondary) {
    if (primary?.trim().isNotEmpty == true) return primary;
    if (secondary?.trim().isNotEmpty == true) return secondary;
    return primary ?? secondary;
  }
}
