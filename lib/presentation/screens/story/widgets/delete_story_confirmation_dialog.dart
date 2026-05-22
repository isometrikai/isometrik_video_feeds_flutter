import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class DeleteStoryConfirmationDialog extends StatelessWidget {
  const DeleteStoryConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const DeleteStoryConfirmationDialog(),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final borderRadius = dialogConfig?.borderRadius ?? 24.0;

    return Dialog(
      backgroundColor:
          dialogConfig?.backgroundColor ?? theme.scaffoldBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: dialogConfig?.padding ??
            IsrDimens.edgeInsets(
              top: 24.responsiveDimension,
              left: 24.responsiveDimension,
              right: 24.responsiveDimension,
              bottom: 20.responsiveDimension,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.responsiveDimension,
              height: 72.responsiveDimension,
              decoration: BoxDecoration(
                color: theme.destructive.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: theme.destructive,
                size: 40,
              ),
            ),
            20.responsiveVerticalSpace,
            Text(
              IsrTranslationFile.deleteStory,
              textAlign: TextAlign.center,
              style: (dialogConfig?.titleTextStyle ??
                      IsrStyles.primaryText18.copyWith(
                        fontWeight: FontWeight.w700,
                      ))
                  .copyWith(color: theme.textPrimary),
            ),
            10.responsiveVerticalSpace,
            Text(
              IsrTranslationFile.deleteStoryConfirmation,
              textAlign: TextAlign.center,
              style:
                  (dialogConfig?.messageTextStyle ?? IsrStyles.secondaryText14)
                      .copyWith(
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
            24.responsiveVerticalSpace,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  padding: IsrDimens.edgeInsetsSymmetric(
                    vertical: 14.responsiveDimension,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.responsiveDimension),
                  ),
                ),
                child: Text(
                  IsrTranslationFile.delete,
                  style: IsrStyles.white14.copyWith(
                    color: theme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            12.responsiveVerticalSpace,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textPrimary,
                  side: BorderSide(
                    color: theme.textSecondary.withValues(alpha: 0.35),
                  ),
                  padding: IsrDimens.edgeInsetsSymmetric(
                    vertical: 14.responsiveDimension,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.responsiveDimension),
                  ),
                ),
                child: Text(
                  IsrTranslationFile.cancel,
                  style: IsrStyles.primaryText14.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
