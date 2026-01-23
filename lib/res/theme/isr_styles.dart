import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// A chunk of styles used in the application.
/// Will be ignored for test since all are static values and would not change.
abstract class IsrStyles {
  static TextStyle get primaryText10 => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize10 ??
                IsrDimens.ten)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText12 => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize12 ??
                IsrDimens.twelve)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText14 => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ??
                IsrDimens.fourteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText14Bold => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ??
                IsrDimens.fourteen)
            .sp,
        fontWeight: FontWeight.bold,
        fontFamily: AppConstants.primaryFontFamily,
      );

  static TextStyle get primaryText16 => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ??
                IsrDimens.sixteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText16Bold => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ??
                IsrDimens.sixteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get primaryText18 => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize18 ??
                IsrDimens.eighteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText20 => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize20 ??
                IsrDimens.twenty)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText20Bold => TextStyle(
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize20 ??
                IsrDimens.twenty)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get secondaryText10 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize10 ??
                IsrDimens.ten)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText8 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize8 ??
                IsrDimens.eight)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText12 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize12 ??
                IsrDimens.twelve)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText14 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ??
                IsrDimens.fourteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText16 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ??
                IsrDimens.sixteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText18 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize18 ??
                IsrDimens.eighteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText20 => TextStyle(
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize20 ??
                IsrDimens.twenty)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white10 => TextStyle(
        color: IsrColors.white,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize10 ??
                IsrDimens.ten)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white12 => TextStyle(
        color: IsrColors.white,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize12 ??
                IsrDimens.twelve)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white14 => TextStyle(
        color: IsrColors.white,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ??
                IsrDimens.fourteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white16 => TextStyle(
        color: IsrColors.white,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ??
                IsrDimens.sixteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle getTextStyles({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    String? fontFamily,
    TextDecoration? underline,
  }) =>
      TextStyle(
        color: color ?? IsrColors.primaryTextColor,
        fontSize: fontSize ?? IsrDimens.sixteen,
        fontWeight: fontWeight ?? FontWeight.w400,
        fontFamily: fontFamily ?? AppConstants.primaryFontFamily,
        decoration: underline,
      );

  /// app button text styles
  static TextStyle get appButtonStyle => TextStyle(
        color: IsrColors.buttonTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ??
                IsrDimens.fourteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get appButtonDisableStyle => TextStyle(
        color: IsrColors.buttonTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ??
                IsrDimens.fourteen)
            .sp,
        fontFamily: AppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );
}
