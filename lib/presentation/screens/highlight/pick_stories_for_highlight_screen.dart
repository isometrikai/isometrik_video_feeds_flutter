import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/highlight_story_item.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Full-screen story picker before creating or adding to a highlight.
class PickStoriesForHighlightScreen extends StatefulWidget {
  const PickStoriesForHighlightScreen({
    super.key,
    required this.stories,
  });

  final List<HighlightStoryItem> stories;

  static Future<List<HighlightStoryItem>?> push(
    BuildContext context, {
    required List<HighlightStoryItem> stories,
  }) =>
      Navigator.of(context).push<List<HighlightStoryItem>>(
        MaterialPageRoute<List<HighlightStoryItem>>(
          builder: (_) => PickStoriesForHighlightScreen(stories: stories),
          fullscreenDialog: true,
        ),
      );

  @override
  State<PickStoriesForHighlightScreen> createState() =>
      _PickStoriesForHighlightScreenState();
}

class _PickStoriesForHighlightScreenState
    extends State<PickStoriesForHighlightScreen> {
  final Set<String> _selectedIds = <String>{};

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  List<HighlightStoryItem> _orderedSelection() {
    final out = <HighlightStoryItem>[];
    for (final s in widget.stories) {
      if (_selectedIds.contains(s.id)) out.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    final selected = _orderedSelection();
    final count = selected.length;

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
        actions: [
          TextButton(
            onPressed: count == 0
                ? null
                : () => Navigator.of(context).pop(_orderedSelection()),
            child: Text(
              'Next',
              style: IsrStyles.primaryText14.copyWith(
                color: count == 0
                    ? theme.textSecondary.withValues(alpha: 0.5)
                    : theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'PAST STORIES',
                  style: IsrStyles.secondaryText12.copyWith(
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: widget.stories.length,
                  itemBuilder: (_, i) {
                    final s = widget.stories[i];
                    final isSelected = _selectedIds.contains(s.id);
                    return _StoryGridTile(
                      story: s,
                      selected: isSelected,
                      theme: theme,
                      onTap: () => _toggle(s.id),
                    );
                  },
                ),
              ),
            ],
          ),
          if (count > 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: _SelectionSummaryBar(
                selected: selected,
                count: count,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryGridTile extends StatelessWidget {
  const _StoryGridTile({
    required this.story,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final HighlightStoryItem story;
  final bool selected;
  final StoryThemeResolver theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              story.thumbUrl.isNotEmpty
                  ? AppImage.network(story.thumbUrl, fit: BoxFit.cover)
                  : ColoredBox(
                      color: theme.textSecondary.withValues(alpha: 0.12),
                    ),
              if (story.dateLabel.isNotEmpty)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Text(
                    story.dateLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(blurRadius: 4, color: Color(0x99000000)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? theme.primary : Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 14, color: theme.onPrimary)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSummaryBar extends StatelessWidget {
  const _SelectionSummaryBar({
    required this.selected,
    required this.count,
    required this.theme,
  });

  final List<HighlightStoryItem> selected;
  final int count;
  final StoryThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    final previews = selected.take(3).toList();

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(32),
      color: theme.scaffoldBackground.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: previews.length * 22.0 + 12,
              height: 32,
              child: Stack(
                children: [
                  for (var i = 0; i < previews.length; i++)
                    Positioned(
                      left: i * 22.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: previews[i].thumbUrl.isNotEmpty
                              ? AppImage.network(
                                  previews[i].thumbUrl,
                                  fit: BoxFit.cover,
                                )
                              : ColoredBox(
                                  color: theme.textSecondary
                                      .withValues(alpha: 0.12),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'story' : 'stories'} selected',
                style: IsrStyles.primaryText14.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
