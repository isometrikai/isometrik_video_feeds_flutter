/// Stable id for dedupe across cache reads/writes.
String isrFeedPostKey(Map<String, dynamic> post) {
  final id = post['postId'] ??
      post['_id'] ??
      post['id'] ??
      post['post_id'] ??
      post['PostId'] ??
      post['messageId'] ??
      post['message_id'];
  if (id != null) {
    final s = id.toString();
    if (s.isNotEmpty) return s;
  }
  final media = post['media'];
  if (media is List && media.isNotEmpty) {
    final first = media.first;
    if (first is Map) {
      final url = first['url']?.toString() ?? first['preview_url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
  }
  return post.toString().hashCode.toString();
}

/// Resolves author user id from a timeline map payload.
String? isrFeedAuthorUserId(Map<String, dynamic> post) {
  final user = post['user'];
  if (user is Map) {
    final id = user['id'] ?? user['userId'] ?? user['user_id'];
    if (id != null && id.toString().isNotEmpty) return id.toString();
  }
  final direct = post['userId'] ?? post['user_id'];
  if (direct != null && direct.toString().isNotEmpty) {
    return direct.toString();
  }
  return null;
}
