import 'package:flutter/material.dart';
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
  });

  final String subtitle;
  final String buttonText;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: 32.responsiveDimension,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppImage.svg(AssetConstants.icNearbyPlace),
          32.responsiveVerticalSpace,
          Text(
            IsrTranslationFile.seePlacesNearYou,
            style: IsrStyles.primaryText20.copyWith(
              fontWeight: FontWeight.w600,
              color: IsrColors.color242424,
            ),
          ),
          12.responsiveVerticalSpace,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: IsrStyles.primaryText16.copyWith(
              color: IsrColors.color9B9B9B,
              height: 1.4,
            ),
          ),
          40.responsiveVerticalSpace,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: IsrColors.appColor,
                foregroundColor: IsrColors.white,
                padding: IsrDimens.edgeInsetsSymmetric(
                  vertical: 16.responsiveDimension,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.responsiveDimension,
                      width: 20.responsiveDimension,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: IsrStyles.primaryText16.copyWith(
                        fontWeight: FontWeight.w600,
                        color: IsrColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
