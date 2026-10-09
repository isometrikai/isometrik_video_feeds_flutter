import 'package:flutter/material.dart';

/// Host UI for the video trim screen.
///
/// Null fields use the theme set on the SDK social config.
class VideoTrimUIConfig {
  const VideoTrimUIConfig({
    this.title,
    this.doneButtonText,
    this.errorText,
    this.scaffoldBackgroundColor,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.titleStyle,
    this.durationTextStyle,
    this.selectionColor,
    this.handleColor,
    this.playheadColor,
    this.trackColor,
    this.dimColor,
    this.placeholderColor,
    this.buttonBackgroundColor,
    this.buttonForegroundColor,
    this.progressColor,
    this.maxDurationScreenFraction,
    this.trackHeight,
    this.borderRadius,
    this.selectionBorderWidth,
    this.handleHitWidth,
    this.handleWidth,
    this.handleHeight,
    this.thumbnailPageSize,
  });

  final String? title;
  final String? doneButtonText;
  final String? errorText;
  final Color? scaffoldBackgroundColor;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final TextStyle? titleStyle;
  final TextStyle? durationTextStyle;

  /// Border around the selected span.
  final Color? selectionColor;
  final Color? handleColor;
  final Color? playheadColor;
  final Color? trackColor;
  final Color? dimColor;
  final Color? placeholderColor;
  final Color? buttonBackgroundColor;
  final Color? buttonForegroundColor;
  final Color? progressColor;

  /// Share of the screen width used to draw the max trim duration.
  ///
  /// When null, the trim screen uses 60%.
  final double? maxDurationScreenFraction;

  /// Filmstrip height. When null, the timeline uses 58.
  final double? trackHeight;

  /// Corner radius of the filmstrip and selection. When null, the timeline uses 6.
  final double? borderRadius;

  /// Width of the border around the selected span. When null, the timeline uses 3.
  final double? selectionBorderWidth;

  /// Drag target width of each trim handle. When null, the timeline uses 28.
  final double? handleHitWidth;

  /// Visible thickness of each trim handle. When null, the timeline uses 4.
  final double? handleWidth;

  /// Visible height of each trim handle. When null, the timeline uses 36.
  final double? handleHeight;

  /// Stills requested per scroll page. When null, the timeline loads 20.
  final int? thumbnailPageSize;

  VideoTrimUIConfig copyWith({
    String? title,
    String? doneButtonText,
    String? errorText,
    Color? scaffoldBackgroundColor,
    Color? appBarBackgroundColor,
    Color? appBarForegroundColor,
    TextStyle? titleStyle,
    TextStyle? durationTextStyle,
    Color? selectionColor,
    Color? handleColor,
    Color? playheadColor,
    Color? trackColor,
    Color? dimColor,
    Color? placeholderColor,
    Color? buttonBackgroundColor,
    Color? buttonForegroundColor,
    Color? progressColor,
    double? maxDurationScreenFraction,
    double? trackHeight,
    double? borderRadius,
    double? selectionBorderWidth,
    double? handleHitWidth,
    double? handleWidth,
    double? handleHeight,
    int? thumbnailPageSize,
  }) =>
      VideoTrimUIConfig(
        title: title ?? this.title,
        doneButtonText: doneButtonText ?? this.doneButtonText,
        errorText: errorText ?? this.errorText,
        scaffoldBackgroundColor:
            scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
        appBarBackgroundColor:
            appBarBackgroundColor ?? this.appBarBackgroundColor,
        appBarForegroundColor:
            appBarForegroundColor ?? this.appBarForegroundColor,
        titleStyle: titleStyle ?? this.titleStyle,
        durationTextStyle: durationTextStyle ?? this.durationTextStyle,
        selectionColor: selectionColor ?? this.selectionColor,
        handleColor: handleColor ?? this.handleColor,
        playheadColor: playheadColor ?? this.playheadColor,
        trackColor: trackColor ?? this.trackColor,
        dimColor: dimColor ?? this.dimColor,
        placeholderColor: placeholderColor ?? this.placeholderColor,
        buttonBackgroundColor:
            buttonBackgroundColor ?? this.buttonBackgroundColor,
        buttonForegroundColor:
            buttonForegroundColor ?? this.buttonForegroundColor,
        progressColor: progressColor ?? this.progressColor,
        maxDurationScreenFraction:
            maxDurationScreenFraction ?? this.maxDurationScreenFraction,
        trackHeight: trackHeight ?? this.trackHeight,
        borderRadius: borderRadius ?? this.borderRadius,
        selectionBorderWidth:
            selectionBorderWidth ?? this.selectionBorderWidth,
        handleHitWidth: handleHitWidth ?? this.handleHitWidth,
        handleWidth: handleWidth ?? this.handleWidth,
        handleHeight: handleHeight ?? this.handleHeight,
        thumbnailPageSize: thumbnailPageSize ?? this.thumbnailPageSize,
      );
}
