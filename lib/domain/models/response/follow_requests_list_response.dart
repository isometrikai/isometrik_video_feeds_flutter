import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

class FollowRequestsListResponse {
  FollowRequestsListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total,
    this.hasMore = false,
  });

  factory FollowRequestsListResponse.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      return FollowRequestsListResponse._fromDataMap(data);
    }
    if (data is List) {
      return FollowRequestsListResponse(
        items: _parseItemList(data),
        hasMore: false,
      );
    }
    return FollowRequestsListResponse(items: []);
  }

  factory FollowRequestsListResponse._fromDataMap(Map<String, dynamic> data) {
    final rawList =
        data['items'] ?? data['requests'] ?? data['data'] ?? data['results'];
    final items =
        rawList is List ? _parseItemList(rawList) : <FollowRequestItem>[];

    final page = (data['page'] as num?)?.toInt() ??
        (data['current_page'] as num?)?.toInt() ??
        1;
    final pageSize = (data['page_size'] as num?)?.toInt() ??
        (data['limit'] as num?)?.toInt() ??
        20;
    final total = (data['total'] as num?)?.toInt() ??
        (data['total_count'] as num?)?.toInt();
    final hasNext = data['has_next'] as bool? ??
        data['has_more'] as bool? ??
        (total != null ? page * pageSize < total : items.length >= pageSize);

    return FollowRequestsListResponse(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      hasMore: hasNext,
    );
  }

  static List<FollowRequestItem> _parseItemList(List<dynamic> raw) {
    final out = <FollowRequestItem>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        final item = FollowRequestItem.tryParse(e);
        if (item != null) {
          out.add(item);
        }
      }
    }
    return out;
  }

  final List<FollowRequestItem> items;
  final int page;
  final int pageSize;
  final int? total;
  final bool hasMore;
}

/// Single follow request row from API.
class FollowRequestItem {
  FollowRequestItem({
    required this.id,
    required this.user,
  });

  static FollowRequestItem? tryParse(Map<String, dynamic> map) {
    final id = map['id'] as String? ??
        map['request_id'] as String? ??
        map['follow_request_id'] as String? ??
        '';
    if (id.isEmpty) return null;

    final userMap = _userMapFrom(map);
    if (userMap == null) return null;

    return FollowRequestItem(
      id: id,
      user: SocialUserData.fromMap(userMap),
    );
  }

  static Map<String, dynamic>? _userMapFrom(Map<String, dynamic> map) {
    if (map['user'] is Map<String, dynamic>) {
      return map['user'] as Map<String, dynamic>;
    }
    if (map['follower'] is Map<String, dynamic>) {
      return map['follower'] as Map<String, dynamic>;
    }
    if (map['followee'] is Map<String, dynamic>) {
      return map['followee'] as Map<String, dynamic>;
    }
    if (map['following'] is Map<String, dynamic>) {
      return map['following'] as Map<String, dynamic>;
    }
    if (map['target'] is Map<String, dynamic>) {
      return map['target'] as Map<String, dynamic>;
    }
    if (map['target_user'] is Map<String, dynamic>) {
      return map['target_user'] as Map<String, dynamic>;
    }
    // Flat user fields on the request object
    if (map['username'] != null || map['id'] != null) {
      final m = Map<String, dynamic>.from(map);
      m.remove('request_id');
      m.remove('follow_request_id');
      return m;
    }
    return null;
  }

  final String id;
  final SocialUserData user;
}

abstract class FollowRelationshipStatus {
  static const int none = 0;
  static const int following = 1;
  static const int requested = 2;

  /// Prefer numeric [`follow_status`]; string enums like `request_pending`; then [`follow_relationship`].
  static num? parseFromApiFields({
    dynamic followStatus,
    dynamic followRelationship,
  }) {
    if (followStatus is num) return followStatus;

    if (followStatus is String) {
      final trimmed = followStatus.trim();
      final asNum = num.tryParse(trimmed);
      if (asNum != null) return asNum;
      final fromStatus = parseRelationshipString(trimmed);
      if (fromStatus != null) return fromStatus;
    }

    return parseRelationshipString(followRelationship);
  }

  static num? parseRelationshipString(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw;
    final s = raw.toString().trim().toLowerCase().replaceAll('-', '_');
    switch (s) {
      case '':
      case 'none':
      case 'not_following':
        return none;
      case 'following':
      case 'follows':
      case 'followed':
      case 'accepted':
        return following;
      case 'requested':
      case 'request_pending':
      case 'follow_request_pending':
      case 'pending_out':
      case 'pending_sent':
      case 'outgoing':
      case 'outgoing_pending':
      case 'sent':
        return requested;
      case 'pending_in':
      case 'incoming':
      case 'pending_received':
      case 'request_received':
        return none;
    }
    return null;
  }
}
