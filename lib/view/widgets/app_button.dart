import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';

/// [AppButton] widget is a custom Button.
/// `onPress` is the callback when the [AppButton] is pressed.
/// `title` is the title of the button.
/// `titleWidget` is the custom widget for title. if `titleWidget` is null `title` will be used.

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.onPress,
    this.title,
    this.titleWidget,
    this.isDisable = false,
    this.height,
    this.width,
    this.margin,
  });

  final String? title;
  final Function()? onPress;
  final Widget? titleWidget;
  final bool isDisable;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        width: width ?? Dimens.getScreenWidth(context),
        height: height ?? Dimens.appButtonHeight,
        child: TextButton(
          onPressed: isDisable
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (onPress != null) {
                    onPress!();
                  }
                },
          style: Theme.of(context).textButtonTheme.style,
          child: titleWidget ??
              Center(
                child: Text(
                  title ?? '',
                  style: isDisable ? Styles.appButtonDisableStyle : Styles.appButtonStyle,
                  textAlign: TextAlign.center,
                ),
              ),
        ),
      );
/*Container(
        width: Dimens.getScreenWidth(context),
        height: Dimens.appButtonHeight,
        constraints: BoxConstraints(
          maxHeight: Dimens.sixtyFour,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisable
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (onPress != null) {
                      onPress!();
                    }
                  },
            splashColor: isDisable ? null : AppColors.accent,
            borderRadius: Dimens.appButtonBorderRadius(),
            child: Ink(
              width: double.infinity,
              padding: Dimens.edgeInsetsAll(Dimens.zero),
              decoration: BoxDecoration(
                color: isDisable
                    ? AppColors.buttonDisabledBackgroundColor
                    : AppColors.buttonBackgroundColor,
                borderRadius: Dimens.appButtonBorderRadius(),
                border: Border.all(
                  width: Dimens.zero,
                  color: isDisable
                      ? AppColors.buttonDisabledBackgroundColor
                      : AppColors.buttonBackgroundColor,
                ),
              ),
              child: Opacity(
                opacity: isDisable ? 0.5 : 1,
                child: titleWidget ??
                    Center(
                      child: Text(
                        '$title',
                        style: isDisable
                            ? Styles.appButtonDisableStyle
                            : Styles.appButtonStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
              ),
            ),
          ),
        ),
      );*/
}
