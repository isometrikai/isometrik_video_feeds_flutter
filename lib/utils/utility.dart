import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as m;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:mime/mime.dart' as mime;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Utility {
  Utility._();

  static bool isLoading = false;
  static final Connectivity _connectivity = Connectivity();

  static void hideKeyboard() =>
      SystemChannels.textInput.invokeMethod('TextInput.hide');

  static void updateLater(
    VoidCallback callback, [
    bool addDelay = true,
  ]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
          addDelay ? const Duration(milliseconds: 10) : Duration.zero, () {
        callback();
      });
    });
  }

  static String jsonEncodePretty(Object? object) =>
      JsonEncoder.withIndent(' ' * 4).convert(object);

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
      barrierColor:
          loaderType == LoaderType.withBackGround ? null : Colors.transparent,
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

  static MediaType getMediaType(File file) {
    final mimeType = mime.lookupMimeType(file.path);

    if (mimeType == null) return MediaType.unknown;

    if (mimeType.startsWith('image/')) {
      return MediaType.photo;
    } else if (mimeType.startsWith('video/')) {
      return MediaType.video;
    }

    return MediaType.unknown;
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
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final borderRadius = dialogConfig?.borderRadius ?? IsrDimens.twelve;
    final backgroundColor = dialogConfig?.backgroundColor ??
        IsrColors.dialogColor;
    final padding = dialogConfig?.padding ??
        IsrDimens.edgeInsetsAll(IsrDimens.fourteen);
    final titleStyle = dialogConfig?.titleTextStyle ??
        IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w700);
    final messageStyle = dialogConfig?.messageTextStyle ?? IsrStyles.primaryText14;

    showDialog(
      context: context ?? IsrVideoReelConfig.buildContext!,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: IsrDimens.borderRadiusAll(borderRadius),
        ),
        backgroundColor: backgroundColor,
        child: Padding(
          padding: padding,
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
                  style: titleStyle,
                ),
              if (message.isStringEmptyOrNull == false) ...[
                IsrDimens.boxHeight(IsrDimens.eight),
                Text(
                  message.toString(),
                  style: messageStyle,
                  textAlign: TextAlign.center,
                ),
              ],
              IsrDimens.boxHeight(IsrDimens.twenty),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      title: positiveButtonText ?? IsrTranslationFile.ok,
                      buttonConfig: IsrVideoReelConfig.socialConfig.primaryButton,
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
                      child: _buildDialogButton(
                        title: negativeButtonText ?? IsrTranslationFile.cancel,
                        buttonConfig: IsrVideoReelConfig.socialConfig.secondaryButton,
                        buttonType: ButtonType.secondary,
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

  /// Helper method to build dialog button with ButtonConfig
  static Widget _buildDialogButton({
    required String title,
    ButtonConfig? buttonConfig,
    ButtonType buttonType = ButtonType.primary,
    required VoidCallback? onPress,
  }) => AppButton(
      width: IsrDimens.twoHundredFifty,
      title: title,
      type: buttonType,
      onPress: onPress,
      backgroundColor: buttonConfig?.backgroundColor,
      textColor: buttonConfig?.textColor,
      borderColor: buttonConfig?.borderColor,
      borderRadius: buttonConfig?.borderRadius,
    );

  /// shows bottom sheet
  static Future<T?> showBottomSheet<T>({
    required Widget child,
    bool isDarkBG = false,
    bool isDismissible = true,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? maxHeight,
    bool isRoundedCorners = true,
    bool isSafeArea = true,
  }) {
    // Try to get context from multiple sources
    final contextToUse = context ??
        ismNavigatorKey.currentContext ??
        IsrVideoReelConfig.buildContext;

    if (contextToUse == null) {
      throw FlutterError(
        'Navigator context is not available. '
        'This usually happens when:\n'
        '1. The SDK widgets (IsmPostView/IsmReelsVideoPlayerView) have not been built yet\n'
        '2. The method is called before the widget tree is initialized\n'
        'Make sure to call this after the SDK widgets are displayed.',
      );
    }

    final defaultBackgroundColor = isDarkBG
        ? Theme.of(contextToUse).primaryColor
        : (IsrVideoReelConfig.socialConfig.colorsConfig
                ?.bottomSheetBackgroundColor ??
            IsrColors.white);

    return showModalBottomSheet<T>(
      context: contextToUse,
      builder: (_) => isSafeArea
          ? SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxHeight ?? 84.percentHeight,
                ),
                child: child,
              ),
            )
          : Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight ?? 84.percentHeight,
              ),
              child: child,
            ),
      enableDrag: false,
      showDragHandle: false,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? defaultBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(IsrDimens.sixteen),
        ),
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
    return regex.hasMatch(value) == true
        ? null
        : IsrTranslationFile.passwordValidationString;
  }

  /// email validator to verify email is valid or not
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return IsrTranslationFile.required;
    }
    final regex = RegExp(AppConstants.emailPattern);
    return regex.hasMatch(value) == true
        ? null
        : IsrTranslationFile.invalidEmail;
  }

  /// email validator to verify email is valid or not
  static bool isValidEmail(String? value) {
    final regex = RegExp(AppConstants.emailPattern);
    return regex.hasMatch(value!) == true;
  }

  /// converts a double number into decimal number till 2 decimal point
  static String? convertToDecimalValue(double originalValue,
          {bool isRemoveTrailingZero = false}) =>
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
                style: IsrStyles.primaryText14
                    .copyWith(color: foregroundColor ?? IsrColors.white),
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
            ? const CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white)
            : const CircularProgressIndicator(color: Colors.white),
      );

  /// get formated date
  static String getFormattedDateWithNumberOfDays(int? numberOfDays,
          {String? dataFormat = 'EEEE, dd MMM'}) =>
      DateFormat(dataFormat)
          .format(DateTime.now().add(Duration(days: numberOfDays ?? 0)));

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

  static String getFormattedPrice(double price, String? currencySymbol) =>
      NumberFormat.currency(
              decimalDigits: price % 1 == 0 ? 0 : 2,
              symbol: currencySymbol.isStringEmptyOrNull
                  ? DefaultValues.defaultCurrencySymbol
                  : currencySymbol)
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
          padding: IsrDimens.edgeInsetsSymmetric(
                  vertical: IsrDimens.sixteen, horizontal: IsrDimens.eighteen)
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
  static String capitalizeString(String text, {bool? isName}) =>
      text.split(' ').map((word) {
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
    final toastConfig = IsrVideoReelConfig.socialConfig.toastConfig;
    final toastGravity = _mapToastGravity(
      gravity ?? _mapToastGravityType(toastConfig?.gravity),
    );
    final backgroundColor = toastConfig?.backgroundColor ?? IsrColors.black;
    final textColor = toastConfig?.textColor ?? IsrColors.white;
    final duration = toastConfig?.duration;

    Fluttertoast.showToast(
      msg: msg,
      toastLength: duration != null
          ? (duration.inSeconds >= 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT)
          : Toast.LENGTH_SHORT,
      gravity: toastGravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  static ToastGravity? _mapToastGravityType(
      ToastGravityType? gravityType) {
    if (gravityType == null) return null;
    switch (gravityType) {
      case ToastGravityType.top:
        return ToastGravity.TOP;
      case ToastGravityType.bottom:
        return ToastGravity.BOTTOM;
      case ToastGravityType.center:
        return ToastGravity.CENTER;
    }
  }

  static ToastGravity _mapToastGravity(ToastGravity? gravity) =>
      gravity ?? ToastGravity.BOTTOM;

  static BuildContext? get context =>
      IsrVideoReelConfig.getBuildContext?.call() ??
      IsrVideoReelConfig.buildContext!;

  // Define a function to convert a character to its base64Encode
  static String encodeChar(String char) => base64Encode(utf8.encode(char));

  //Function for converting timestamp to formatted data
  static String convertTimestamp(int timestamp, String format) =>
      DateFormat(format)
          .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

  /// converts epoch date time into current date time
  static String getEpochConvertedTime(String timeStamp, String format) {
    var parsedDate = DateTime.parse(timeStamp);
    return DateFormat(format).format(parsedDate);
  }

  // /// returns gumlet image url
  // static String buildGumletImageUrl({required String imageUrl, double? width, double? height}) {
  //   final finalImageUrl = removeSourceUrl(imageUrl);
  //   return '${AppUrl.gumletUrl}/$finalImageUrl?w=${width ?? 0}&h=${height ?? 0}';
  // }

  /// returns gumlet image url
  static String buildGumletImageUrl(
      {required String imageUrl, double? width, double? height}) {
    final finalImageUrl =
        removeSourceUrl(imageUrl).replaceAll('trulyfree-staging/', '');
    final queryParameter = StringBuffer();
    if (width != null && width != 0) {
      queryParameter.write('w=$width');
    }
    if (height != null && height != 0) {
      if (queryParameter.isNotEmpty) {
        queryParameter.write('&');
      }
      queryParameter.write('h=$height');
    }
    // queryParameter.write('&q=70');

    final optimizedImageUrl =
        '${AppUrl.gumletUrl}/$finalImageUrl${queryParameter.isNotEmpty ? '?$queryParameter' : ''}';
    return optimizedImageUrl;
  }

  /// removes source url and extract only file name
  static String removeSourceUrl(String url) {
    // Find the index of '.com' or '.net'
    final comIndex = url.indexOf('.com');
    final netIndex = url.indexOf('.net');

    // Determine the starting point for searching the slash
    var startIndex =
        comIndex != -1 ? comIndex + 4 : (netIndex != -1 ? netIndex + 4 : -1);
    // If neither '.com' nor '.net' is found, return -1
    if (startIndex == -1) {
      return url.substring(url.lastIndexOf('/') + 1);
    }
    // Find the first '/' after the identified domain
    final finalIndex = url.indexOf('/', startIndex);
    return url.substring(finalIndex + 1);
  }

  /// remove escape sequences
  static String cleanText(String inputText) => inputText.replaceAll(
      RegExp(r'[\n\t\r]'), ''); // Removes newline, tab, and carriage return

  ///show custom widget dialog
  static Future<void> showCustomDialog(
          {required BuildContext context, required Widget child}) {
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final borderRadius = dialogConfig?.borderRadius ?? IsrDimens.twelve;
    final backgroundColor = dialogConfig?.backgroundColor ??
        IsrColors.dialogColor;
    final padding = dialogConfig?.padding ??
        IsrDimens.edgeInsetsAll(IsrDimens.twelve);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: IsrDimens.borderRadiusAll(borderRadius),
        ),
        backgroundColor: backgroundColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TapHandler(
                padding: IsrDimens.four,
                onTap: Utility.closeOpenDialog,
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
  }

  static bool _isErrorShowing =
      false; // Flag to track if an error is currently displayed

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

  static bool isLocalUrl(String url) =>
      url.startsWith('http://') == false && url.startsWith('https://') == false;

  static String generateRandomId(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = m.Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  static String getInitials({
    required String firstName,
    required String lastName,
  }) {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (firstName.isEmpty) return lastName[0].toUpperCase();
    if (lastName.isEmpty) return firstName[0].toUpperCase();
    return '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
  }

  /// Builds text spans with highlighted usernames and hashtags from comment tags
  ///
  /// This function processes comment text and highlights usernames (@username) and
  /// hashtags (#hashtag) based on the tags data from the comment.
  ///
  /// [text] - The comment text to process
  /// [baseStyle] - Base text style for normal text
  /// [tags] - Comment tags containing mentions and hashtags data
  /// [onUsernameTap] - Callback when username is tapped
  /// [onHashtagTap] - Callback when hashtag is tapped
  /// [maxLength] - If set and text is longer, show "view more" when collapsed
  /// [isExpanded] - When true and text is truncated, show full text and "view less"
  /// [viewMoreLabel] - Label for the "view more" link (default from translations)
  /// [viewLessLabel] - Label for the "view less" link (default from translations)
  /// [onViewMoreTap] - Callback when "view more" is tapped
  /// [onViewLessTap] - Callback when "view less" is tapped
  static List<TextSpan> buildCommentTextSpans(
    String text,
    TextStyle baseStyle,
    CommentTags? tags, {
    Function(String)? onUsernameTap,
    Function(String)? onHashtagTap,
    int? maxLength,
    bool isExpanded = true,
    String? viewMoreLabel,
    String? viewLessLabel,
    VoidCallback? onViewMoreTap,
    VoidCallback? onViewLessTap,
  }) {
    final spans = <TextSpan>[];

    if (text.isEmpty) return spans;

    final effectiveMaxLength = maxLength;
    final showViewMoreLess = effectiveMaxLength != null &&
        effectiveMaxLength > 0 &&
        text.length > effectiveMaxLength;

    final displayText = (showViewMoreLess && !isExpanded)
        ? text.substring(0, effectiveMaxLength!)
        : text;

    // Create a list of all tagged positions (mentions and hashtags)
    final taggedPositions = <TagPosition>[];

    // Add mention positions (only within displayText range when truncated)
    if (tags?.mentions != null) {
      for (final mention in tags!.mentions!) {
        if (mention.textPosition != null) {
          final start = mention.textPosition!.start?.toInt() ?? 0;
          final end = mention.textPosition!.end?.toInt() ?? 0;
          if (end <= displayText.length) {
            taggedPositions.add(TagPosition(
              start: start,
              end: end,
              type: Tag.mention,
              data: mention,
            ));
          }
        }
      }
    }

    // Add hashtag positions
    if (tags?.hashtags != null) {
      for (final hashtag in tags!.hashtags!) {
        if (hashtag.textPosition != null) {
          final start = hashtag.textPosition!.start?.toInt() ?? 0;
          final end = hashtag.textPosition!.end?.toInt() ?? 0;
          if (end <= displayText.length) {
            taggedPositions.add(TagPosition(
              start: start,
              end: end,
              type: Tag.hashtag,
              data: hashtag,
            ));
          }
        }
      }
    }

    // Sort positions by start index
    taggedPositions.sort((a, b) => a.start.compareTo(b.start));

    // Also handle URLs (only within displayText range when truncated)
    final urlRegex = RegExp(r'(https?:\/\/\S+|www\.\S+)', caseSensitive: false);
    final urlMatches = urlRegex.allMatches(displayText);
    for (final match in urlMatches) {
      if (match.end <= displayText.length) {
        taggedPositions.add(TagPosition(
          start: match.start,
          end: match.end,
          type: Tag.url,
          data: null,
        ));
      }
    }

    // Sort again to include URLs
    taggedPositions.sort((a, b) => a.start.compareTo(b.start));

    var currentIndex = 0;

    for (final position in taggedPositions) {
      // Add normal text before the tagged position
      if (position.start > currentIndex) {
        spans.add(
          TextSpan(
            text: displayText.substring(currentIndex, position.start),
            style: baseStyle,
          ),
        );
      }

      // Add the tagged text with appropriate styling and tap handler
      final taggedText = displayText.substring(position.start, position.end);
      var taggedStyle = baseStyle;
      TapGestureRecognizer? recognizer;

      switch (position.type) {
        case Tag.mention:
          taggedStyle = baseStyle.copyWith(
            fontWeight: FontWeight.w600,
          );
          recognizer = TapGestureRecognizer()
            ..onTap = () {
              if (onUsernameTap != null &&
                  position.data is CommentMentionData) {
                final mentionData = position.data as CommentMentionData;
                onUsernameTap(mentionData.userId ?? '');
              }
            };
          break;

        case Tag.hashtag:
          taggedStyle = baseStyle.copyWith(
            fontWeight: FontWeight.w600,
          );
          recognizer = TapGestureRecognizer()
            ..onTap = () {
              if (onHashtagTap != null && position.data is CommentMentionData) {
                final hashtagData = position.data as CommentMentionData;
                onHashtagTap(hashtagData.tag ?? '');
              }
            };
          break;

        case Tag.url:
          taggedStyle = baseStyle.copyWith(
            color: IsrColors.appColor,
            decoration: TextDecoration.underline,
          );
          final urlToLaunch = taggedText.startsWith('http')
              ? taggedText
              : 'https://$taggedText';
          recognizer = TapGestureRecognizer()
            ..onTap = () {
              Utility.launchExternalUrl(urlToLaunch);
            };
          break;
      }

      spans.add(
        TextSpan(
          text: taggedText,
          style: taggedStyle,
          recognizer: recognizer,
        ),
      );

      currentIndex = position.end;
    }

    // Add remaining text
    if (currentIndex < displayText.length) {
      spans.add(
        TextSpan(
          text: displayText.substring(currentIndex),
          style: baseStyle,
        ),
      );
    }

    // Append "view more" or "view less" when applicable
    if (showViewMoreLess) {
      final linkStyle = baseStyle.copyWith(
        color: IsrColors.appColor,
        fontWeight: FontWeight.w600,
      );
      if (!isExpanded) {
        final label = viewMoreLabel ?? IsrTranslationFile.viewMore;
        spans.add(TextSpan(text: ' '));
        spans.add(
          TextSpan(
            text: label,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onViewMoreTap?.call(),
          ),
        );
      } else {
        final label = viewLessLabel ?? IsrTranslationFile.viewLess;
        spans.add(TextSpan(text: ' '));
        spans.add(
          TextSpan(
            text: label,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onViewLessTap?.call(),
          ),
        );
      }
    }

    return spans;
  }

  // get time ago
  static String getTimeAgoFromDateTime(DateTime? dateTime,
      {bool showJustNow = false}) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 5 && showJustNow == true) {
      return IsrTranslationFile.justNow;
    }

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7}w';
    }

    if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30}mo';
    }

    return '${difference.inDays ~/ 365}y';
  }

  //Show bottom sheet with Customized child
  static Future<T?> showCustomizedBottomSheet<T>({
    required Widget child,
    double? padding,
    bool isDarkBG = false,
    bool isDismissible = true,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? maxHeight,
    bool isRoundedCorners = true,
  }) {
    // Try to get context from multiple sources
    final contextToUse = context ??
        ismNavigatorKey.currentContext ??
        IsrVideoReelConfig.buildContext;
    return showModalBottomSheet<T>(
      context: contextToUse!,
      builder: (_) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight ?? double.infinity,
          ),
          padding: IsrDimens.edgeInsetsAll(padding ?? IsrDimens.fourteen),
          child: child,
        ),
      ),
      useSafeArea: true,
      enableDrag: false,
      showDragHandle: false,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ??
          (isDarkBG ? Theme.of(contextToUse).primaryColor : IsrColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
              isRoundedCorners ? IsrDimens.bottomSheetBorderRadius : 0),
        ),
      ),
    );
  }
}

/// Helper class to represent tagged positions in text
class TagPosition {
  TagPosition({
    required this.start,
    required this.end,
    required this.type,
    this.data,
  });

  final int start;
  final int end;
  final Tag type;
  final dynamic data;
}

/// Enum to represent different types of tagged content
enum Tag {
  mention,
  hashtag,
  url,
}

class NoFirstSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }
    return newValue;
  }
}

class CapitalizeTextFormatter extends TextInputFormatter {
  CapitalizeTextFormatter({this.capitalizeOnlyFirstLetter = false});
  final bool capitalizeOnlyFirstLetter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Capitalize the text using the same logic as Utility.capitalizeString
    final capitalizedText = _capitalizeString(
      newValue.text,
      capitalizeOnlyFirstLetter: capitalizeOnlyFirstLetter,
    );

    return TextEditingValue(
      text: capitalizedText,
      selection: newValue.selection, // Preserve cursor position
    );
  }

  String _capitalizeString(String text,
      {bool capitalizeOnlyFirstLetter = false}) {
    if (text.isEmpty) return text;

    if (capitalizeOnlyFirstLetter) {
      return text[0].toUpperCase() + text.substring(1);
    }

    return text.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      } else {
        return word;
      }
    }).join(' ');
  }
}
