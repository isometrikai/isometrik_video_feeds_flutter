import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class StoryPostedSuccessDialog extends StatelessWidget {
  const StoryPostedSuccessDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const StoryPostedSuccessDialog(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);

    return Dialog(
      backgroundColor: theme.scaffoldBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: IsrDimens.edgeInsets(
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
                color: theme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: theme.success, size: 44),
            ),
            20.responsiveVerticalSpace,
            Text(
              'Story Posted Successfully',
              textAlign: TextAlign.center,
              style: IsrStyles.primaryText18.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            10.responsiveVerticalSpace,
            Text(
              'Your story is now live and will be visible for 24 hours.',
              textAlign: TextAlign.center,
              style: IsrStyles.secondaryText14.copyWith(
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
            24.responsiveVerticalSpace,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  padding: IsrDimens.edgeInsetsSymmetric(
                      vertical: 14.responsiveDimension),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.responsiveDimension),
                  ),
                ),
                child: Text(
                  'Done',
                  style: IsrStyles.white14.copyWith(
                    color: theme.onPrimary,
                    fontWeight: FontWeight.w700,
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
