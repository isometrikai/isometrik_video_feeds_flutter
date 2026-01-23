import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

ThemeData get isrTheme {
  final themeConfig = IsrVideoReelConfig.socialConfig.themeConfig;
  final primaryColor = themeConfig?.primaryColor ?? IsrColors.appColor;
  final scaffoldColor = themeConfig?.scaffoldBackgroundColor ??
      IsrColors.scaffoldColor;
  final appBarColor = themeConfig?.appBarColor ?? IsrColors.appBarColor;
  final brightness = themeConfig?.brightness ?? Brightness.light;
  final splashColor = themeConfig?.splashColor ??
      primaryColor.changeOpacity(0.5);

  return ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(
          allowEnterRouteSnapshotting: false,
        ),
      },
    ),
    splashFactory: InkRipple.splashFactory,
    brightness: brightness,
    primaryColor: primaryColor,
    iconTheme: IconThemeData(color: IsrColors.white),
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: AppConstants.primaryFontFamily,
    splashColor: splashColor,
    textTheme: TextTheme(
    displayLarge:
        IsrStyles.secondaryText18.copyWith(fontWeight: FontWeight.w600),
    displayMedium:
        IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    displaySmall:
        IsrStyles.secondaryText12.copyWith(fontWeight: FontWeight.w600),
    headlineLarge:
        IsrStyles.secondaryText20.copyWith(fontWeight: FontWeight.w600),
    headlineMedium:
        IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    headlineSmall:
        IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w600),
    titleLarge: IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w600),
    titleMedium:
        IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w600),
    titleSmall: IsrStyles.secondaryText12.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: IsrStyles.secondaryText16
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    bodyMedium: IsrStyles.secondaryText14
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    bodySmall: IsrStyles.secondaryText12
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    labelLarge: IsrStyles.secondaryText12
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    labelMedium: IsrStyles.secondaryText10
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
    labelSmall: IsrStyles.secondaryText8
        .copyWith(fontFamily: AppConstants.primaryFontFamily),
  ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: primaryColor,
      surfaceTintColor: IsrColors.white,
      rangeSelectionBackgroundColor: IsrColors.white,
      rangeSelectionOverlayColor: WidgetStatePropertyAll(IsrColors.white),
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) =>
            states.contains(WidgetState.selected) ? IsrColors.white : null,
      ),
      dividerColor: IsrColors.white,
      dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? IsrColors.black
            : IsrColors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
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
        borderRadius:
            IsrDimens.appButtonBorderRadius(), // Adjust the radius as needed
      ),
    ),
  ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: appBarColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: IsrColors.navigationBar,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      backgroundColor: appBarColor,
      iconTheme: IconThemeData(color: IsrColors.black),
      actionsIconTheme: IconThemeData(color: IsrColors.black),
      titleTextStyle:
          IsrStyles.secondaryText16.copyWith(fontWeight: FontWeight.w500),
      toolbarTextStyle: IsrStyles.secondaryText12,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      dragHandleColor: IsrColors.grey.shade300,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: IsrColors.white,
    ),
    dividerColor: IsrColors.dividerColor,
    dividerTheme: DividerThemeData(
      color: IsrColors.dividerColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: IsrColors.white,
      elevation: 4,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
