import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

class CreatePostBottomSheet extends StatelessWidget {
  const CreatePostBottomSheet({super.key, this.onCreateNewPost});

  final Function()? onCreateNewPost;
  @override
  Widget build(BuildContext context) => Padding(
        padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.sixteen, horizontal: Dimens.eighteen)
            .copyWith(top: Dimens.twentyFour, bottom: Dimens.thirty),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TranslationFile.create,
                  style: Styles.secondaryText16.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Dimens.boxHeight(Dimens.fifteen),
                Divider(
                  height: Dimens.zero,
                  color: AppColors.colorD4D4D4,
                  thickness: Dimens.one,
                ),
                Dimens.boxHeight(Dimens.fifteen),
                TapHandler(
                  onTap: () {
                    context.pop();
                    if (onCreateNewPost != null) {
                      onCreateNewPost!();
                    }
                  },
                  padding: Dimens.five,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.post_add,
                        color: AppColors.black,
                      ),
                      Dimens.boxWidth(Dimens.ten),
                      Text(
                        TranslationFile.createAPost,
                        style: Styles.secondaryText16.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Dimens.boxHeight(Dimens.fifteen),
                TapHandler(
                  onTap: () {
                    context.pop();
                  },
                  padding: Dimens.five,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_list_bulleted,
                        color: AppColors.black,
                      ),
                      Dimens.boxWidth(Dimens.ten),
                      Text(
                        TranslationFile.addAProduct,
                        style: Styles.secondaryText16.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: -Dimens.sixtyFour,
              right: Dimens.zero,
              child: InkWell(
                onTap: () {
                  context.pop();
                },
                borderRadius: Dimens.borderRadiusAll(Dimens.fifty),
                child: Container(
                  width: Dimens.twentyEight,
                  height: Dimens.twentyEight,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: Dimens.borderRadiusAll(Dimens.fifty),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
