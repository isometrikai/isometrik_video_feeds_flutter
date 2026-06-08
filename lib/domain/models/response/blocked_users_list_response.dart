import 'dart:convert';

class BlockedUsersListResponse {
  BlockedUsersListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total,
    this.hasMore = false,
  });

  factory BlockedUsersListResponse.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
    final data = map['data'];
    if (data is List) {
      return BlockedUsersListResponse(
        items: _parseItemList(data),
        page: (map['page'] as num?)?.toInt() ?? 1,
        pageSize: (map['page_size'] as num?)?.toInt() ?? 20,
        total: (map['total'] as num?)?.toInt(),
        hasMore: map['has_next'] as bool? ??
            (map['total'] != null
                ? ((map['page'] as num?)?.toInt() ?? 1) *
                        ((map['page_size'] as num?)?.toInt() ?? 20) <
                    (map['total'] as num).toInt()
                : false),
      );
    }
    if (data is Map<String, dynamic>) {
      final rawList = data['items'] ?? data['data'] ?? data['results'];
      final items =
          rawList is List ? _parseItemList(rawList) : <BlockedUserItem>[];
      return BlockedUsersListResponse(
        items: items,
        page: (data['page'] as num?)?.toInt() ?? 1,
        pageSize: (data['page_size'] as num?)?.toInt() ?? 20,
        total: (data['total'] as num?)?.toInt(),
        hasMore: data['has_next'] as bool? ?? false,
      );
    }
    return BlockedUsersListResponse(items: []);
  }

  static List<BlockedUserItem> _parseItemList(List<dynamic> raw) {
    final out = <BlockedUserItem>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        final item = BlockedUserItem.tryParse(e);
        if (item != null) {
          out.add(item);
        }
      }
    }
    return out;
  }

  final List<BlockedUserItem> items;
  final int page;
  final int pageSize;
  final int? total;
  final bool hasMore;

  Map<String, dynamic> toMap() => {
        'data': items.map((e) => e.toMap()).toList(),
        'page': page,
        'page_size': pageSize,
        if (total != null) 'total': total,
        'has_next': hasMore,
      };
}

class BlockedUserItem {
  BlockedUserItem({
    required this.userId,
    required this.username,
    this.displayName,
    this.fullName,
    this.avatarUrl,
    this.blockedAt,
    this.reason,
  });

  static BlockedUserItem? tryParse(Map<String, dynamic> map) {
    final userId = map['user_id'] as String? ??
        map['id'] as String? ??
        map['blocked_id'] as String? ??
        '';
    if (userId.isEmpty) return null;

    return BlockedUserItem(
      userId: userId,
      username: map['username'] as String? ?? '',
      displayName: map['display_name'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      blockedAt: map['blocked_at'] as String?,
      reason: map['reason'] as String?,
    );
  }

  final String userId;
  final String username;
  final String? displayName;
  final String? fullName;
  final String? avatarUrl;
  final String? blockedAt;
  final String? reason;

  String get displayLabel {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (username.isNotEmpty) return username;
    return 'Unknown user';
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'username': username,
        if (displayName != null) 'display_name': displayName,
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (blockedAt != null) 'blocked_at': blockedAt,
        if (reason != null) 'reason': reason,
      };
}
