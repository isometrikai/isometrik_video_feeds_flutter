import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/create_edit_post_config.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/widgets.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class LocationPermissionPlaceholder extends StatelessWidget {
  const LocationPermissionPlaceholder({
    super.key,
    required this.subtitle,
    required this.buttonText,
    required this.isLoading,
    required this.onPressed,
    this.config,
  });

  final String subtitle;
  final String buttonText;
  final bool isLoading;
  final VoidCallback? onPressed;
  final LocationPermissionConfig? config;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonConfig = config?.buttonConfig;
    final titleStyle = config?.titleStyle ??
        IsrStyles.primaryText20.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? IsrColors.white : IsrColors.color242424,
        );
    final subtitleStyle = config?.subtitleStyle ??
        IsrStyles.primaryText16.copyWith(
          color: IsrColors.color9B9B9B,
          height: 1.4,
        );
    final buttonTextStyle = buttonConfig?.textStyle ??
        IsrStyles.primaryText16.copyWith(
          fontWeight: FontWeight.w600,
          color: IsrColors.white,
        );
    final buttonBackgroundColor =
        buttonConfig?.backgroundColor ?? IsrColors.appColor;
    final buttonBorderRadius = buttonConfig?.borderRadius ?? 12.0;
    final buttonPadding = buttonConfig?.padding ??
        IsrDimens.edgeInsetsSymmetric(
          vertical: 16.responsiveDimension,
        );

    return Center(
      child: Padding(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: 32.responsiveDimension,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage.svg(
              AssetConstants.icNearbyPlace,
              color: config?.iconColor ??
                  (isDark ? IsrColors.white : null),
            ),
            32.responsiveVerticalSpace,
            Text(
              IsrTranslationFile.seePlacesNearYou,
              style: titleStyle,
            ),
            12.responsiveVerticalSpace,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: subtitleStyle,
            ),
            40.responsiveVerticalSpace,
            SizedBox(
              width: double.infinity,
              height: buttonConfig?.height,
              child: ElevatedButton(
                // Keep the button disabled while loading or when no action exists.
                onPressed: (isLoading || onPressed == null) ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBackgroundColor,
                  foregroundColor: buttonTextStyle.color ?? IsrColors.white,
                  padding: buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20.responsiveDimension,
                        width: 20.responsiveDimension,
                        child: CircularProgressIndicator(
                          color: buttonTextStyle.color ?? IsrColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        buttonText,
                        style: buttonTextStyle,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
