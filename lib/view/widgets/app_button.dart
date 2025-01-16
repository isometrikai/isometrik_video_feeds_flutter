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
        width: width ?? IsrDimens.getScreenWidth(context),
        height: height ?? IsrDimens.appButtonHeight,
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
                  style: isDisable ? IsrStyles.appButtonDisableStyle : IsrStyles.appButtonStyle,
                  textAlign: TextAlign.center,
                ),
              ),
        ),
      );
/*Container(
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.appButtonHeight,
        constraints: BoxConstraints(
          maxHeight: IsrDimens.sixtyFour,
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
            splashColor: isDisable ? null : IsrColors.accent,
            borderRadius: IsrDimens.appButtonBorderRadius(),
            child: Ink(
              width: double.infinity,
              padding: IsrDimens.edgeInsetsAll(IsrDimens.zero),
              decoration: BoxDecoration(
                color: isDisable
                    ? IsrColors.buttonDisabledBackgroundColor
                    : IsrColors.buttonBackgroundColor,
                borderRadius: IsrDimens.appButtonBorderRadius(),
                border: Border.all(
                  width: IsrDimens.zero,
                  color: isDisable
                      ? IsrColors.buttonDisabledBackgroundColor
                      : IsrColors.buttonBackgroundColor,
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
