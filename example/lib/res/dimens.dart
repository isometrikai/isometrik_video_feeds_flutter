import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Dimens {
  const Dimens._();

  /// Get the height with the percent value of the screen height.
  static double percentHeight(double percentValue) => percentValue.sh;

  /// Get the width with the percent value of the screen width.
  static double percentWidth(double percentValue) => percentValue.sw;

  static final double appBarHeight = fiftySix;

  static final double appBarElevation = eight;

  static final double pinCodeField = fortyEight;

  static final investTypeSized = oneHundredSixty;

  static final double pointFive = 0.5.sp;
  static final double zero = 0.sp;
  static final double one = 1.sp;
  static final double two = 2.sp;
  static final double three = 3.sp;
  static final double four = 4.sp;
  static final double five = 5.sp;
  static final double six = 6.sp;
  static final double seven = 7.sp;
  static final double eight = 8.sp;
  static final double ten = 10.sp;
  static final double twelve = 12.sp;
  static final double thirteen = 13.sp;
  static final double fourteen = 14.sp;
  static final double fifteen = 15.sp;
  static final double sixteen = 16.sp;
  static final double seventeen = 17.sp;
  static final double eighteen = 18.sp;
  static final double twenty = 20.sp;
  static final double twentyTwo = 22.sp;
  static final double twentyThree = 23.sp;
  static final double twentyFour = 24.sp;
  static final double twentyFive = 25.sp;
  static final double twentySix = 26.sp;
  static final double twentyEight = 28.sp;
  static final double thirty = 30.sp;
  static final double thirtyTwo = 32.sp;
  static final double thirtySix = 36.sp;
  static final double thirtySeven = 37.sp;
  static final double thirtyEight = 38.sp;
  static final double forty = 40.sp;
  static final double fortyFour = 44.sp;
  static final double fortyEight = 48.sp;
  static final double fortyNine = 49.sp;
  static final double fifty = 50.sp;
  static final double fiftyFour = 54.sp;
  static final double fiftySix = 56.sp;
  static final double sixty = 60.sp;
  static final double sixtyFour = 64.sp;
  static final double sixtyEight = 68.sp;
  static final double seventy = 70.sp;
  static final double seventyTwo = 72.sp;
  static final double eighty = 80.sp;
  static final double eightySix = 86.sp;
  static final double ninety = 90.sp;
  static final double ninetyTwo = 92.sp;
  static final double ninetySix = 96.sp;
  static final double hundred = 100.sp;
  static final double oneHundredTen = 110.sp;
  static final double oneHundredTwenty = 120.sp;
  static final double oneHundredThirty = 130.sp;
  static final double oneHundredForty = 140.sp;
  static final double oneHundredFifty = 150.sp;
  static final double oneHundredFiftySix = 156.sp;
  static final double oneHundredSixty = 160.sp;
  static final double oneHundredSeventy = 170.sp;
  static final double oneHundredEighty = 180.sp;
  static final double oneHundredNinety = 190.sp;
  static final double twoHundred = 200.sp;
  static final double twoHundredTwenty = 220.sp;
  static final double twoHundredThirtyFive = 235.sp;
  static final double twoHundredFifty = 250.sp;
  static final double threeHundred = 300.sp;
  static final double threeHundredThirty = 330.sp;
  static final double threeHundredSeventyFive = 375.sp;
  static final double fourHundred = 400.sp;
  static final double sixHundred = 600.sp;
  static final double bottomSheetBorderRadius = 16.sp;

  /// app button dimensions
  static BorderRadius appButtonBorderRadius({
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomRightRadius,
    double? bottomLeftRadius,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeftRadius ?? Dimens.eight),
        topRight: Radius.circular(topRightRadius ?? Dimens.eight),
        bottomLeft: Radius.circular(bottomLeftRadius ?? Dimens.eight),
        bottomRight: Radius.circular(bottomRightRadius ?? Dimens.eight),
      );

  static final double appButtonHeight = 50.sp;

  static BorderRadius borderRadiusAll(double radius) => BorderRadius.circular(radius);

  static BorderRadius borderRadius({
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomRightRadius,
    double? bottomLeftRadius,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeftRadius ?? Dimens.zero),
        topRight: Radius.circular(topRightRadius ?? Dimens.zero),
        bottomLeft: Radius.circular(bottomLeftRadius ?? Dimens.zero),
        bottomRight: Radius.circular(bottomRightRadius ?? Dimens.zero),
      );

  /// Returns Box with requested height value
  static SizedBox boxHeight(double height) => height == 0 ? const SizedBox.shrink() : SizedBox(height: height);

  /// Returns Box with requested width value
  static SizedBox boxWidth(double width) => SizedBox(width: width);

  static EdgeInsets edgeInsets({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) =>
      EdgeInsets.fromLTRB(
        left ?? zero,
        top ?? zero,
        right ?? zero,
        bottom ?? zero,
      );

  static EdgeInsets edgeInsetsAll(double allSide) => EdgeInsets.all(allSide);

  static EdgeInsets edgeInsetsSymmetric({
    double? vertical,
    double? horizontal,
  }) =>
      EdgeInsets.symmetric(
        vertical: vertical ?? 0,
        horizontal: horizontal ?? 0,
      );

  static double getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static double getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  static double getDimensValue(double? value) => (value ?? 0).sp;

  static EdgeInsets getSafeAreaPadding(BuildContext context) => MediaQuery.of(context).padding;
}
