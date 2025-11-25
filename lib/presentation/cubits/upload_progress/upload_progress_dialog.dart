import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class UploadProgressDialog extends StatelessWidget {
  const UploadProgressDialog({
    super.key,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    var progress = 0.0;
    return BlocBuilder<UploadProgressCubit, ProgressState>(
      builder: (context, state) {
        progress = state.progress;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: IsrColors.white,
              borderRadius: BorderRadius.circular(12.responsiveDimension),
              border: Border.all(color: IsrColors.colorDBDBDB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: IsrDimens.edgeInsetsAll(20.responsiveDimension),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title ?? '',
                    style: IsrStyles.primaryText16
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  16.verticalSpace,
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: IsrColors.colorF5F5F5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                    minHeight: 8.responsiveDimension,
                    borderRadius: BorderRadius.circular(4.responsiveDimension),
                  ),
                  8.verticalSpace,
                  Text(
                    '${(progress * 100).truncateToDouble() / 100} %',
                    style: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
