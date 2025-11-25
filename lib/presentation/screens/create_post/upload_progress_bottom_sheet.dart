import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';

class UploadProgressBottomSheet extends StatelessWidget {
  const UploadProgressBottomSheet({Key? key, this.onClose, this.message})
      : super(key: key);
  final VoidCallback? onClose;
  final String? message;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<UploadProgressCubit, ProgressState>(
        builder: (context, state) => Container(
          margin: IsrDimens.edgeInsetsSymmetric(
              horizontal: 16.responsiveDimension,
              vertical: 20.responsiveDimension),
          padding: IsrDimens.edgeInsetsAll(24.responsiveDimension),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.title,
                style: IsrStyles.primaryText16.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              24.verticalSpace,
              if (state.isSuccess) ...[
                // Show success animation
                Center(
                  child: Row(
                    children: [
                      Lottie.asset(
                        AssetConstants.postUploadedAnimation,
                        animate: true,
                        height: 40.responsiveDimension,
                        width: 40.responsiveDimension,
                        repeat: false,
                      ),
                      8.horizontalSpace,
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              IsrTranslationFile.successfullyUploaded,
                              style: IsrStyles.primaryText16.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            8.verticalSpace,
                            Text(
                              IsrTranslationFile
                                  .yourMediaFilesHaveBeenUploadedSuccessfully,
                              style: IsrStyles.primaryText14.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.subtitle, // Show filename with count
                        style: IsrStyles.primaryText14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${state.progress.toStringAsFixed(0)}%',
                      style: IsrStyles.primaryText14.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: state.progress / 100,
                    minHeight: 4,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
