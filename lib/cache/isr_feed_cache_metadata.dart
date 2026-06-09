/// Pagination / session metadata stored beside posts in Hive.
class IsrFeedCacheMetadata {
  const IsrFeedCacheMetadata({
    required this.hasMore,
    required this.lastFetchedAt,
    required this.ownerKey,
    required this.version,
    this.currentPage,
  });

  final bool hasMore;
  final DateTime lastFetchedAt;
  final String ownerKey;
  final int version;
  final int? currentPage;

  Map<String, dynamic> toJson() => {
        'hasMore': hasMore,
        'lastFetchedAt': lastFetchedAt.toIso8601String(),
        'ownerKey': ownerKey,
        'version': version,
        if (currentPage != null) 'currentPage': currentPage,
      };

  factory IsrFeedCacheMetadata.fromJson(Map<String, dynamic> json) {
    final last = json['lastFetchedAt']?.toString();
    return IsrFeedCacheMetadata(
      hasMore: json['hasMore'] != false,
      lastFetchedAt: last != null && last.isNotEmpty
          ? DateTime.tryParse(last) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      ownerKey: json['ownerKey']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt(),
    );
  }

  IsrFeedCacheMetadata copyWith({
    bool? hasMore,
    DateTime? lastFetchedAt,
    String? ownerKey,
    int? version,
    int? currentPage,
  }) =>
      IsrFeedCacheMetadata(
        hasMore: hasMore ?? this.hasMore,
        lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
        ownerKey: ownerKey ?? this.ownerKey,
        version: version ?? this.version,
        currentPage: currentPage ?? this.currentPage,
      );
}
