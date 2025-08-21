import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_phone_validator/country_phone_validator.dart' as validator;
import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Utility {
  Utility._();

  static bool isLoading = false;
  static final Connectivity _connectivity = Connectivity();

  static void hideKeyboard() => SystemChannels.textInput.invokeMethod('TextInput.hide');

  static bool isLocalUrl(String url) =>
      url.startsWith('http://') == false && url.startsWith('https://') == false;

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
    final isNetworkAvailable = result.any((e) => [
          ConnectivityResult.mobile,
          ConnectivityResult.wifi,
          ConnectivityResult.ethernet,
        ].contains(e));
    if (!isNetworkAvailable) {
      try {
        final response = await http.get(Uri.parse('https://www.google.com'));
        return response.statusCode == 200; // Internet is reachable
      } catch (e) {
        return false; // Handle exceptions (e.g., no internet)
      }
    }
    return isNetworkAvailable; // No network connection
  }

  /// Show loader
  static void showLoader({
    String? message,
    LoaderType? loaderType = LoaderType.withoutBackground,
  }) async {
    isLoading = true;
    await showDialog(
      barrierColor: loaderType == LoaderType.withBackGround ? null : Colors.transparent,
      context: exNavigatorKey.currentContext!,
      builder: (_) => AppLoader(
        message: message,
        loaderType: loaderType,
      ),
      barrierDismissible: false,
    );
  }

  // closes dialog for progress bar
  static void closeProgressDialog() {
    if (isLoading == true && exNavigatorKey.currentContext!.canPop()) {
      isLoading = false;
      exNavigatorKey.currentContext!.pop();
    }
  }

  static String getErrorMessage(ResponseModel data) => data.data.isNotEmpty
      ? jsonDecode(data.data)['message'] == null
          ? ''
          : jsonDecode(data.data)['message'] as String
      : data.statusCode.toString();

  static void showInfoDialog(
    ResponseModel data, {
    bool? isSuccess = false,
    bool? isToShowTitle = true,
    ErrorViewType? errorViewType = ErrorViewType.dialog,
  }) {
    final message = getErrorMessage(data);
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
      context: exNavigatorKey.currentContext!,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: Dimens.borderRadiusAll(Dimens.twelve),
        ),
        backgroundColor: AppColors.dialogColor,
        child: Padding(
          padding: Dimens.edgeInsetsAll(Dimens.fourteen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TapHandler(
                  padding: Dimens.four,
                  onTap: closeOpenDialog,
                  child: AppImage.svg(
                    AssetConstants.icCrossIcon,
                    height: Dimens.twelve,
                    width: Dimens.twelve,
                  ),
                ),
              ),
              Dimens.boxHeight(Dimens.twenty),
              if (isToShowTitle == true)
                Text(
                  titleText ?? TranslationFile.alert,
                  style: Styles.secondaryText14.copyWith(fontWeight: FontWeight.w700),
                ),
              if (message.isEmptyOrNull == false) ...[
                Dimens.boxHeight(Dimens.eight),
                Text(
                  message.toString(),
                  style: Styles.primaryText14,
                  textAlign: TextAlign.center,
                ),
              ],
              Dimens.boxHeight(Dimens.twenty),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CustomButton(
                      width: Dimens.twoHundredFifty,
                      height: Dimens.fortyFour,
                      radius: Dimens.four,
                      borderWidth: Dimens.one,
                      borderColor: AppColors.appColor,
                      color: isTwoButtons == true ? AppColors.white : AppColors.appColor,
                      textStyle: Styles.primaryText14.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isTwoButtons == true ? AppColors.appColor : AppColors.white),
                      title: positiveButtonText ??
                          (isTwoButtons == true ? TranslationFile.yes : TranslationFile.ok),
                      onPress: () {
                        closeOpenDialog();
                        if (onPressPositiveButton != null) {
                          onPressPositiveButton.call();
                        }
                      },
                    ),
                  ),
                  if (isTwoButtons == true) ...[
                    Dimens.boxWidth(Dimens.five),
                    Expanded(
                      child: CustomButton(
                        width: Dimens.twoHundredFifty,
                        height: Dimens.fortyFour,
                        radius: Dimens.four,
                        color: AppColors.appColor,
                        title: negativeButtonText ?? TranslationFile.no,
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
              Dimens.boxHeight(Dimens.ten),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// shows bottom sheet
  static Future<T?> showBottomSheet<T>({
    required Widget child,
    bool isDarkBG = false,
    bool isDismissible = true,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? height,
  }) =>
      showModalBottomSheet<T>(
        context: exNavigatorKey.currentContext!,
        builder: (_) => SizedBox(
          height: height,
          child: child,
        ),
        enableDrag: false,
        showDragHandle: false,
        useSafeArea: true,
        isDismissible: isDismissible,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor ??
            (isDarkBG ? Theme.of(exNavigatorKey.currentContext!).primaryColor : AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimens.bottomSheetBorderRadius),
          ),
        ),
      );

  static int lengthFromCountry([Country? country]) =>
      validator.CountryUtils.getCountryByDialCode(
        (country ?? Country.parse(DefaultValues.defaultCountryIsoCode)).phoneCode,
      )?.phoneMinLength ??
      10;

  static void countryPicker({
    required void Function(Country) onCountrySelect,
    String? hintText,
    Widget? icon,
  }) {
    final context = exNavigatorKey.currentContext!;
    showCountryPicker(
      context: context,
      onSelect: onCountrySelect,
      searchAutofocus: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.appBarColor,
        inputDecoration: InputDecoration(
          prefixIcon: icon,
          border: GradientInputBorder(
            gradient: const LinearGradient(colors: AppColors.inputGradient),
            borderRadius: Dimens.borderRadiusAll(Dimens.eight),
          ),
          hintText: hintText ?? 'Search',
          hintStyle: context.textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        textStyle: context.textTheme.labelLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        searchTextStyle: context.textTheme.labelLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        borderRadius: Dimens.borderRadiusAll(Dimens.sixteen),
      ),
    );
  }

  /// [datePicker] (to pick the date from the calendar)  to use it as datePicker when ever we required when can modified the date picker at one place..
  static Future<DateTime?> datePicker({
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool Function(DateTime)? selectableDayPredicate,
    bool isDisabledPastDate = false,
    bool isDisabledFutureDate = false,
  }) async {
    final context = exNavigatorKey.currentContext!;
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? (isDisabledPastDate ? DateTime.now() : DateTime(1900)),
      lastDate: lastDate ?? (isDisabledFutureDate ? DateTime.now() : DateTime(4000)),
      selectableDayPredicate: selectableDayPredicate,
      builder: (context, child) => Theme(
        data: context.theme.copyWith(
          colorScheme: ColorScheme.light(
            primary: context.theme.primaryColor,
            // onSurface: AppColors.white,
            // onPrimary: AppColors.white,
          ),
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: context.theme.primaryColor,
            headerForegroundColor: AppColors.white,
            backgroundColor: AppColors.white,
            dayStyle: context.textTheme.bodyMedium?.copyWith(color: AppColors.black),
            yearStyle: context.textTheme.bodyMedium?.copyWith(color: AppColors.black),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: Styles.primaryText14.copyWith(color: Theme.of(context).primaryColor),
              backgroundBuilder: (context, states, child) => child!,
              backgroundColor: AppColors.white, // Button background color
            ),
          ),
        ),
        child: child!,
      ),
    );
  }

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
    final value = kIsWeb
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
      return TranslationFile.required;
    }
    final regex = RegExp(AppConstants.passwordPattern);
    return regex.hasMatch(value) == true ? null : TranslationFile.passwordValidationString;
  }

  /// email validator to verify email is valid or not
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return TranslationFile.required;
    }
    final regex = RegExp(AppConstants.emailPattern);
    return regex.hasMatch(value) == true ? null : TranslationFile.invalidEmail;
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
        margin: Dimens.edgeInsetsAll(Dimens.ten),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.twelve),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        content: Row(
          children: [
            if (isSuccessIcon == true) ...[
              Icon(
                Icons.check,
                color: foregroundColor ?? AppColors.white,
              ),
              Dimens.boxWidth(Dimens.ten),
            ],
            Flexible(
              child: Text(
                message,
                style: Styles.primaryText14.copyWith(color: foregroundColor ?? AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// to open external url
  static void launchExternalUrl(String link) async {
    final url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  static Widget loaderWidget({bool? isAdaptive = true}) => Center(
      child: isAdaptive == true
          ? const CircularProgressIndicator.adaptive()
          : const CircularProgressIndicator());

  /// get formated date
  static String getFormattedDateWithNumberOfDays(int? numberOfDays,
          {String? dataFormat = 'EEEE, dd MMM'}) =>
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

    return AppColors.transparent;
  }

  static String getFormattedPrice(double price, String? currencySymbol) => NumberFormat.currency(
          decimalDigits: price % 1 == 0 ? 0 : 2,
          symbol:
              currencySymbol.isEmptyOrNull ? DefaultValues.defaultCurrencySymbol : currencySymbol)
      .format(price);

  static Future<void> showCustomModalBottomSheet({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isBackButton = true,
    bool isScrollControl = false,
  }) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: Dimens.borderRadius(
            topLeftRadius: Dimens.sixteen,
            topRightRadius: Dimens.sixteen,
          ),
        ),
        isScrollControlled: isScrollControl,
        builder: (context) => Padding(
          padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.sixteen, horizontal: Dimens.eighteen)
              .copyWith(top: Dimens.twentyFour),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              builder(context),
              Positioned(
                top: -Dimens.sixtyEight,
                right: Dimens.one,
                child: InkWell(
                  onTap: () {
                    context.pop();
                  },
                  borderRadius: Dimens.borderRadiusAll(Dimens.fifty),
                  child: Container(
                    height: Dimens.thirtySix,
                    width: Dimens.thirtySix,
                    decoration: BoxDecoration(
                      borderRadius: Dimens.borderRadiusAll(Dimens.fifty),
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
        positiveButtonText: TranslationFile.ok,
      );
    } else if (errorViewType == ErrorViewType.snackBar) {
      showInSnackBar(message, context ?? exNavigatorKey.currentContext!);
    } else if (errorViewType == ErrorViewType.toast) {
      showToastMessage(message);
      _isErrorShowing = false; // Reset the flag immediately for toast
    }
  }

  //capitalize the first letter of each word
  static String capitalizeString(String text, {bool? isName}) => text.split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1);
        } else {
          return word;
        }
      }).join(' ');

  //Flutter toast message
  static showToastMessage(
    String msg, {
    ToastGravity? gravity,
  }) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity ?? ToastGravity.BOTTOM,
      backgroundColor: AppColors.black,
      textColor: AppColors.white,
    );
  }

  // closes opened dialog
  static void closeOpenDialog() {
    _isErrorShowing = false; // Reset the flag after the dialog is dismissed
    if (exNavigatorKey.currentContext!.canPop()) {
      exNavigatorKey.currentContext!.pop();
    }
  }

  // Define a function to convert a character to its base64Encode
  static String encodeChar(String char) => base64Encode(utf8.encode(char));

  //Function for converting timestamp to formatted data
  static String convertTimestamp(int timestamp, String format) =>
      DateFormat(format).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

  /// converts epoch date time into current date time
  static String getEpochConvertedTime(String timeStamp, String format) {
    final parsedDate = DateTime.parse(timeStamp);
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
    final startIndex = comIndex != -1 ? comIndex + 4 : (netIndex != -1 ? netIndex + 4 : -1);
    // If neither '.com' nor '.net' is found, return -1
    if (startIndex == -1) {
      return url.substring(url.lastIndexOf('/') + 1);
    }
    // Find the first '/' after the identified domain
    final finalIndex = url.indexOf('/', startIndex);
    return url.substring(finalIndex + 1);
  }

  /// extract text from html content
  static String? extractTextFromHtmlContent(String? htmlContent) {
    // Parse the HTML
    final document = html_parser.parse(htmlContent);

    // Extract the text content (ignores the HTML tags)
    return Utility.cleanText(
        document.body?.text ?? ''); // Use null-aware operator in case of no body.
  }

  /// remove escape sequences
  static String cleanText(String inputText) =>
      inputText.replaceAll(RegExp(r'[\n\t\r]'), ''); // Removes newline, tab, and carriage return

  ///show custom widget dialog
  static Future<void> showCustomDialog({required BuildContext context, required Widget child}) =>
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: Dimens.edgeInsetsAll(Dimens.twelve),
          shape: RoundedRectangleBorder(
            borderRadius: Dimens.borderRadiusAll(Dimens.twelve),
          ),
          backgroundColor: AppColors.dialogColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TapHandler(
                  padding: Dimens.four,
                  onTap: Utility.closeOpenDialog,
                  child: AppImage.svg(
                    AssetConstants.icCrossIcon,
                    height: Dimens.twelve,
                    width: Dimens.twelve,
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      );

  static String formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  static String formatDuration(Duration? duration) {
    if (duration == null) return '0m 0s';
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }
}

class NoFirstSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }
    return newValue;
  }
}

// Suggestion Caching Mechanism
class SuggestionCache {
  final _cache = <String, List<String>>{};
  static const int _maxCacheSize = 50;

  List<String>? get(String query) => _cache[query];

  void set(String query, List<String> suggestions) {
    // Implement LRU cache eviction if needed
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[query] = suggestions;
  }

  void clear() {
    _cache.clear();
  }
}
