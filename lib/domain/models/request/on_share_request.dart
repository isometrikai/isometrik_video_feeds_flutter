class OnShareRequest {

  /// Convert JSON → Object
  factory OnShareRequest.fromJson(Map<String, dynamic> json) => OnShareRequest(
      postId: json['post_id'] as String? ?? '',
      shareMessage: json['share_message'] as String? ?? '',
      sharePlatform: SharePlatform.fromValue(json['share_platform'] as String?),
      shareType: json['share_type'] as String? ?? '',
    );

  const OnShareRequest({
    required this.postId,
    required this.shareMessage,
    required this.sharePlatform,
    required this.shareType,
  });
  final String postId;
  final String shareMessage;
  final SharePlatform sharePlatform;
  final String shareType;

  /// Convert Object → JSON
  Map<String, dynamic> toJson() => {
      'post_id': postId,
      'share_message': shareMessage,
      'share_platform': sharePlatform.value,
      'share_type': shareType,
    };

  /// Useful for modifying specific fields immutably
  OnShareRequest copyWith({
    String? postId,
    String? shareMessage,
    SharePlatform? sharePlatform,
    String? shareType,
  }) => OnShareRequest(
      postId: postId ?? this.postId,
      shareMessage: shareMessage ?? this.shareMessage,
      sharePlatform: sharePlatform ?? this.sharePlatform,
      shareType: shareType ?? this.shareType,
    );
}

enum SharePlatform {
  twitter(['twitter']),
  facebook(['facebook']),
  instagram(['instagram']),
  x(['x', 'twitter_x']),
  telegram(['telegram']),
  whatsapp(['whatsapp', 'wa']),
  email(['email', 'mail']),
  sms(['sms', 'message']),
  other(['other', 'more']);

  const SharePlatform(this.aliases);

  final List<String> aliases;

  String get value => aliases.firstOrNull ?? name.toLowerCase();

  static SharePlatform fromValue(String? value) {
    if (value == null || value.isEmpty) {
      return SharePlatform.other;
    }

    final normalized = value.toLowerCase();

    return SharePlatform.values.firstWhere(
          (e) => e.aliases.any(
            (alias) => alias.toLowerCase() == normalized,
      ),
      orElse: () => SharePlatform.other,
    );
  }
}



