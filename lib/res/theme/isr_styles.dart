import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// A chunk of styles used in the application.
/// Will be ignored for test since all are static values and would not change.
abstract class IsrStyles {
  static TextStyle primaryText10 = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.ten,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText12 = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.twelve,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText14 = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText14Bold = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.fourteen,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.primaryFontFamily,
  );

  static TextStyle primaryText16 = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.sixteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText16Bold = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.sixteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.bold,
  );

  static TextStyle primaryText18 = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.eighteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText20 = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.twenty,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText20Bold = TextStyle(
    color: IsrColors.primaryTextColor,
    fontSize: IsrDimens.twenty,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.bold,
  );

  static TextStyle secondaryText10 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.ten,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText8 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.eight,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText12 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.twelve,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText14 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText16 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.sixteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText18 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.eighteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText20 = TextStyle(
    color: IsrColors.secondaryTextColor,
    fontSize: IsrDimens.twenty,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white10 = TextStyle(
    color: IsrColors.white,
    fontSize: IsrDimens.ten,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white12 = TextStyle(
    color: IsrColors.white,
    fontSize: IsrDimens.twelve,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white14 = TextStyle(
    color: IsrColors.white,
    fontSize: IsrDimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white16 = TextStyle(
    color: IsrColors.white,
    fontSize: IsrDimens.sixteen,
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
  static TextStyle appButtonStyle = TextStyle(
    color: IsrColors.buttonTextColor,
    fontSize: IsrDimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle appButtonDisableStyle = TextStyle(
    color: IsrColors.buttonTextColor,
    fontSize: IsrDimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );
}
