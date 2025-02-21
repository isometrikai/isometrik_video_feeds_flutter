import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

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
  Widget build(BuildContext context) => Center(
        child: loaderType == LoaderType.normal
            ? const CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              )
            : Card(
                elevation: isDialog ? null : 0,
                color: Colors.white,
                child: Padding(
                  padding: isDialog && message != null
                      ? Dimens.edgeInsetsAll(Dimens.sixteen)
                      : Dimens.edgeInsetsAll(Dimens.eight),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                      if (isDialog && message != null) ...[
                        Dimens.boxWidth(Dimens.sixteen),
                        Text(
                          message!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      );
}
