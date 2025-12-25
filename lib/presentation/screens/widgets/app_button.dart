import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.title,
    this.type = ButtonType.primary,
    this.size = ButtonSize.large,
    this.onPress,
    this.isLoading = false,
    this.isDisable = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height,
    this.margin,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.textStyle,
    this.maxWidth,
  });

  final String title;
  final ButtonType type;
  final ButtonSize size;
  final VoidCallback? onPress;
  final bool isLoading;
  final bool isDisable;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final TextStyle? textStyle;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          width: width ?? double.infinity,
          height: height ?? _getButtonHeight(),
          child: _buildButton(context),
        ),
      );

  Widget _buildButton(BuildContext context) {
    final effectiveOnPressed = (isDisable || isLoading)
        ? null
        : onPress == null
            ? () {}
            : onPress;
    final effectiveType = isDisable
        ? type == ButtonType.text
            ? ButtonType.text
            : ButtonType.disabled
        : type;

    switch (effectiveType) {
      case ButtonType.primary:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: _getPrimaryStyle(
            context: context,
            backgroundColor: backgroundColor,
            textColor: textColor,
            borderWidth: borderWidth,
            borderColor: borderColor,
            borderRadius: borderRadius,
            textStyle: textStyle,
          ),
          child: _buildButtonContent(context),
        );
      case ButtonType.secondary:
        return OutlinedButton(
            onPressed: effectiveOnPressed,
            style: _getSecondaryStyle(context, borderColor),
            child: _buildButtonContent(context, loaderColor: borderColor));
      case ButtonType.tertiary:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: _getTertiaryStyle(
            context: context,
            backgroundColor: backgroundColor,
            textColor: textColor,
            borderWidth: borderWidth,
            borderColor: borderColor,
            borderRadius: borderRadius,
            textStyle: textStyle,
          ),
          child: _buildButtonContent(context),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: _getTextButtonStyle(
            context: context,
            textColor: isDisable
                ? Theme.of(context).primaryColor.changeOpacity(0.5)
                : textColor ?? Theme.of(context).primaryColor,
            textStyle: textStyle ??
                IsrStyles.primaryText12.copyWith(
                    color: isDisable
                        ? Theme.of(context).primaryColor.changeOpacity(0.5)
                        : textColor ?? Theme.of(context).primaryColor),
          ),
          child: _buildButtonContent(context),
        );
      case ButtonType.danger:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: _getDangerStyle(context),
          child: _buildButtonContent(context),
        );
      case ButtonType.success:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: _getSuccessStyle(context),
          child: _buildButtonContent(context),
        );
      case ButtonType.disabled:
        return FilledButton(
          onPressed: null,
          style: _getDisabledStyle(context),
          child: _buildButtonContent(context),
        );
    }
  }

  ButtonStyle _getPrimaryStyle({
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double? borderRadius,
    double? borderWidth,
    TextStyle? textStyle,
  }) =>
      FilledButton.styleFrom(
        backgroundColor: isDisable
            ? backgroundColor?.changeOpacity(0.5) ??
                Theme.of(context).primaryColor.changeOpacity(0.5)
            : backgroundColor ?? Theme.of(context).primaryColor,
        disabledBackgroundColor: backgroundColor?.changeOpacity(0.5) ??
            Theme.of(context).primaryColor.changeOpacity(0.5),
        foregroundColor: isDisable
            ? const Color(0xFF999999) // Grey text for disabled
            : textColor ?? IsrColors.primaryTextColor,
        // White text for enabled
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? IsrDimens.eight),
        ),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: _getPadding()),
      );

  ButtonStyle _getSecondaryStyle(BuildContext context, Color? borderColor) =>
      OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: isDisable ? Colors.grey : Theme.of(context).primaryColor,
        side: BorderSide(
          color: borderColor ?? Theme.of(context).primaryColor,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? IsrDimens.eight),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => IsrDimens.twelve,
            ButtonSize.medium => IsrDimens.sixteen,
            ButtonSize.large => IsrDimens.twenty,
          },
        ),
      );

  ButtonStyle _getTextButtonStyle({
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
    TextStyle? textStyle,
  }) =>
      TextButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: textColor ?? IsrColors.primaryTextColor,
        disabledForegroundColor: IsrColors.grey,
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.eight),
        textStyle: textStyle,
      );

  ButtonStyle _getTertiaryStyle({
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double? borderRadius,
    double? borderWidth,
    TextStyle? textStyle,
  }) =>
      TextButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: textColor ?? IsrColors.primaryTextColor,
        disabledForegroundColor: IsrColors.grey,
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.eight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? IsrDimens.eight),
          side: BorderSide(
              color: borderColor ?? Theme.of(context).primaryColor, width: borderWidth ?? 0.5),
        ),
        textStyle: textStyle,
      );

  ButtonStyle _getDangerStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: IsrColors.error,
        disabledBackgroundColor: IsrColors.buttonDisabledBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? IsrDimens.eight),
        ),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.sixteen),
      );

  ButtonStyle _getSuccessStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: IsrColors.success,
        disabledBackgroundColor: IsrColors.buttonDisabledBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? IsrDimens.eight),
        ),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.sixteen),
      );

  ButtonStyle _getDisabledStyle(BuildContext context) => FilledButton.styleFrom(
        disabledBackgroundColor: backgroundColor?.changeOpacity(0.5) ??
            Theme.of(context).primaryColor.changeOpacity(0.5),
        foregroundColor: IsrColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? IsrDimens.eight),
        ),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: _getPadding()),
      );

  Widget _buildButtonContent(BuildContext context, {Color? loaderColor}) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: loaderColor ?? IsrColors.white),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[prefixIcon!, SizedBox(width: IsrDimens.eight)],
        Text(title, style: textStyle ?? _getTextStyle(context)),
        if (suffixIcon != null) ...[SizedBox(width: IsrDimens.eight), suffixIcon!],
      ],
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    final fontSize = switch (size) {
      ButtonSize.small => IsrDimens.twelve,
      ButtonSize.medium => IsrDimens.fourteen,
      ButtonSize.large => IsrDimens.sixteen,
    };

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      fontFamily: AppConstants.primaryFontFamily,
    );

    if (textColor != null) return baseStyle.copyWith(color: textColor);

    return switch (type) {
      ButtonType.primary => baseStyle.copyWith(color: IsrColors.white),
      ButtonType.secondary => baseStyle.copyWith(color: IsrColors.primaryTextColor),
      ButtonType.tertiary => baseStyle.copyWith(color: IsrColors.primaryTextColor),
      ButtonType.danger => baseStyle.copyWith(color: IsrColors.white),
      ButtonType.success => baseStyle.copyWith(color: IsrColors.white),
      ButtonType.disabled => baseStyle.copyWith(color: IsrColors.grey),
      ButtonType.text => baseStyle.copyWith(color: IsrColors.primaryTextColor),
    };
  }

  double _getButtonHeight() => switch (size) {
        ButtonSize.small => IsrDimens.twentyEight,
        ButtonSize.medium => IsrDimens.thirtySix,
        ButtonSize.large => IsrDimens.fortyFour,
      };

  double _getPadding() => switch (size) {
        ButtonSize.small => IsrDimens.twelve,
        ButtonSize.medium => IsrDimens.sixteen,
        ButtonSize.large => IsrDimens.twenty,
      };
}
