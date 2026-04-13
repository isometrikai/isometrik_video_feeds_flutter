import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.isDialog = true,
    this.message,
    this.loaderType = LoaderType.withBackGround,
  });

  final bool isDialog;
  final String? message;
  final LoaderType? loaderType;

  @override
  Widget build(BuildContext context) {
    final appLoaderBuilder = IsrVideoReelConfig.socialConfig.loaderBuilder;
    if (appLoaderBuilder != null) {
      // Reuse host app loader everywhere SDK uses AppLoader.
      return appLoaderBuilder(
        context,
        isDialog: isDialog,
        message: message,
        loaderType: loaderType,
        isAdaptive: false,
      );
    }

    return Center(
      child: _buildDefaultLoader(),
    );
  }

  Widget _buildDefaultLoader() {
    final indicator = const CircularProgressIndicator(
      color: Colors.blue,
      strokeWidth: 3,
    );

    // Keep transparent loader truly transparent (no white card).
    if (loaderType == LoaderType.normal ||
        loaderType == LoaderType.withoutBackground) {
      return indicator;
    }

    return Card(
      elevation: isDialog ? null : 0,
      color: Colors.white,
      child: Padding(
        padding: isDialog && message != null
            ? IsrDimens.edgeInsetsAll(IsrDimens.sixteen)
            : IsrDimens.edgeInsetsAll(IsrDimens.eight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (isDialog && message != null) ...[
              IsrDimens.boxWidth(IsrDimens.sixteen),
              Text(
                message!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
