import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class UploadProgressBottomSheet extends StatelessWidget {
  const UploadProgressBottomSheet({Key? key, this.onClose, this.message})
      : super(key: key);
  final VoidCallback? onClose;
  final String? message;

  @override
  Widget build(BuildContext context) {
    var progress = 0.0;
    return BlocBuilder<UploadProgressCubit, ProgressState>(
      builder: (context, state) {
        progress = state.progress;
        return Container(
          margin: Dimens.edgeInsetsSymmetric(horizontal: 24, vertical: 20),
          padding: Dimens.edgeInsetsAll(24.scaledValue),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // if (progress < 100) ...[
              LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: Colors.grey,
                borderRadius: Dimens.borderRadiusAll(Dimens.ten),
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
              32.verticalSpace,
              Text(
                message ?? '${TranslationFile.postingPost}...',
                style: Styles.primaryText16.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // ] else ...[
              //   Lottie.asset(
              //     AssetConstants.postUploadedAnimation,
              //     animate: true,
              //     height: 70.scaledValue,
              //     width: 70.scaledValue,
              //     repeat: false,
              //   ),
              //   24.verticalSpace,
              //   Text(
              //     TranslationFile.successfullyPosted,
              //     style: Styles.primaryText16.copyWith(
              //       fontWeight: FontWeight.w700,
              //       fontSize: 18.scaledValue,
              //     ),
              //   ),
              //   8.verticalSpace,
              //   Text(
              //     TranslationFile.yourPostHasBeenSuccessfullyPosted,
              //     style: Styles.primaryText14.copyWith(
              //       color: Colors.grey,
              //       fontSize: 15.scaledValue,
              //     ),
              //     textAlign: TextAlign.center,
              //   ),
              // ],
              // 16.verticalSpace,
            ],
          ),
        );
      },
    );
  }
}
