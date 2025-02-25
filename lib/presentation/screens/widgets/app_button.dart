import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.title,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.onPress,
    this.isLoading = false,
    this.isDisable = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.margin,
    this.backgroundColor,
    this.textColor,
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
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: SizedBox(
          width: width ?? double.infinity,
          height: _getButtonHeight(),
          child: _buildButton(context),
        ),
      );

  Widget _buildButton(BuildContext context) {
    final effectiveOnPressed = (isDisable || isLoading) ? null : onPress;
    final effectiveType = isDisable ? ButtonType.disabled : type;

    switch (effectiveType) {
      case ButtonType.primary:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: _getPrimaryStyle(context),
          child: _buildButtonContent(context),
        );
      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _getSecondaryStyle(context),
          child: _buildButtonContent(context),
        );
      case ButtonType.tertiary:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: _getTertiaryStyle(context),
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

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: IsrColors.white,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          prefixIcon!,
          SizedBox(width: IsrDimens.eight),
        ],
        Text(title, style: _getTextStyle(context)),
        if (suffixIcon != null) ...[
          SizedBox(width: IsrDimens.eight),
          suffixIcon!,
        ],
      ],
    );
  }

  double _getButtonHeight() => switch (size) {
        ButtonSize.small => IsrDimens.twentyEight, // 28h for small
        ButtonSize.medium => IsrDimens.thirtySix, // 36h for medium
        ButtonSize.large => IsrDimens.fortyFour, // 44h for large
      };

  TextStyle _getTextStyle(BuildContext context) {
    final fontSize = switch (size) {
      ButtonSize.small => IsrDimens.twelve, // 12sp for small
      ButtonSize.medium => IsrDimens.fourteen, // 14sp for medium
      ButtonSize.large => IsrDimens.sixteen, // 16sp for large
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
    };
  }

  ButtonStyle _getPrimaryStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: isDisable
            ? const Color(0xFFE6E6E6) // Light grey for disabled
            : backgroundColor ?? Theme.of(context).primaryColor,
        // Blue for enabled
        disabledBackgroundColor: const Color(0xFFE6E6E6),
        foregroundColor: isDisable
            ? const Color(0xFF999999) // Grey text for disabled
            : IsrColors.white,
        // White text for enabled
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.hundred),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => IsrDimens.twelve,
            ButtonSize.medium => IsrDimens.sixteen,
            ButtonSize.large => IsrDimens.twenty,
          },
        ),
      );

  ButtonStyle _getSecondaryStyle(BuildContext context) => OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: isDisable
            ? const Color(0xFF999999) // Grey text for disabled
            : Theme.of(context).primaryColor,
        // Blue text for enabled
        side: BorderSide(
          color: isDisable
              ? const Color(0xFFE6E6E6) // Light grey border for disabled
              : Theme.of(context).primaryColor, // Blue border for enabled
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.hundred),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => IsrDimens.twelve,
            ButtonSize.medium => IsrDimens.sixteen,
            ButtonSize.large => IsrDimens.twenty,
          },
        ),
      );

  ButtonStyle _getTertiaryStyle(BuildContext context) => TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: IsrColors.primaryTextColor,
        disabledForegroundColor: IsrColors.grey,
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.eight),
      );

  ButtonStyle _getDangerStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: IsrColors.error,
        disabledBackgroundColor: IsrColors.buttonDisabledBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.twelve),
        ),
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.sixteen),
      );

  ButtonStyle _getSuccessStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: IsrColors.success,
        disabledBackgroundColor: IsrColors.buttonDisabledBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.twelve),
        ),
        padding: EdgeInsets.symmetric(horizontal: IsrDimens.sixteen),
      );

  ButtonStyle _getDisabledStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE6E6E6), // Light grey background
        foregroundColor: const Color(0xFF999999), // Grey text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.hundred),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => IsrDimens.twelve,
            ButtonSize.medium => IsrDimens.sixteen,
            ButtonSize.large => IsrDimens.twenty,
          },
        ),
      );
}
