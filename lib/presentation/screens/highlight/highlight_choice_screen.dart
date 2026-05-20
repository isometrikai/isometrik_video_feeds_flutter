import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Create new highlight vs add to an existing one.
class HighlightChoiceScreen extends StatelessWidget {
  const HighlightChoiceScreen({super.key});

  static Future<String?> push(BuildContext context) => Navigator.of(context)
      .push<String>(
        MaterialPageRoute<String>(
          builder: (_) => const HighlightChoiceScreen(),
          fullscreenDialog: true,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Add to highlights',
          style: IsrStyles.primaryText16.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: theme.primary),
              title: Text(
                'Create new highlight',
                style: IsrStyles.primaryText14.copyWith(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
              onTap: () => Navigator.of(context).pop('create'),
            ),
            Divider(
              height: 1,
              color: theme.textSecondary.withValues(alpha: 0.2),
            ),
            ListTile(
              leading: Icon(
                Icons.collections_bookmark_outlined,
                color: theme.textPrimary,
              ),
              title: Text(
                'Add to existing highlight',
                style: IsrStyles.primaryText14.copyWith(
                  color: theme.textPrimary,
                  fontSize: 16,
                ),
              ),
              onTap: () => Navigator.of(context).pop('existing'),
            ),
          ],
        ),
      ),
    );
  }
}
