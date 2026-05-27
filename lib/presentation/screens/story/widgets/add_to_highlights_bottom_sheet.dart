import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Bottom sheet: highlight list with thumbnails, radio selection, + to create.
class AddToHighlightsBottomSheet extends StatefulWidget {
  const AddToHighlightsBottomSheet({
    super.key,
    required this.highlights,
    required this.onCreateNewHighlight,
    required this.onHighlightSelected,
  });

  final List<StoryHighlightData> highlights;
  final VoidCallback onCreateNewHighlight;
  final ValueChanged<StoryHighlightData> onHighlightSelected;

  static Future<void> show({
    required BuildContext context,
    required List<StoryHighlightData> highlights,
    required VoidCallback onCreateNewHighlight,
    required ValueChanged<StoryHighlightData> onHighlightSelected,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AddToHighlightsBottomSheet(
          highlights: highlights,
          onCreateNewHighlight: () {
            Navigator.of(ctx).pop();
            onCreateNewHighlight();
          },
          onHighlightSelected: (h) {
            Navigator.of(ctx).pop();
            onHighlightSelected(h);
          },
        ),
      );

  @override
  State<AddToHighlightsBottomSheet> createState() =>
      _AddToHighlightsBottomSheetState();
}

class _AddToHighlightsBottomSheetState extends State<AddToHighlightsBottomSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      IsrTranslationFile.addToHighlights,
                      style: IsrStyles.primaryText16.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: theme.primary, size: 28),
                    onPressed: widget.onCreateNewHighlight,
                  ),
                ],
              ),
            ),
            Flexible(
              child: widget.highlights.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        IsrTranslationFile.noHighlightsCreateFirst,
                        textAlign: TextAlign.center,
                        style: IsrStyles.secondaryText14.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: widget.highlights.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final h = widget.highlights[index];
                        final selected = _selectedId == h.id;
                        final title = h.title.trim().isEmpty
                            ? 'Untitled highlight'
                            : h.title.trim();
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() => _selectedId = h.id);
                              widget.onHighlightSelected(h);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  _HighlightThumbnail(
                                    coverUrl: h.coverUrl,
                                    theme: theme,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: IsrStyles.primaryText14.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _RadioIndicator(
                                    selected: selected,
                                    theme: theme,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightThumbnail extends StatelessWidget {
  const _HighlightThumbnail({
    required this.coverUrl,
    required this.theme,
  });

  final String coverUrl;
  final StoryThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    if (coverUrl.trim().isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: AppImage.network(
          coverUrl,
          fit: BoxFit.cover,
          placeHolderWidget: (_, __) => placeholder,
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({
    required this.selected,
    required this.theme,
  });

  final bool selected;
  final StoryThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    const outer = 24.0;
    if (selected) {
      return Container(
        width: outer,
        height: outer,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.textPrimary,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
    );
  }
}
