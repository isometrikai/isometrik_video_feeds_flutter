import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

import 'media_selection.dart';

class MediaSelectionConfig {
  MediaSelectionConfig({
    //colors
    Color? primaryColor,
    this.primaryTextColor = MediaSelectionConstant.primaryTextColor,
    this.backgroundColor = MediaSelectionConstant.backgroundColor,
    this.appBarColor = MediaSelectionConstant.appBarColor,

    //styles
    this.primaryFontFamily = MediaSelectionConstant.primaryFontFamily,

    //icons
    Widget? closeIcon,
    Widget? cameraIcon,
    Widget? videoIcon,
    Widget? playIcon,
    Widget? pauseIcon,
    Widget? singleSelectModeIcon,
    Widget? multiSelectModeIcon,

    //text
    this.selectMediaTitle = MediaSelectionConstant.selectMediaTitle,
    this.doneButtonText = MediaSelectionConstant.doneButtonText,

    //options
    this.isMultiSelect = MediaSelectionConstant.isMultiSelect,
    this.videoMediaLimit = MediaSelectionConstant.videoMediaLimit,
    this.imageMediaLimit = MediaSelectionConstant.imageMediaLimit,
    this.mediaLimit = MediaSelectionConstant.mediaLimit,
    this.thumbnailQuality = MediaSelectionConstant.thumbnailQuality,
    this.videoMaxDuration = MediaSelectionConstant.videoMaxDuration,
    this.pageSize = MediaSelectionConstant.pageSize,
    this.mediaListType = MediaSelectionConstant.mediaListType,
    this.gridItemAspectRatio = MediaSelectionConstant.gridItemAspectRatio,
    this.gridItemMaxWidth = MediaSelectionConstant.gridItemMaxWidth,
  })  : primaryColor = primaryColor ?? MediaSelectionConstant.primaryColor,
        closeIcon =
            closeIcon ?? MediaSelectionConstant.closeIcon(color: Colors.black),
        cameraIcon = cameraIcon ??
            MediaSelectionConstant.cameraIcon(
                color: primaryColor ?? MediaSelectionConstant.primaryColor),
        videoIcon = videoIcon ??
            MediaSelectionConstant.videoIcon(
                color: primaryColor ?? MediaSelectionConstant.primaryColor),
        playIcon =
            playIcon ?? MediaSelectionConstant.playIcon(color: Colors.white),
        pauseIcon =
            pauseIcon ?? MediaSelectionConstant.pauseIcon(color: Colors.white),
        singleSelectModeIcon = singleSelectModeIcon ??
            MediaSelectionConstant.singleSelectModeIcon(
                color: primaryColor ?? MediaSelectionConstant.primaryColor),
        multiSelectModeIcon = multiSelectModeIcon ??
            MediaSelectionConstant.multiSelectModeIcon(
                color: primaryColor ?? MediaSelectionConstant.primaryColor);

  //colors
  final Color primaryColor;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color appBarColor;

  //styles
  final String primaryFontFamily;

  //icons
  final Widget closeIcon;
  final Widget cameraIcon;
  final Widget videoIcon;
  final Widget playIcon;
  final Widget pauseIcon;
  final Widget singleSelectModeIcon;
  final Widget multiSelectModeIcon;

  //text
  final String selectMediaTitle;
  final String doneButtonText;

  //options
  final bool isMultiSelect;
  final int videoMediaLimit;
  final int imageMediaLimit;
  final int mediaLimit;
  final int thumbnailQuality;
  final Duration videoMaxDuration;
  final int pageSize;
  final MediaListType mediaListType;
  final double gridItemAspectRatio;
  final double gridItemMaxWidth;

  /// Creates a copy of this MediaSelectionConfig with the given fields replaced with new values.
  MediaSelectionConfig copyWith({
    Color? primaryColor,
    Color? primaryTextColor,
    Color? backgroundColor,
    Color? appBarColor,
    String? primaryFontFamily,
    Widget? closeIcon,
    Widget? cameraIcon,
    Widget? videoIcon,
    Widget? playIcon,
    Widget? pauseIcon,
    Widget? singleSelectModeIcon,
    Widget? multiSelectModeIcon,
    String? selectMediaTitle,
    String? doneButtonText,
    bool? isMultiSelect,
    int? videoMediaLimit,
    int? imageMediaLimit,
    int? mediaLimit,
    int? thumbnailQuality,
    Duration? videoMaxDuration,
    int? pageSize,
    MediaListType? mediaListType,
    double? gridItemAspectRatio,
    double? gridItemMaxWidth,
  }) =>
      MediaSelectionConfig(
        primaryColor: primaryColor ?? this.primaryColor,
        primaryTextColor: primaryTextColor ?? this.primaryTextColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        appBarColor: appBarColor ?? this.appBarColor,
        primaryFontFamily: primaryFontFamily ?? this.primaryFontFamily,
        closeIcon: closeIcon ?? this.closeIcon,
        cameraIcon: cameraIcon ?? this.cameraIcon,
        videoIcon: videoIcon ?? this.videoIcon,
        playIcon: playIcon ?? this.playIcon,
        pauseIcon: pauseIcon ?? this.pauseIcon,
        singleSelectModeIcon: singleSelectModeIcon ?? this.singleSelectModeIcon,
        multiSelectModeIcon: multiSelectModeIcon ?? this.multiSelectModeIcon,
        selectMediaTitle: selectMediaTitle ?? this.selectMediaTitle,
        doneButtonText: doneButtonText ?? this.doneButtonText,
        isMultiSelect: isMultiSelect ?? this.isMultiSelect,
        videoMediaLimit: videoMediaLimit ?? this.videoMediaLimit,
        imageMediaLimit: imageMediaLimit ?? this.imageMediaLimit,
        mediaLimit: mediaLimit ?? this.mediaLimit,
        thumbnailQuality: thumbnailQuality ?? this.thumbnailQuality,
        videoMaxDuration: videoMaxDuration ?? this.videoMaxDuration,
        pageSize: pageSize ?? this.pageSize,
        mediaListType: mediaListType ?? this.mediaListType,
        gridItemAspectRatio: gridItemAspectRatio ?? this.gridItemAspectRatio,
        gridItemMaxWidth: gridItemMaxWidth ?? this.gridItemMaxWidth,
      );
}

class MediaSelectionConstant {
  //colors
  static const Color primaryColor = Colors.blue;
  static const Color primaryTextColor = Colors.black;
  static const Color backgroundColor = Colors.white;
  static const Color appBarColor = Colors.white;

  //styles
  static const String primaryFontFamily = 'Inter';

  //icons - methods to create icons with dynamic colors
  static Widget closeIcon({Color? color}) => Icon(
        Icons.close,
        color: color ?? Colors.black,
        size: 24,
      );

  static Widget cameraIcon({Color? color}) => Icon(
        Icons.camera_alt,
        color: color ?? MediaSelectionConstant.primaryColor,
        size: 40,
      );

  static Widget videoIcon({Color? color}) => Icon(
        Icons.videocam,
        color: color ?? MediaSelectionConstant.primaryColor,
        size: 40,
      );

  static Widget playIcon({Color? color}) => Icon(
        Icons.play_arrow,
        color: color ?? Colors.white,
        size: 48,
      );

  static Widget pauseIcon({Color? color}) => Icon(
        Icons.pause,
        color: color ?? Colors.white,
        size: 48,
      );

  static Widget singleSelectModeIcon({Color? color}) =>
      Icon(Icons.radio_button_checked, color: color ?? Colors.black);

  static Widget multiSelectModeIcon({Color? color}) =>
      Icon(Icons.checklist, color: color ?? Colors.black);

  //text
  static const String selectMediaTitle = 'Select Media';
  static const String doneButtonText = 'Done';

  //constants
  static const int thumbnailQuality = 50;
  static const Duration videoMaxDuration = Duration(seconds: 30);
  static const int pageSize = 20; // Reduced from 50 to prevent memory issues
  static const bool isMultiSelect = true;
  static const int videoMediaLimit = 10;
  static const int imageMediaLimit = 10;
  static const int mediaLimit = 10;
  static const MediaListType mediaListType = MediaListType.imageVideo;
  static const double gridItemAspectRatio =
      9 / 16; // 9:16 ratio for reels-like appearance
  static const double gridItemMaxWidth =
      120.0; // Desired item width for responsive grid
}

enum MediaListType {
  image,
  video,
  imageVideo,
  audio;

  static MediaListType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return MediaListType.image;
      case 'video':
        return MediaListType.video;
      case 'imageVideo':
        return MediaListType.imageVideo;
      case 'audio':
        return MediaListType.audio;
      default:
        throw ArgumentError('Invalid MediaType: $value');
    }
  }

  String toJson() => name;
}

class MediaSelectionUtility {
  /// show snackBar
  static void showInSnackBar(
    String message,
    BuildContext context, {
    bool? isSuccessIcon = false,
    Color? backgroundColor,
    Color? foregroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        margin: EdgeInsets.all(10.responsiveDimension),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.responsiveDimension),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        content: Row(
          children: [
            if (isSuccessIcon == true) ...[
              Icon(
                Icons.check,
                color: foregroundColor ?? Colors.white,
              ),
              SizedBox(width: 10.responsiveDimension)
            ],
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor ?? Colors.white,
                  fontSize: 14.responsiveDimension,
                  fontFamily: MediaSelectionConstant.primaryFontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
