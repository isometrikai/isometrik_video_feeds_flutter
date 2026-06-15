/// One cached post row (JSON payload matches [TimeLineData.toMap] shape).
class IsrFeedCacheEntry {
  const IsrFeedCacheEntry({
    required this.postId,
    required this.payload,
    required this.insertedAt,
  });

  final String postId;
  final Map<String, dynamic> payload;
  final DateTime insertedAt;

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'payload': payload,
        'insertedAt': insertedAt.toIso8601String(),
      };

  factory IsrFeedCacheEntry.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['payload'];
    final payload = payloadRaw is Map<String, dynamic>
        ? payloadRaw
        : Map<String, dynamic>.from(payloadRaw as Map? ?? const {});
    final inserted = json['insertedAt']?.toString();
    return IsrFeedCacheEntry(
      postId: json['postId']?.toString() ?? '',
      payload: payload,
      insertedAt: inserted != null && inserted.isNotEmpty
          ? DateTime.tryParse(inserted) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
