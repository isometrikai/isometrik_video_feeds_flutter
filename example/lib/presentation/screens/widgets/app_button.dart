import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

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
    this.height,
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
  final double? height;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: SizedBox(
          width: width ?? double.infinity,
          height: height ?? _getButtonHeight(),
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
          color: AppColors.white,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          prefixIcon!,
          SizedBox(width: Dimens.eight),
        ],
        Text(title, style: _getTextStyle(context)),
        if (suffixIcon != null) ...[
          SizedBox(width: Dimens.eight),
          suffixIcon!,
        ],
      ],
    );
  }

  double _getButtonHeight() => switch (size) {
        ButtonSize.small => Dimens.twentyEight, // 28h for small
        ButtonSize.medium => Dimens.thirtySix, // 36h for medium
        ButtonSize.large => Dimens.fortyFour, // 44h for large
      };

  TextStyle _getTextStyle(BuildContext context) {
    final fontSize = switch (size) {
      ButtonSize.small => Dimens.twelve, // 12sp for small
      ButtonSize.medium => Dimens.fourteen, // 14sp for medium
      ButtonSize.large => Dimens.sixteen, // 16sp for large
    };

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      fontFamily: AppConstants.primaryFontFamily,
    );

    if (textColor != null) return baseStyle.copyWith(color: textColor);

    return switch (type) {
      ButtonType.primary => baseStyle.copyWith(color: AppColors.white),
      ButtonType.secondary =>
        baseStyle.copyWith(color: AppColors.primaryTextColor),
      ButtonType.tertiary =>
        baseStyle.copyWith(color: AppColors.primaryTextColor),
      ButtonType.danger => baseStyle.copyWith(color: AppColors.white),
      ButtonType.success => baseStyle.copyWith(color: AppColors.white),
      ButtonType.disabled => baseStyle.copyWith(color: AppColors.grey),
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
            : AppColors.white,
        // White text for enabled
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.hundred),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => Dimens.twelve,
            ButtonSize.medium => Dimens.sixteen,
            ButtonSize.large => Dimens.twenty,
          },
        ),
      );

  ButtonStyle _getSecondaryStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
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
          borderRadius: BorderRadius.circular(Dimens.hundred),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => Dimens.twelve,
            ButtonSize.medium => Dimens.sixteen,
            ButtonSize.large => Dimens.twenty,
          },
        ),
      );

  ButtonStyle _getTertiaryStyle(BuildContext context) => TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryTextColor,
        disabledForegroundColor: AppColors.grey,
        padding: EdgeInsets.symmetric(horizontal: Dimens.eight),
      );

  ButtonStyle _getDangerStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: AppColors.error,
        disabledBackgroundColor: AppColors.buttonDisabledBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.twelve),
        ),
        padding: EdgeInsets.symmetric(horizontal: Dimens.sixteen),
      );

  ButtonStyle _getSuccessStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: AppColors.success,
        disabledBackgroundColor: AppColors.buttonDisabledBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.twelve),
        ),
        padding: EdgeInsets.symmetric(horizontal: Dimens.sixteen),
      );

  ButtonStyle _getDisabledStyle(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE6E6E6), // Light grey background
        foregroundColor: const Color(0xFF999999), // Grey text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.hundred),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: switch (size) {
            ButtonSize.small => Dimens.twelve,
            ButtonSize.medium => Dimens.sixteen,
            ButtonSize.large => Dimens.twenty,
          },
        ),
      );
}
