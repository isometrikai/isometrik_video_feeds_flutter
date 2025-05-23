import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class IsrVideoReelUtility {
  IsrVideoReelUtility._();

  static bool isLoading = false;
  static final Connectivity _connectivity = Connectivity();

  static void hideKeyboard() => SystemChannels.textInput.invokeMethod('TextInput.hide');

  static void updateLater(
    VoidCallback callback, [
    bool addDelay = true,
  ]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(addDelay ? const Duration(milliseconds: 10) : Duration.zero, () {
        callback();
      });
    });
  }

  static String jsonEncodePretty(Object? object) => JsonEncoder.withIndent(' ' * 4).convert(object);

  static Future<bool> get isNetworkAvailable async {
    final result = await _connectivity.checkConnectivity();
    return result.any((e) => [
          ConnectivityResult.mobile,
          ConnectivityResult.wifi,
          ConnectivityResult.ethernet,
        ].contains(e));
  }

  /// Show loader
  static void showLoader({
    String? message,
    LoaderType? loaderType = LoaderType.withoutBackground,
  }) async {
    isLoading = true;
    await showDialog(
      barrierColor: loaderType == LoaderType.withBackGround ? null : Colors.transparent,
      context: context!,
      builder: (_) => AppLoader(
        message: message,
        loaderType: loaderType,
      ),
      barrierDismissible: false,
    );
  }

  // closes dialog for progress bar
  static void closeProgressDialog() {
    if (isLoading == true && context?.canPop() == true) {
      isLoading = false;
      context?.pop();
    }
  }

  static void showInfoDialog(
    ResponseModel data, {
    bool? isSuccess = false,
    bool? isToShowTitle = true,
    ErrorViewType? errorViewType = ErrorViewType.dialog,
  }) {
    final message = data.data.isNotEmpty
        ? jsonDecode(data.data)['message'] == null
            ? ''
            : jsonDecode(data.data)['message'] as String
        : data.statusCode.toString();
    if (data.statusCode != 406) {
      if (errorViewType == ErrorViewType.dialog) {
        showAppDialog(
          titleText: isSuccess == true ? 'SUCCESS' : 'ERROR',
          message: message,
          isSuccess: isSuccess,
          isToShowTitle: isToShowTitle,
        );
      } else if (errorViewType == ErrorViewType.toast) {
        showToastMessage(message);
      }
    }
  }

  /// shows general dialog for entire app
  static void showAppDialog({
    String? message,
    String? titleText,
    bool? isSuccess = false,
    bool? isToShowTitle = true,
    bool? isTwoButtons = false,
    String? positiveButtonText,
    String? negativeButtonText,
    Function()? onPressPositiveButton,
    Function()? onPressNegativeButton,
  }) {
    showDialog(
      context: context ?? IsrVideoReelConfig.buildContext!,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: IsrDimens.borderRadiusAll(IsrDimens.twelve),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.fourteen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TapHandler(
                  padding: IsrDimens.four,
                  onTap: closeOpenDialog,
                  child: AppImage.svg(
                    AssetConstants.icCrossIcon,
                    height: IsrDimens.twelve,
                    width: IsrDimens.twelve,
                  ),
                ),
              ),
              IsrDimens.boxHeight(IsrDimens.twenty),
              if (isToShowTitle == true)
                Text(
                  titleText ?? IsrTranslationFile.alert,
                  style: IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w700),
                ),
              if (message.isStringEmptyOrNull == false) ...[
                IsrDimens.boxHeight(IsrDimens.eight),
                Text(
                  message.toString(),
                  style: IsrStyles.primaryText14,
                  textAlign: TextAlign.center,
                ),
              ],
              IsrDimens.boxHeight(IsrDimens.twenty),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: AppButton(
                      width: IsrDimens.twoHundredFifty,
                      title: positiveButtonText ?? IsrTranslationFile.ok,
                      onPress: () {
                        closeOpenDialog();
                        if (onPressPositiveButton != null) {
                          onPressPositiveButton.call();
                        }
                      },
                    ),
                  ),
                  if (isTwoButtons == true) ...[
                    IsrDimens.boxWidth(IsrDimens.five),
                    Expanded(
                      child: AppButton(
                        width: IsrDimens.twoHundredFifty,
                        title: negativeButtonText ?? IsrTranslationFile.cancel,
                        onPress: () {
                          closeOpenDialog();
                          if (onPressNegativeButton != null) {
                            onPressNegativeButton.call();
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
              IsrDimens.boxHeight(IsrDimens.ten),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// shows bottom sheet
  static Future<T?> showBottomSheet<T>(
    Widget child, {
    bool isDarkBG = false,
    bool isDismissible = true,
    bool isScrollControlled = true,
    BuildContext? context,
  }) =>
      showModalBottomSheet<T>(
        context: context ?? IsrVideoReelConfig.buildContext!,
        builder: (_) => child,
        enableDrag: false,
        showDragHandle: false,
        useSafeArea: false,
        isDismissible: isDismissible,
        isScrollControlled: isScrollControlled,
        backgroundColor:
            isDarkBG ? Theme.of(context ?? IsrVideoReelConfig.buildContext!).primaryColor : IsrColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(IsrDimens.sixteen),
          ),
        ),
      );

  static void debugCatchLog({
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      if (stackTrace != null) {
        log('Error = $error\nStack Trace = $stackTrace');
      } else {
        log('Error = ${error.toString()}');
      }
    }
  }

  /// Returns Platform type
  static int platFormType() {
    var value = kIsWeb
        ? 3
        : Platform.isAndroid
            ? 1
            : 2;
    return value;
  }

  /// precache images
  static void preCacheImages(List<String> imageUrls, BuildContext context) {
    for (final url in imageUrls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  /// password regex for strong password
  static String? passwordValidate(String? value) {
    if (value == null || value.isEmpty) {
      return IsrTranslationFile.required;
    }
    final regex = RegExp(AppConstants.passwordPattern);
    return regex.hasMatch(value) == true ? null : IsrTranslationFile.passwordValidationString;
  }

  /// email validator to verify email is valid or not
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return IsrTranslationFile.required;
    }
    final regex = RegExp(AppConstants.emailPattern);
    return regex.hasMatch(value) == true ? null : IsrTranslationFile.invalidEmail;
  }

  /// email validator to verify email is valid or not
  static bool isValidEmail(String? value) {
    final regex = RegExp(AppConstants.emailPattern);
    return regex.hasMatch(value!) == true;
  }

  /// converts a double number into decimal number till 2 decimal point
  static String? convertToDecimalValue(double originalValue, {bool isRemoveTrailingZero = false}) =>
      NumberFormat(originalValue % 1 == 0 ? '#' : '#.##').format(originalValue);

  // returns app version
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  // returns app build number
  static Future<String> getBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

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
        margin: IsrDimens.edgeInsetsAll(IsrDimens.ten),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.twelve),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        content: Row(
          children: [
            if (isSuccessIcon == true) ...[
              Icon(
                Icons.check,
                color: foregroundColor ?? IsrColors.white,
              ),
              IsrDimens.boxWidth(IsrDimens.ten),
            ],
            Flexible(
              child: Text(
                message,
                style: IsrStyles.primaryText14.copyWith(color: foregroundColor ?? IsrColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// to open external url
  static void launchExternalUrl(String link) async {
    var url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  static Widget loaderWidget({bool? isAdaptive = true}) => Center(
        child: isAdaptive == true
            ? const CircularProgressIndicator.adaptive(backgroundColor: Colors.white)
            : const CircularProgressIndicator(color: Colors.white),
      );

  /// get formated date
  static String getFormattedDateWithNumberOfDays(int? numberOfDays, {String? dataFormat = 'EEEE, dd MMM'}) =>
      DateFormat(dataFormat).format(DateTime.now().add(Duration(days: numberOfDays ?? 0)));

  static Color rgbStringToColor(String rgbString) {
    final rgbRegex = RegExp(r'rgb\((\d+),(\d+),(\d+)\)');
    final match = rgbRegex.firstMatch(rgbString);

    if (match != null) {
      final r = int.parse(match.group(1)!);
      final g = int.parse(match.group(2)!);
      final b = int.parse(match.group(3)!);

      return Color.fromRGBO(r, g, b, 1.0); // Alpha is set to 1.0 (fully opaque)
    }

    return IsrColors.transparent;
  }

  static String getFormattedPrice(double price, String? currencySymbol) => NumberFormat.currency(
          decimalDigits: price % 1 == 0 ? 0 : 2,
          symbol: currencySymbol.isStringEmptyOrNull ? DefaultValues.defaultCurrencySymbol : currencySymbol)
      .format(price);

  static Future<void> showCustomModalBottomSheet({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isBackButton = true,
  }) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: IsrColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: IsrDimens.borderRadius(
            topLeftRadius: IsrDimens.sixteen,
            topRightRadius: IsrDimens.sixteen,
          ),
        ),
        builder: (context) => Padding(
          padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.sixteen, horizontal: IsrDimens.eighteen)
              .copyWith(top: IsrDimens.twentyFour),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              builder(context),
              Positioned(
                top: -IsrDimens.sixtyEight,
                right: IsrDimens.one,
                child: InkWell(
                  onTap: () {
                    context.pop();
                  },
                  borderRadius: IsrDimens.borderRadiusAll(IsrDimens.fifty),
                  child: Container(
                    height: IsrDimens.thirtySix,
                    width: IsrDimens.thirtySix,
                    decoration: BoxDecoration(
                      borderRadius: IsrDimens.borderRadiusAll(IsrDimens.fifty),
                    ),
                    child: isBackButton
                        ? const AppImage.svg(
                            AssetConstants.icCloseBottomSheet,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  //capitalize the first letter of each word
  static String capitalizeString(String text, {bool? isName}) => text.split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1);
        } else {
          return word;
        }
      }).join(' ');

  //Flutter toast message
  static void showToastMessage(
    String msg, {
    ToastGravity? gravity,
  }) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity ?? ToastGravity.BOTTOM,
      backgroundColor: IsrColors.black,
      textColor: IsrColors.white,
    );
  }

  static BuildContext? get context => IsrVideoReelConfig.buildContext!;

  // Define a function to convert a character to its base64Encode
  static String encodeChar(String char) => base64Encode(utf8.encode(char));

  //Function for converting timestamp to formatted data
  static String convertTimestamp(int timestamp, String format) =>
      DateFormat(format).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

  /// converts epoch date time into current date time
  static String getEpochConvertedTime(String timeStamp, String format) {
    var parsedDate = DateTime.parse(timeStamp);
    return DateFormat(format).format(parsedDate);
  }

  /// returns gumlet image url
  static String buildGumletImageUrl({required String imageUrl, double? width, double? height}) {
    final finalImageUrl = removeSourceUrl(imageUrl);
    return '${AppUrl.gumletUrl}/$finalImageUrl?w=${width ?? 0}&h=${height ?? 0}';
  }

  /// removes source url and extract only file name
  static String removeSourceUrl(String url) {
    // Find the index of '.com' or '.net'
    final comIndex = url.indexOf('.com');
    final netIndex = url.indexOf('.net');

    // Determine the starting point for searching the slash
    var startIndex = comIndex != -1 ? comIndex + 4 : (netIndex != -1 ? netIndex + 4 : -1);
    // If neither '.com' nor '.net' is found, return -1
    if (startIndex == -1) {
      return url.substring(url.lastIndexOf('/') + 1);
    }
    // Find the first '/' after the identified domain
    final finalIndex = url.indexOf('/', startIndex);
    return url.substring(finalIndex + 1);
  }

  /// remove escape sequences
  static String cleanText(String inputText) =>
      inputText.replaceAll(RegExp(r'[\n\t\r]'), ''); // Removes newline, tab, and carriage return

  ///show custom widget dialog
  static Future<void> showCustomDialog({required BuildContext context, required Widget child}) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
          shape: RoundedRectangleBorder(
            borderRadius: IsrDimens.borderRadiusAll(IsrDimens.twelve),
          ),
          backgroundColor: IsrColors.dialogColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TapHandler(
                  padding: IsrDimens.four,
                  onTap: IsrVideoReelUtility.closeOpenDialog,
                  child: AppImage.svg(
                    AssetConstants.icCrossIcon,
                    height: IsrDimens.twelve,
                    width: IsrDimens.twelve,
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      );

  static bool _isErrorShowing = false; // Flag to track if an error is currently displayed

  static void showAppError({
    BuildContext? context,
    required String message,
    ErrorViewType? errorViewType = ErrorViewType.none,
  }) {
    if (errorViewType == ErrorViewType.none || _isErrorShowing) {
      return; // Do not show if no error type or if an error is already showing
    }

    _isErrorShowing = true; // Set the flag to true when showing an error

    if (errorViewType == ErrorViewType.dialog) {
      showAppDialog(
        message: message,
        positiveButtonText: IsrTranslationFile.ok,
      );
    } else if (errorViewType == ErrorViewType.snackBar) {
      showInSnackBar(message, context ?? IsrVideoReelConfig.buildContext!);
    } else if (errorViewType == ErrorViewType.toast) {
      showToastMessage(message);
      _isErrorShowing = false; // Reset the flag immediately for toast
    }
  }

  // closes opened dialog
  static void closeOpenDialog() {
    _isErrorShowing = false;
    if (context?.canPop() == true) {
      context?.pop();
    }
  }

  static String getErrorMessage(ResponseModel data) => data.data.isNotEmpty
      ? jsonDecode(data.data)['message'] == null
          ? ''
          : jsonDecode(data.data)['message'] as String
      : data.statusCode.toString();
}
