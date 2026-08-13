import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// A chunk of styles used in the application.
/// Will be ignored for test since all are static values and would not change.
abstract class IsrStyles {
  static TextStyle get primaryText10 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize10 ?? IsrDimens.ten).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText12 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize12 ?? IsrDimens.twelve).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText14 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ?? IsrDimens.fourteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText14Bold => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ?? IsrDimens.fourteen).sp,
        fontWeight: FontWeight.bold,
        fontFamily: IsrAppConstants.primaryFontFamily,
      );

  static TextStyle get primaryText16 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ?? IsrDimens.sixteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText16Bold => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ?? IsrDimens.sixteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get primaryText18 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize18 ?? IsrDimens.eighteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText20 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize20 ?? IsrDimens.twenty).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get primaryText20Bold => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.primaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize20 ?? IsrDimens.twenty).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get secondaryText10 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize10 ?? IsrDimens.ten).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText8 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize8 ?? IsrDimens.eight).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText12 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize12 ?? IsrDimens.twelve).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText14 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ?? IsrDimens.fourteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText16 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ?? IsrDimens.sixteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText18 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize18 ?? IsrDimens.eighteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get secondaryText20 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.secondaryTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize20 ?? IsrDimens.twenty).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white10 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.white,
        fontSize: (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize10 ?? IsrDimens.ten).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white12 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.white,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize12 ?? IsrDimens.twelve).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white14 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.white,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ?? IsrDimens.fourteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get white16 => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.white,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize16 ?? IsrDimens.sixteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
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
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: color ?? IsrColors.primaryTextColor,
        fontSize: fontSize ?? IsrDimens.sixteen,
        fontWeight: fontWeight ?? FontWeight.w400,
        fontFamily: fontFamily ?? IsrAppConstants.primaryFontFamily,
        decoration: underline,
      );

  /// app button text styles
  static TextStyle get appButtonStyle => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.buttonTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ?? IsrDimens.fourteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get appButtonDisableStyle => TextStyle(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        color: IsrColors.buttonTextColor,
        fontSize:
            (IsrVideoReelConfig.socialConfig.textSizeConfig?.textSize14 ?? IsrDimens.fourteen).sp,
        fontFamily: IsrAppConstants.primaryFontFamily,
        fontWeight: FontWeight.w400,
      );
}
