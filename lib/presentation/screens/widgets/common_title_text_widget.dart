import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CommonTitleTextWidget extends StatelessWidget {
  const CommonTitleTextWidget({
    super.key,
    required this.title,
    this.showCloseIcon = true,
    this.titleColor = Colors.black,
    this.removePadding = false,
    this.titleCenter = false,
    this.titleAlign = TextAlign.left,
    this.popFn,
  });
  final String title;
  final bool showCloseIcon;
  final Color titleColor;
  final bool removePadding;
  final bool titleCenter;
  final TextAlign titleAlign;
  final VoidCallback? popFn;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: titleCenter
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: IsrDimens.edgeInsets(
                  top: removePadding
                      ? 0.responsiveDimension
                      : 16.responsiveDimension),
              child: Text(
                title,
                textAlign: titleAlign,
                style: IsrStyles.getTextStyles(
                  fontSize: IsrDimens.eighteen,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ),
          ),
          if (showCloseIcon)
            TapHandler(
              onTap: popFn ??
                  () {
                    context.pop();
                  },
              child: AppImage.svg(
                AssetConstants.icClose,
                height: IsrDimens.twentyEight,
                width: IsrDimens.twentyEight,
              ),
            ),
        ],
      );
}
