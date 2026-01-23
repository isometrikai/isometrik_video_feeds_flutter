class OnShareRequest {

  /// Convert JSON → Object
  factory OnShareRequest.fromJson(Map<String, dynamic> json) => OnShareRequest(
      postId: json['post_id'] as String,
      shareMessage: json['share_message'] as String,
      sharePlatform: json['share_platform'] as String,
      shareType: json['share_type'] as String,
    );

  const OnShareRequest({
    required this.postId,
    required this.shareMessage,
    required this.sharePlatform,
    required this.shareType,
  });
  final String postId;
  final String shareMessage;
  final String sharePlatform;
  final String shareType;

  /// Convert Object → JSON
  Map<String, dynamic> toJson() => {
      'post_id': postId,
      'share_message': shareMessage,
      'share_platform': sharePlatform,
      'share_type': shareType,
    };

  /// Useful for modifying specific fields immutably
  OnShareRequest copyWith({
    String? postId,
    String? shareMessage,
    String? sharePlatform,
    String? shareType,
  }) => OnShareRequest(
      postId: postId ?? this.postId,
      shareMessage: shareMessage ?? this.shareMessage,
      sharePlatform: sharePlatform ?? this.sharePlatform,
      shareType: shareType ?? this.shareType,
    );
}
