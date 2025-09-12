import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

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
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.scaledValue),
              border: Border.all(color: AppColors.colorDBDBDB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.applyOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: Dimens.edgeInsetsAll(20.scaledValue),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title ?? '',
                    style: Styles.primaryText16
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  16.verticalSpace,
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: AppColors.colorF5F5F5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                    minHeight: 8.scaledValue,
                    borderRadius: BorderRadius.circular(4.scaledValue),
                  ),
                  8.verticalSpace,
                  Text(
                    '${(progress * 100).truncateToDouble() / 100} %',
                    style: Styles.primaryText14.copyWith(
                      color: '767676'.toHexColor,
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
