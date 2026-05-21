import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Full-screen picker to add stories to an existing highlight.
class PickExistingHighlightScreen extends StatefulWidget {
  const PickExistingHighlightScreen({
    super.key,
    required this.highlights,
  });

  final List<StoryHighlightData> highlights;

  static Future<StoryHighlightData?> push(
    BuildContext context, {
    required List<StoryHighlightData> highlights,
  }) =>
      Navigator.of(context).push<StoryHighlightData>(
        MaterialPageRoute<StoryHighlightData>(
          builder: (_) => PickExistingHighlightScreen(highlights: highlights),
          fullscreenDialog: true,
        ),
      );

  @override
  State<PickExistingHighlightScreen> createState() =>
      _PickExistingHighlightScreenState();
}

class _PickExistingHighlightScreenState extends State<PickExistingHighlightScreen> {
  String? _selectedId;

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
          IsrTranslationFile.addToHighlights,
          style: IsrStyles.primaryText16.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: widget.highlights.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        IsrTranslationFile.noHighlightsCreateFirst,
                        textAlign: TextAlign.center,
                        style: IsrStyles.secondaryText14.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: widget.highlights.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final h = widget.highlights[index];
                      final selected = _selectedId == h.id;
                      final title = h.title.trim().isEmpty
                          ? 'Untitled highlight'
                          : h.title.trim();
                      return Material(
                        color: theme.textSecondary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedId = h.id),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? theme.primary
                                    : Colors.transparent,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: selected
                                          ? theme.primary
                                          : theme.textSecondary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Select',
                                      style: IsrStyles.secondaryText12
                                          .copyWith(
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: h.coverUrl.trim().isNotEmpty
                                          ? SizedBox(
                                              width: 44,
                                              height: 44,
                                              child: AppImage.network(
                                                h.coverUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: 44,
                                              height: 44,
                                              color: theme.textSecondary
                                                  .withValues(alpha: 0.12),
                                              child: Icon(
                                                Icons
                                                    .collections_bookmark_outlined,
                                                color: theme.textSecondary,
                                                size: 22,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: IsrStyles.primaryText14
                                            .copyWith(
                                          color: theme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: FilledButton(
              onPressed: _selectedId == null
                  ? null
                  : () {
                      for (final h in widget.highlights) {
                        if (h.id == _selectedId) {
                          Navigator.of(context).pop(h);
                          return;
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add to highlight'),
            ),
          ),
        ],
      ),
    );
  }
}
