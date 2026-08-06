import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Default success UI for the rejected-post inline resubmit flow.
class RejectedPostResubmitSuccessView extends StatelessWidget {
  const RejectedPostResubmitSuccessView({
    super.key,
    required this.data,
  });

  final RejectedPostResubmitSuccessData data;

  /// SDK default builder used when the host does not pass a custom success widget.
  static RejectedPostResubmitSuccessBuilder get defaultBuilder =>
      (context, data) => RejectedPostResubmitSuccessView(data: data);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: IsrDimens.twentyFour,
          bottom: IsrDimens.twentyFour,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: IsrDimens.sixtyFour,
              height: IsrDimens.sixtyFour,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 32),
            ),
            IsrDimens.boxHeight(IsrDimens.sixteen),
            Text(
              IsrTranslationFile.postDetailsResubmittedTitle,
              textAlign: TextAlign.center,
              style: IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w700),
            ),
            IsrDimens.boxHeight(IsrDimens.twelve),
            Text(
              data.sheetData.resubmittedMessage ??
                  IsrTranslationFile.postDetailsResubmittedMessage(data.replacedCount),
              textAlign: TextAlign.center,
              style: IsrStyles.primaryText14.copyWith(
                color: IsrColors.secondaryTextColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
}
