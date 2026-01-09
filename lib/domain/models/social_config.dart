class SocialConfig {
  const SocialConfig({
    this.socialCallBackConfig,
    this.socialUIConfig,
    this.autoMoveToNextPost = true,
  });

  final SocialCallBackConfig? socialCallBackConfig;
  final SocialUIConfig? socialUIConfig;
  final bool autoMoveToNextPost;

  SocialConfig copyWith({
    SocialCallBackConfig? socialCallBackConfig,
    SocialUIConfig? socialUIConfig,
  }) =>
      SocialConfig(
        socialCallBackConfig: socialCallBackConfig ?? this.socialCallBackConfig,
        socialUIConfig: socialUIConfig ?? this.socialUIConfig,
      );
}

class SocialUIConfig {
  const SocialUIConfig();

  SocialUIConfig copyWith() => const SocialUIConfig();
}

class SocialCallBackConfig {
  const SocialCallBackConfig({
    this.onLoginInvoked,
  });

  final Future<bool> Function()? onLoginInvoked;

  SocialCallBackConfig copyWith({
    Future<bool> Function()? onLoginInvoked,
  }) =>
      SocialCallBackConfig(
        onLoginInvoked: onLoginInvoked ?? this.onLoginInvoked,
      );
}
