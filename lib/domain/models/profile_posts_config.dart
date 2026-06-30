import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/models/tab_config.dart';
import 'package:ism_video_reel_player/res/constants/asset_constants.dart';

/// Profile posts tab configuration (media/text sub-tabs, empty states, layout).
class ProfilePostsConfig {
  const ProfilePostsConfig({
    this.enablePostTypeTabs = false,
    this.contentHorizontalPadding = 16,
    this.textPostHorizontalPadding = 16,
    this.reelsPlayerOverlayPadding,
    this.tabConfig,
    this.noMediaPostsIcon,
    this.noTextPostsIllustration,
  });

  /// When true, profile posts show Media / Text filter pills (client-side).
  final bool enablePostTypeTabs;

  /// Horizontal inset for media grid and filter pills (from screen edge).
  final double contentHorizontalPadding;

  /// Horizontal inset for text post feed cards (from screen edge, max ~20).
  final double textPostHorizontalPadding;

  /// Optional overlay padding for full-screen player opened from the profile grid.
  final EdgeInsetsGeometry? reelsPlayerOverlayPadding;

  /// Optional tab config for the profile reels player.
  final TabConfig? tabConfig;

  /// Empty-state icon for the media posts filter tab.
  final String? noMediaPostsIcon;

  /// Empty-state illustration for the text posts filter tab.
  final String? noTextPostsIllustration;

  String get resolvedNoMediaPostsIcon =>
      noMediaPostsIcon ?? AssetConstants.icNoProfilePosts;

  String get resolvedNoTextPostsIllustration =>
      noTextPostsIllustration ?? AssetConstants.icNoTextPosts;

  ProfilePostsConfig copyWith({
    bool? enablePostTypeTabs,
    double? contentHorizontalPadding,
    double? textPostHorizontalPadding,
    EdgeInsetsGeometry? reelsPlayerOverlayPadding,
    TabConfig? tabConfig,
    String? noMediaPostsIcon,
    String? noTextPostsIllustration,
  }) =>
      ProfilePostsConfig(
        enablePostTypeTabs: enablePostTypeTabs ?? this.enablePostTypeTabs,
        contentHorizontalPadding:
            contentHorizontalPadding ?? this.contentHorizontalPadding,
        textPostHorizontalPadding:
            textPostHorizontalPadding ?? this.textPostHorizontalPadding,
        reelsPlayerOverlayPadding:
            reelsPlayerOverlayPadding ?? this.reelsPlayerOverlayPadding,
        tabConfig: tabConfig ?? this.tabConfig,
        noMediaPostsIcon: noMediaPostsIcon ?? this.noMediaPostsIcon,
        noTextPostsIllustration:
            noTextPostsIllustration ?? this.noTextPostsIllustration,
      );
}
