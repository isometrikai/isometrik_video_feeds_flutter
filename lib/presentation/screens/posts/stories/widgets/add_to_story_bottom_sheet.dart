import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

/// Entry point for story media: in-app camera or gallery picker.
enum StoryMediaPick {
  camera,
  gallery;

  static const Duration storyVideoMaxDuration = Duration(seconds: 60);

  bool get isCamera => this == camera;
}

class AddToStoryBottomSheet extends StatelessWidget {
  const AddToStoryBottomSheet({super.key});

  static Future<StoryMediaPick?> show(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    return showModalBottomSheet<StoryMediaPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackground,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20.responsiveDimension)),
      ),
      builder: (_) => const AddToStoryBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);

    return SafeArea(
      child: Padding(
        padding: IsrDimens.edgeInsets(
          top: 20.responsiveDimension,
          left: 20.responsiveDimension,
          right: 20.responsiveDimension,
          bottom: 24.responsiveDimension,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.responsiveDimension,
                height: 4.responsiveDimension,
                decoration: BoxDecoration(
                  color: theme.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            16.responsiveVerticalSpace,
            Row(
              children: [
                Expanded(
                  child: Text(
                    IsrTranslationFile.newStory,
                    style: IsrStyles.primaryText18.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            8.responsiveVerticalSpace,
            Text(
              IsrTranslationFile.choosePhotoOrVideo,
              style: IsrStyles.primaryText14.copyWith(
                color: theme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            24.responsiveVerticalSpace,
            Row(
              children: [
                Expanded(
                  child: _MediaOptionTile(
                    theme: theme,
                    icon: Icons.photo_camera_outlined,
                    label: IsrTranslationFile.camera,
                    onTap: () => Navigator.pop(context, StoryMediaPick.camera),
                  ),
                ),
                12.responsiveHorizontalSpace,
                Expanded(
                  child: _MediaOptionTile(
                    theme: theme,
                    icon: Icons.photo_library_outlined,
                    label: IsrTranslationFile.gallery,
                    onTap: () => Navigator.pop(context, StoryMediaPick.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaOptionTile extends StatelessWidget {
  const _MediaOptionTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final StoryThemeResolver theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: theme.scaffoldBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.responsiveDimension),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.responsiveDimension),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 28.responsiveDimension,
              horizontal: 12.responsiveDimension,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.responsiveDimension,
                  height: 56.responsiveDimension,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28.responsiveDimension,
                    color: theme.primary,
                  ),
                ),
                12.responsiveVerticalSpace,
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: IsrStyles.primaryText14.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
