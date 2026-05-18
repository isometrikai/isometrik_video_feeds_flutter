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
    this.titleStyle,
    this.showTitles = true,
  });

  final EdgeInsetsGeometry? containerPadding;
  final double? avatarSize;
  final double? itemSpacing;
  final Color? backgroundColor;
  final Color? fullyViewedRingColor;
  final Color? hasUnviewedRingColor;
  final Color? seenBorderColor;
  final Color? unseenBorderColor;
  final TextStyle? titleStyle;
  final bool showTitles;

  StoryUiConfig copyWith({
    EdgeInsetsGeometry? containerPadding,
    double? avatarSize,
    double? itemSpacing,
    Color? backgroundColor,
    Color? fullyViewedRingColor,
    Color? hasUnviewedRingColor,
    Color? seenBorderColor,
    Color? unseenBorderColor,
    TextStyle? titleStyle,
    bool? showTitles,
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
        titleStyle: titleStyle ?? this.titleStyle,
        showTitles: showTitles ?? this.showTitles,
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
