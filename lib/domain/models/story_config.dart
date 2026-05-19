import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/enums.dart' show MediaType;

class StoryConfig {
  const StoryConfig({
    this.storyUiConfig = const StoryUiConfig(),
    this.storyCallbackConfig = const StoryCallbackConfig(),
    this.uploadMode = StoryUploadMode.hostProvidedUrl,
    this.uploadMediaToCloud,
  });

  final StoryUiConfig storyUiConfig;
  final StoryCallbackConfig storyCallbackConfig;

  final StoryUploadMode uploadMode;
  final Future<String> Function(
    File? file,
    String fileName,
    MediaType? mediaType,
    void Function(double) progressCallBackFunction,
    String folderName,
    String fileExtension,
  )? uploadMediaToCloud;

  StoryConfig copyWith({
    StoryUiConfig? storyUiConfig,
    StoryCallbackConfig? storyCallbackConfig,
    StoryUploadMode? uploadMode,
    Future<String> Function(
      File? file,
      String fileName,
      MediaType? mediaType,
      void Function(double) progressCallBackFunction,
      String folderName,
      String fileExtension,
    )? uploadMediaToCloud,
  }) =>
      StoryConfig(
        storyUiConfig: storyUiConfig ?? this.storyUiConfig,
        storyCallbackConfig: storyCallbackConfig ?? this.storyCallbackConfig,
        uploadMode: uploadMode ?? this.uploadMode,
        uploadMediaToCloud: uploadMediaToCloud ?? this.uploadMediaToCloud,
      );
}

class StoryUiConfig {
  const StoryUiConfig({
    this.containerPadding,
    this.avatarSize,
    this.itemSpacing,
    this.backgroundColor,
    this.fullyViewedRingColor,
    this.hasUnviewedRingColor,
    this.seenBorderColor,
    this.unseenBorderColor,
    this.unseenRingGradientColors,
    this.titleStyle,
    this.addStoryLabelStyle,
    this.addStoryAccentColor,
    this.addStoryTitle,
    this.showTitles = true,
    this.showAddStoryTile = true,
    this.bottomSheetBackgroundColor,
    this.bottomSheetTextColor,
    this.bottomSheetSecondaryTextColor,
    this.destructiveColor,
    this.successColor,
    this.primaryButtonColor,
    this.onPrimaryButtonColor,
  });

  final EdgeInsetsGeometry? containerPadding;
  final double? avatarSize;
  final double? itemSpacing;
  final Color? backgroundColor;
  final Color? fullyViewedRingColor;
  final Color? hasUnviewedRingColor;
  final Color? seenBorderColor;
  final Color? unseenBorderColor;
  /// Gradient colors for unviewed story / highlight rings (host theme).
  final List<Color>? unseenRingGradientColors;
  final TextStyle? titleStyle;
  final TextStyle? addStoryLabelStyle;
  final Color? addStoryAccentColor;
  final String? addStoryTitle;
  final bool showTitles;
  /// When true, shows the first "Add Story" tile with a + badge on the strip.
  final bool showAddStoryTile;
  final Color? bottomSheetBackgroundColor;
  final Color? bottomSheetTextColor;
  final Color? bottomSheetSecondaryTextColor;
  final Color? destructiveColor;
  final Color? successColor;
  final Color? primaryButtonColor;
  final Color? onPrimaryButtonColor;

  StoryUiConfig copyWith({
    EdgeInsetsGeometry? containerPadding,
    double? avatarSize,
    double? itemSpacing,
    Color? backgroundColor,
    Color? fullyViewedRingColor,
    Color? hasUnviewedRingColor,
    Color? seenBorderColor,
    Color? unseenBorderColor,
    List<Color>? unseenRingGradientColors,
    TextStyle? titleStyle,
    TextStyle? addStoryLabelStyle,
    Color? addStoryAccentColor,
    String? addStoryTitle,
    bool? showTitles,
    bool? showAddStoryTile,
    Color? bottomSheetBackgroundColor,
    Color? bottomSheetTextColor,
    Color? bottomSheetSecondaryTextColor,
    Color? destructiveColor,
    Color? successColor,
    Color? primaryButtonColor,
    Color? onPrimaryButtonColor,
  }) =>
      StoryUiConfig(
        containerPadding: containerPadding ?? this.containerPadding,
        avatarSize: avatarSize ?? this.avatarSize,
        itemSpacing: itemSpacing ?? this.itemSpacing,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        fullyViewedRingColor: fullyViewedRingColor ?? this.fullyViewedRingColor,
        hasUnviewedRingColor: hasUnviewedRingColor ?? this.hasUnviewedRingColor,
        seenBorderColor: seenBorderColor ?? this.seenBorderColor,
        unseenBorderColor: unseenBorderColor ?? this.unseenBorderColor,
        unseenRingGradientColors:
            unseenRingGradientColors ?? this.unseenRingGradientColors,
        titleStyle: titleStyle ?? this.titleStyle,
        addStoryLabelStyle: addStoryLabelStyle ?? this.addStoryLabelStyle,
        addStoryAccentColor: addStoryAccentColor ?? this.addStoryAccentColor,
        addStoryTitle: addStoryTitle ?? this.addStoryTitle,
        showTitles: showTitles ?? this.showTitles,
        showAddStoryTile: showAddStoryTile ?? this.showAddStoryTile,
        bottomSheetBackgroundColor:
            bottomSheetBackgroundColor ?? this.bottomSheetBackgroundColor,
        bottomSheetTextColor:
            bottomSheetTextColor ?? this.bottomSheetTextColor,
        bottomSheetSecondaryTextColor: bottomSheetSecondaryTextColor ??
            this.bottomSheetSecondaryTextColor,
        destructiveColor: destructiveColor ?? this.destructiveColor,
        successColor: successColor ?? this.successColor,
        primaryButtonColor: primaryButtonColor ?? this.primaryButtonColor,
        onPrimaryButtonColor:
            onPrimaryButtonColor ?? this.onPrimaryButtonColor,
      );
}

enum StoryUploadMode {
  sdkManagedGoogleCloud,
  hostProvidedUrl,
}

class StoryUploadPayload {
  const StoryUploadPayload({
    this.file,
    this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.expiresInHours,
    required this.mediaPosition,
    this.assetId,
    this.description,
    this.extraData,
    this.privacy,
    this.soundId,
    this.soundSnapshot,
    this.tags,
    this.textFormatting,
    this.videoDurationSeconds,
  });

  final File? file;
  final String? mediaUrl;
  final String mediaType;
  final String? caption;
  final int? expiresInHours;
  final int mediaPosition;
  final String? assetId;
  final String? description;
  final Map<String, dynamic>? extraData;
  final String? privacy;
  final String? soundId;
  final Map<String, dynamic>? soundSnapshot;
  final Map<String, dynamic>? tags;
  final Map<String, dynamic>? textFormatting;
  final int? videoDurationSeconds;
}

class StoryCallbackConfig {
  const StoryCallbackConfig({
    this.onStoryTap,
    this.onCreateStoryTap,
    this.navigateToCreateStory,
    this.onRequestStoryUploadPayload,
    this.uploadMediaToCloud,
    this.onStoryFeedLoaded,
    this.onStoryActionError,
    this.onHighlightTap,
    this.onHighlightOpenDiagnostics,
    this.onHighlightsChanged,
    this.resolveCurrentUserAvatarUrl,
    this.onReportStory,
    this.uploadMode = StoryUploadMode.hostProvidedUrl,
  });

  final Future<void> Function(StoryData story)? onStoryTap;

  final Future<void> Function()? onCreateStoryTap;

  final Future<void> Function(BuildContext context)? navigateToCreateStory;

  final Future<StoryUploadPayload?> Function()? onRequestStoryUploadPayload;

  final Future<String> Function(
    File? file,
    String fileName,
    MediaType? mediaType,
    void Function(double) progressCallBackFunction,
    String folderName,
    String fileExtension,
  )? uploadMediaToCloud;

  final void Function(List<StoryGroup> storyGroups)? onStoryFeedLoaded;
  final void Function(String action, String message)? onStoryActionError;
  final Future<void> Function(StoryHighlightData highlight)? onHighlightTap;
  final void Function(HighlightOpenDiagnostics diagnostics)?
      onHighlightOpenDiagnostics;
  /// Host app should refresh profile highlight strip / list.
  final void Function()? onHighlightsChanged;
  /// Host provides the signed-in user's profile image for the Add Story tile.
  final Future<String?> Function()? resolveCurrentUserAvatarUrl;
  /// Called when a viewer reports someone else's story (not shown for own stories).
  final Future<void> Function(StoryData story)? onReportStory;
  final StoryUploadMode uploadMode;
}

class HighlightOpenDiagnostics {
  const HighlightOpenDiagnostics({
    required this.highlightId,
    required this.targetStoryIds,
    required this.resolvedStoryIds,
    required this.stepsAttempted,
    required this.reason,
    required this.opened,
  });

  final String highlightId;
  final List<String> targetStoryIds;
  final List<String> resolvedStoryIds;
  final List<String> stepsAttempted;
  final String reason;
  final bool opened;
}
