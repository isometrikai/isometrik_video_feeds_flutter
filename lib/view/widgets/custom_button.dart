import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';

/// [CustomButton] widget is a custom Button.
///
/// `width` is the width of [CustomButton].
///
/// `height` is the height of [CustomButton].
///
/// `onPress` is the callback when the [CustomButton] is pressed.
///
/// `buttonType` is to define if the button is `active` or `cancelled`.
///
/// `title` is the title of the button.
///
/// `borderWidth` is the border width of the button.
///
/// `titleWidget` is the custom widget for tilte. if `titleWidget` is null `title` will be used.
///
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.width,
    this.onPress,
    this.title,
    this.color,
    this.disableColor,
    this.textColor,
    this.borderColor,
    this.padding,
    this.borderWidth,
    this.titleWidget,
    this.isDisable = false,
    this.margin,
    this.height,
    this.textAlign,
    this.radius,
    this.elevation,
    this.textStyle,
    this.isButtonWithCenterIcon,
    this.centerIcon,
  });

  final String? title;
  final double? width;
  final double? height;
  final double? radius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Function()? onPress;
  final Color? color;
  final Color? disableColor;
  final Color? textColor;
  final Color? borderColor;
  final double? borderWidth;
  final Widget? titleWidget;
  final bool isDisable;
  final TextAlign? textAlign;
  final TextStyle? textStyle;
  final double? elevation;
  final bool? isButtonWithCenterIcon;
  final Widget? centerIcon;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.all(
      Radius.circular(
        radius ?? IsrDimens.four,
      ),
    );
    return Container(
      margin: margin,
      width: width,
      height: height ?? IsrDimens.fifty,
      constraints: BoxConstraints(
        maxHeight: IsrDimens.sixtyFour,
      ),
      child: Material(
        elevation: elevation ?? IsrDimens.zero,
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisable
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (onPress != null) {
                    onPress!.call();
                  }
                },
          splashColor: isDisable ? null : Theme.of(context).splashColor,
          borderRadius: borderRadius,
          child: Ink(
            width: width ?? double.infinity,
            padding: padding ?? IsrDimens.edgeInsetsAll(IsrDimens.zero),
            decoration: BoxDecoration(
              color: isDisable
                  ? disableColor != null
                      ? disableColor
                      : IsrColors.accent
                  : color ?? IsrColors.secondaryColor,
              borderRadius: borderRadius,
              border: Border.all(
                width: borderWidth ?? 0,
                color: isDisable
                    ? IsrColors.accent
                    : borderColor != null
                        ? borderColor!
                        : color != null
                            ? color == IsrColors.white
                                ? IsrColors.secondaryColor
                                : color!
                            : IsrColors.secondaryColor,
              ),
            ),
            child: Opacity(
              opacity: isDisable ? 0.5 : 1,
              child: titleWidget ??
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isButtonWithCenterIcon != null && isButtonWithCenterIcon!) ...[
                          centerIcon!,
                          IsrDimens.boxWidth(IsrDimens.twelve),
                        ],
                        Text(
                          '$title',
                          style: textStyle != null
                              ? textStyle
                              : textColor != null
                                  ? IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w700)
                                  : IsrStyles.white14.copyWith(fontWeight: FontWeight.w700),
                          textAlign: textAlign,
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
