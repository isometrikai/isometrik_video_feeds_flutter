import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

ThemeData isrTheme = ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(
        allowEnterRouteSnapshotting: false,
      ),
    },
  ),
  splashFactory: InkRipple.splashFactory,
  brightness: Brightness.light,
  primaryColor: IsrColors.appColor,
  iconTheme: const IconThemeData(color: IsrColors.white),
  scaffoldBackgroundColor: IsrColors.scaffoldColor,
  fontFamily: IsmAppConstants.primaryFontFamily,
  splashColor: IsrColors.appColor.changeOpacity(0.5),
  textTheme: TextTheme(
    displayLarge: IsrStyles.secondaryText18.copyWith(fontWeight: FontWeight.w600),
    displayMedium: IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    displaySmall: IsrStyles.secondaryText12.copyWith(fontWeight: FontWeight.w600),
    headlineLarge: IsrStyles.secondaryText20.copyWith(fontWeight: FontWeight.w600),
    headlineMedium: IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    headlineSmall: IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w600),
    titleLarge: IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    titleMedium: IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w600),
    titleSmall: IsrStyles.secondaryText12.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: IsrStyles.secondaryText16.copyWith(fontFamily: IsmAppConstants.primaryFontFamily),
    bodyMedium: IsrStyles.secondaryText14.copyWith(fontFamily: IsmAppConstants.primaryFontFamily),
    bodySmall: IsrStyles.secondaryText12.copyWith(fontFamily: IsmAppConstants.primaryFontFamily),
    labelLarge: IsrStyles.secondaryText12.copyWith(fontFamily: IsmAppConstants.primaryFontFamily),
    labelMedium: IsrStyles.secondaryText10.copyWith(fontFamily: IsmAppConstants.primaryFontFamily),
    labelSmall: IsrStyles.secondaryText8.copyWith(fontFamily: IsmAppConstants.primaryFontFamily),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: IsrColors.appColor,
    surfaceTintColor: IsrColors.white,
    rangeSelectionBackgroundColor: IsrColors.white,
    rangeSelectionOverlayColor: const WidgetStatePropertyAll(IsrColors.white),
    dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected) ? IsrColors.white : null,
    ),
    dividerColor: IsrColors.white,
    dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected) ? IsrColors.black : IsrColors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: IsrColors.appColor,
      textStyle: IsrStyles.appButtonStyle,
      disabledBackgroundColor: IsrColors.buttonDisabledBackgroundColor,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      backgroundColor: IsrColors.buttonBackgroundColor,
      textStyle: IsrStyles.appButtonStyle,
      disabledBackgroundColor: IsrColors.buttonDisabledBackgroundColor,
      disabledIconColor: IsrColors.buttonDisabledBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: IsrDimens.appButtonBorderRadius(), // Adjust the radius as needed
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: IsrColors.appBarColor,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: IsrColors.navigationBar,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    backgroundColor: IsrColors.appBarColor,
    iconTheme: const IconThemeData(color: IsrColors.black),
    actionsIconTheme: const IconThemeData(color: IsrColors.black),
    titleTextStyle: IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w500),
    toolbarTextStyle: IsrStyles.secondaryText12,
  ),
  bottomSheetTheme: BottomSheetThemeData(
    dragHandleColor: IsrColors.grey.shade300,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: IsrColors.appColor,
    foregroundColor: IsrColors.white,
  ),
  dividerColor: IsrColors.dividerColor,
  dividerTheme: const DividerThemeData(
    color: IsrColors.dividerColor,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: IsrColors.white,
    elevation: 4,
    type: BottomNavigationBarType.fixed,
  ),
);
