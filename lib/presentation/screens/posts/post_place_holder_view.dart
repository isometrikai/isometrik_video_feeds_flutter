import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';

class PostPlaceHolderView extends StatelessWidget {
  const PostPlaceHolderView({
    super.key,
    required this.postSectionType,
    this.onTap,
  });

  final PostSectionType? postSectionType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.fifteen),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.changeOpacity(0.3),
              ),
              child: const AppImage.svg(AssetConstants.icAddFollowerPlaceHolder),
            ),
            IsrDimens.boxHeight(IsrDimens.ten),
            Text(
              postSectionType == PostSectionType.following
                  ? IsrTranslationFile.notFollowingAnyone
                  : IsrTranslationFile.noPostAvailable,
              style: IsrStyles.white14.copyWith(
                fontWeight: FontWeight.w700,
                color: IsrColors.color333333,
              ),
            ),
            if (postSectionType == PostSectionType.following) ...[
              IsrDimens.boxHeight(IsrDimens.five),
              Text(
                IsrTranslationFile.startFollowing,
                style: IsrStyles.white14.copyWith(
                  color: IsrColors.color909090,
                ),
              ),
            ],
            if (postSectionType == PostSectionType.following) ...[
              IsrDimens.boxHeight(IsrDimens.twenty),
              AppButton(
                width: IsrDimens.getDimensValue(245),
                title: IsrTranslationFile.findPeopleToFollow,
                type: ButtonType.primary,
                backgroundColor: Theme.of(context).primaryColor,
                onPress: () {
                  if (onTap != null) {
                    onTap!();
                  }
                },
              ),
            ],
          ],
        ),
      );
}
