import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CustomTextButtonWidget extends StatelessWidget {
  const CustomTextButtonWidget({
    super.key,
    this.text,
    required this.onPress,
    this.fontSize,
    this.textStyle,
    this.backgroundColor,
    this.padding,
    this.widget,
    this.borderColor,
    this.borderRadius,
  });
  final String? text;
  final Function()? onPress;
  final double? fontSize;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Widget? widget;
  final Color? borderColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) => TextButton(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white.applyOpacity(0.4); // disabled color
            }
            return Colors.white; // enabled color
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return (backgroundColor ?? Colors.black)
                  .applyOpacity(0.3); // disabled bg
            }
            return backgroundColor ?? IsrColors.transparent;
          }),
          minimumSize: WidgetStateProperty.all(Size.zero),
          padding: WidgetStateProperty.all(
            padding ??
                IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.four,
                  vertical: IsrDimens.two,
                ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(borderRadius ?? IsrDimens.six),
              side: BorderSide(color: borderColor ?? Colors.transparent),
            ),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPress,
        child: widget ??
            Text(
              text ?? '',
              style: textStyle == null
                  ? IsrStyles.secondaryText12.copyWith(
                      fontSize: fontSize ?? null,
                      color: IsrColors.color9797BE,
                      fontWeight: FontWeight.w500,
                    )
                  : textStyle,
            ),
      );
}
