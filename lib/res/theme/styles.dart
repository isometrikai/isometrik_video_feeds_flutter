import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';

/// A chunk of styles used in the application.
/// Will be ignored for test since all are static values and would not change.
abstract class Styles {
  static TextStyle primaryText10 = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.ten,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText12 = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.twelve,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText14 = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText14Bold = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.fourteen,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.primaryFontFamily,
  );

  static TextStyle primaryText16 = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.sixteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle primaryText16Bold = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.sixteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.bold,
  );

  static TextStyle primaryText18 = TextStyle(
    color: AppColors.primaryTextColor,
    fontSize: Dimens.eighteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText10 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.ten,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText8 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.eight,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText12 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.twelve,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText14 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText16 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.sixteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText18 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.eighteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondaryText20 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontSize: Dimens.twenty,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white10 = TextStyle(
    color: AppColors.white,
    fontSize: Dimens.ten,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white12 = TextStyle(
    color: AppColors.white,
    fontSize: Dimens.twelve,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white14 = TextStyle(
    color: AppColors.white,
    fontSize: Dimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle white16 = TextStyle(
    color: AppColors.white,
    fontSize: Dimens.sixteen,
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
        color: color ?? AppColors.primaryTextColor,
        fontSize: fontSize ?? Dimens.sixteen,
        fontWeight: fontWeight ?? FontWeight.w400,
        fontFamily: fontFamily ?? AppConstants.primaryFontFamily,
        decoration: underline ?? null,
      );

  /// app button text styles
  static TextStyle appButtonStyle = TextStyle(
    color: AppColors.buttonTextColor,
    fontSize: Dimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );

  static TextStyle appButtonDisableStyle = TextStyle(
    color: AppColors.buttonTextColor,
    fontSize: Dimens.fourteen,
    fontFamily: AppConstants.primaryFontFamily,
    fontWeight: FontWeight.w400,
  );
}
