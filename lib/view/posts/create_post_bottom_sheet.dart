import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';

class CreatePostBottomSheet extends StatelessWidget {
  const CreatePostBottomSheet({super.key, this.onCreateNewPost});

  final Function()? onCreateNewPost;
  @override
  Widget build(BuildContext context) => Padding(
        padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.sixteen, horizontal: IsrDimens.eighteen)
            .copyWith(top: IsrDimens.twentyFour, bottom: IsrDimens.thirty),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  IsrTranslationFile.create,
                  style: IsrStyles.secondaryText16.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.fifteen),
                Divider(
                  height: IsrDimens.zero,
                  color: IsrColors.colorD4D4D4,
                  thickness: IsrDimens.one,
                ),
                IsrDimens.boxHeight(IsrDimens.fifteen),
                TapHandler(
                  onTap: () {
                    context.pop();
                    if (onCreateNewPost != null) {
                      onCreateNewPost!();
                    }
                  },
                  padding: IsrDimens.five,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.post_add,
                        color: IsrColors.black,
                      ),
                      IsrDimens.boxWidth(IsrDimens.ten),
                      Text(
                        IsrTranslationFile.createAPost,
                        style: IsrStyles.secondaryText16.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.fifteen),
                TapHandler(
                  onTap: () {
                    context.pop();
                  },
                  padding: IsrDimens.five,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_list_bulleted,
                        color: IsrColors.black,
                      ),
                      IsrDimens.boxWidth(IsrDimens.ten),
                      Text(
                        IsrTranslationFile.addAProduct,
                        style: IsrStyles.secondaryText16.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: -IsrDimens.sixtyFour,
              right: IsrDimens.zero,
              child: InkWell(
                onTap: () {
                  context.pop();
                },
                borderRadius: IsrDimens.borderRadiusAll(IsrDimens.fifty),
                child: Container(
                  width: IsrDimens.twentyEight,
                  height: IsrDimens.twentyEight,
                  decoration: BoxDecoration(
                    color: IsrColors.white,
                    borderRadius: IsrDimens.borderRadiusAll(IsrDimens.fifty),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: IsrColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
