import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

ThemeData appTheme = ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(
        allowEnterRouteSnapshotting: false,
      ),
    },
  ),
  splashFactory: InkRipple.splashFactory,
  brightness: Brightness.light,
  primaryColor: AppColors.appColor,
  iconTheme: const IconThemeData(color: AppColors.white),
  scaffoldBackgroundColor: AppColors.scaffoldColor,
  fontFamily: AppConstants.primaryFontFamily,
  splashColor: AppColors.appColor.applyOpacity(0.5),
  textTheme: TextTheme(
    displayLarge: Styles.secondaryText18.copyWith(fontWeight: FontWeight.w600),
    displayMedium: Styles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    displaySmall: Styles.secondaryText12.copyWith(fontWeight: FontWeight.w600),
    headlineLarge: Styles.secondaryText20.copyWith(fontWeight: FontWeight.w600),
    headlineMedium:
        Styles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    headlineSmall: Styles.secondaryText14.copyWith(fontWeight: FontWeight.w600),
    titleLarge: Styles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    titleMedium: Styles.secondaryText14.copyWith(fontWeight: FontWeight.w600),
    titleSmall: Styles.secondaryText12.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: Styles.secondaryText16
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    bodyMedium: Styles.secondaryText14
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    bodySmall: Styles.secondaryText12
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    labelLarge: Styles.secondaryText12
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    labelMedium: Styles.secondaryText10
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    labelSmall: Styles.secondaryText8
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: AppColors.white,
    surfaceTintColor: AppColors.appColor,
    rangeSelectionBackgroundColor: AppColors.appColor,
    rangeSelectionOverlayColor: const WidgetStatePropertyAll(AppColors.white),
    dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
      (states) =>
          states.contains(WidgetState.selected) ? AppColors.appColor : null,
    ),
    dividerColor: AppColors.appColor,
    dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.white
          : AppColors.black,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.appColor,
      textStyle: Styles.appButtonStyle,
      disabledBackgroundColor: AppColors.buttonDisabledBackgroundColor,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      backgroundColor: AppColors.buttonBackgroundColor,
      textStyle: Styles.appButtonStyle,
      disabledBackgroundColor: AppColors.buttonDisabledBackgroundColor,
      disabledIconColor: AppColors.buttonDisabledBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius:
            Dimens.appButtonBorderRadius(), // Adjust the radius as needed
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: AppColors.appBarColor,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.navigationBar,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    backgroundColor: AppColors.appBarColor,
    iconTheme: const IconThemeData(color: AppColors.black),
    actionsIconTheme: const IconThemeData(color: AppColors.black),
    titleTextStyle:
        Styles.secondaryText16.copyWith(fontWeight: FontWeight.w500),
    toolbarTextStyle: Styles.secondaryText12,
  ),
  bottomSheetTheme: BottomSheetThemeData(
    dragHandleColor: AppColors.grey.shade300,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.appColor,
    foregroundColor: AppColors.white,
  ),
  dividerColor: AppColors.dividerColor,
  dividerTheme: const DividerThemeData(
    color: AppColors.dividerColor,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.white,
    elevation: 4,
    type: BottomNavigationBarType.fixed,
  ),
);
