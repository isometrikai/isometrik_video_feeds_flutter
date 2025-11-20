import 'package:flutter/material.dart';

class MediaEditConfig {
  MediaEditConfig({
    //colors
    Color? primaryColor,
    this.primaryTextColor = MediaEditConstant.primaryTextColor,
    this.backgroundColor = MediaEditConstant.backgroundColor,
    this.appBarColor = MediaEditConstant.appBarColor,
    this.greyColor = MediaEditConstant.greyColor,
    this.blackColor = MediaEditConstant.blackColor,
    this.whiteColor = MediaEditConstant.whiteColor,

    //styles
    this.primaryFontFamily = MediaEditConstant.primaryFontFamily,

    //icons
    Widget? closeIcon,
    Widget? removeIcon,
    Widget? addMoreIcon,
    Widget? editIcon,
    Widget? playIcon,
    Widget? pauseIcon,
    Widget? checkIcon,

    //text
    this.removeMediaTitle = MediaEditConstant.removeMediaTitle,
    this.removeMediaMessage = MediaEditConstant.removeMediaMessage,
    this.removeButtonText = MediaEditConstant.removeButtonText,
    this.cancelButtonText = MediaEditConstant.cancelButtonText,
    this.editCoverTitle = MediaEditConstant.editCoverTitle,
    this.addFromGalleryText = MediaEditConstant.addFromGalleryText,
    this.extractingFramesText = MediaEditConstant.extractingFramesText,
    this.extractedFramesText = MediaEditConstant.extractedFramesText,
    this.selectFrameMessage = MediaEditConstant.selectFrameMessage,

    //dialog function
    this.showDialogFunction = MediaEditConstant.showDialogFunction,

    //text styles
    TextStyle? primaryText14,
    TextStyle? primaryText18,
  })  : primaryColor = primaryColor ?? MediaEditConstant.primaryColor,
        closeIcon = closeIcon ?? MediaEditConstant.closeIcon(color: Colors.black),
        removeIcon = removeIcon ?? MediaEditConstant.removeIcon(color: Colors.red),
        addMoreIcon = addMoreIcon ?? MediaEditConstant.addMoreIcon(color: primaryColor ?? MediaEditConstant.primaryColor),
        editIcon = editIcon ?? MediaEditConstant.editIcon(color: primaryColor ?? MediaEditConstant.primaryColor),
        playIcon = playIcon ?? MediaEditConstant.playIcon(color: Colors.white),
        pauseIcon = pauseIcon ?? MediaEditConstant.pauseIcon(color: Colors.white),
        checkIcon = checkIcon ?? MediaEditConstant.checkIcon(color: primaryColor ?? MediaEditConstant.primaryColor),
        primaryText14 = primaryText14 ?? MediaEditConstant.primaryText14,
        primaryText18 = primaryText18 ?? MediaEditConstant.primaryText18;

  //colors
  final Color primaryColor;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color appBarColor;
  final Color greyColor;
  final Color blackColor;
  final Color whiteColor;

  //styles
  final String primaryFontFamily;

  //icons
  final Widget closeIcon;
  final Widget removeIcon;
  final Widget addMoreIcon;
  final Widget editIcon;
  final Widget playIcon;
  final Widget pauseIcon;
  final Widget checkIcon;

  //text
  final String removeMediaTitle;
  final String removeMediaMessage;
  final String removeButtonText;
  final String cancelButtonText;
  final String editCoverTitle;
  final String addFromGalleryText;
  final String extractingFramesText;
  final String extractedFramesText;
  final String selectFrameMessage;

  //dialog function
  final Future<void> Function({
    required BuildContext context,
    required String title,
    required String message,
    required String positiveButtonText,
    required String negativeButtonText,
    required VoidCallback onPressPositiveButton,
    required VoidCallback onPressNegativeButton,
  }) showDialogFunction;

  //text styles
  final TextStyle primaryText14;
  final TextStyle primaryText18;
}

class MediaEditConstant {
  //colors
  static const Color primaryColor = Colors.blue;
  static const Color primaryTextColor = Colors.black;
  static const Color backgroundColor = Colors.white;
  static const Color appBarColor = Colors.white;
  static const Color greyColor = Colors.grey;
  static const Color blackColor = Colors.black;
  static const Color whiteColor = Colors.white;

  //styles
  static const String primaryFontFamily = 'Inter';

  //icons - methods to create icons with dynamic colors
  static Widget closeIcon({Color? color}) => Icon(
        Icons.close,
        color: color ?? Colors.black,
        size: 24,
      );

  static Widget removeIcon({Color? color}) => Icon(
        Icons.delete,
        color: color ?? Colors.red,
        size: 24,
      );

  static Widget addMoreIcon({Color? color}) => Icon(
        Icons.add,
        color: color ?? MediaEditConstant.primaryColor,
        size: 24,
      );

  static Widget editIcon({Color? color}) => Icon(
        Icons.edit,
        color: color ?? MediaEditConstant.primaryColor,
        size: 24,
      );

  static Widget playIcon({Color? color}) => Icon(
        Icons.play_arrow,
        color: color ?? Colors.white,
        size: 30,
      );

  static Widget pauseIcon({Color? color}) => Icon(
        Icons.pause,
        color: color ?? Colors.white,
        size: 30,
      );

  static Widget checkIcon({Color? color}) => Icon(
        Icons.check,
        color: color ?? MediaEditConstant.primaryColor,
        size: 24,
      );

  //text
  static const String removeMediaTitle = 'Remove Media';
  static const String removeMediaMessage = 'Are you sure you want to remove this media?';
  static const String removeButtonText = 'Remove';
  static const String cancelButtonText = 'Cancel';
  static const String editCoverTitle = 'Edit Cover';
  static const String addFromGalleryText = 'Add from Gallery';
  static const String extractingFramesText = 'Extracting frames ...';
  static const String extractedFramesText = 'Extracted frames';
  static const String selectFrameMessage = 'Please select a frame or choose from gallery';

  //default dialog function
  static Future<void> showDialogFunction({
    required BuildContext context,
    required String title,
    required String message,
    required String positiveButtonText,
    required String negativeButtonText,
    required VoidCallback onPressPositiveButton,
    required VoidCallback onPressNegativeButton,
  }) async => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
          title: Text(
            title,
            style: primaryText18,
          ),
          content: Text(
            message,
            style: primaryText14,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPressNegativeButton();
              },
              child: Text(
                negativeButtonText,
                style: primaryText14.copyWith(
                  color: whiteColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPressPositiveButton();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red
              ),
              child: Text(
                positiveButtonText,
                style: primaryText14.copyWith(
                  color: whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
    );

  //text styles
  static const TextStyle primaryText14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const TextStyle primaryText18 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
}
