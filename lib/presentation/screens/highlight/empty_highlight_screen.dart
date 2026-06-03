import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/res/res.dart';

class EmptyHighlightScreen extends StatefulWidget {
  const EmptyHighlightScreen({
    super.key,
    required this.highlightId,
    this.userId,
    this.initialHighlight,
  });

  final String highlightId;
  final String? userId;
  final StoryHighlightData? initialHighlight;

  static Future<bool?> push(
    BuildContext context, {
    required String highlightId,
    String? userId,
    StoryHighlightData? initialHighlight,
  }) =>
      Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => EmptyHighlightScreen(
            highlightId: highlightId,
            userId: userId,
            initialHighlight: initialHighlight,
          ),
        ),
      );

  @override
  State<EmptyHighlightScreen> createState() => _EmptyHighlightScreenState();
}

class _EmptyHighlightScreenState extends State<EmptyHighlightScreen> {
  StoryHighlightData? _highlight;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _highlight = widget.initialHighlight;
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<StoryCubit>();
    final fresh = await cubit.getStoryHighlightById(widget.highlightId);
    if (!mounted) return;
    setState(() {
      _highlight = fresh ?? _highlight;
      _loading = false;
    });
  }

  String get _title {
    final t = _highlight?.title.trim() ?? '';
    return t.isNotEmpty ? t : 'Highlight';
  }

  String get _coverUrl => _highlight?.coverUrl.trim() ?? '';

  Future<void> _onAddStories() async {
    final highlight = _highlight;
    if (highlight == null || highlight.id.isEmpty) return;
    final cubit = context.read<StoryCubit>();
    final added = await HighlightComposerCoordinator.addStoriesToHighlight(
      context: context,
      cubit: cubit,
      highlight: highlight,
      openViewerAfterAdd: true,
    );
    if (!mounted) return;
    if (added) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onDeleteHighlight() async {
    final id = widget.highlightId.trim();
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete highlight?'),
        content: const Text(
          'This highlight will be removed from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<StoryCubit>().deleteHighlight(id);
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _onEditHighlight() async {
    final highlight = _highlight;
    if (highlight == null || highlight.id.isEmpty) return;
    final cubit = context.read<StoryCubit>();
    final updated = await HighlightComposerCoordinator.editHighlight(
      context: context,
      cubit: cubit,
      highlight: highlight,
    );
    if (!mounted) return;
    if (updated) await _load();
  }

  Future<void> _onMorePressed() async {
    final theme = StoryThemeResolver.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: theme.textPrimary),
              title: Text(
                IsrTranslationFile.editHighlight,
                style: IsrStyles.primaryText14.copyWith(
                  color: theme.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.destructive),
              title: Text(
                'Delete highlight',
                style: IsrStyles.primaryText14.copyWith(
                  color: theme.destructive,
                ),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _onEditHighlight();
      return;
    }
    if (action == 'delete') await _onDeleteHighlight();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    final cover = _coverUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        title: Text(
          _title,
          style: IsrStyles.primaryText14.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'More',
            icon: Icon(Icons.more_horiz, color: theme.textPrimary),
            onPressed: _loading ? null : _onMorePressed,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cover.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppImage.network(
                          cover,
                          width: 120,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.scaffoldBackground),
                        ),
                        child: Icon(
                          Icons.collections_bookmark_outlined,
                          color: theme.textPrimary,
                          size: 40,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      IsrTranslationFile.highlightEmptyTitle,
                      textAlign: TextAlign.center,
                      style: IsrStyles.primaryText16.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      IsrTranslationFile.highlightEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: IsrStyles.white14.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _onAddStories,
                      icon: Icon(Icons.add, color: theme.onPrimary),
                      label: Text('Add stories',
                          style: IsrStyles.primaryText14
                              .copyWith(color: theme.onPrimary)),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _onEditHighlight,
                      icon: Icon(Icons.edit_outlined, color: theme.primary),
                      label: Text(
                        IsrTranslationFile.editHighlight,
                        style: IsrStyles.primaryText14.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(color: theme.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
