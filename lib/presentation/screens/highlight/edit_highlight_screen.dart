import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/highlight_story_item.dart';
import 'package:ism_video_reel_player/presentation/screens/highlight/pick_stories_for_highlight_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/res/res.dart';

class EditHighlightScreen extends StatefulWidget {
  const EditHighlightScreen({
    super.key,
    required this.highlightId,
    required this.initialTitle,
    required this.initialCoverUrl,
    required this.existingStoryIds,
    this.sortOrder = 0,
  });

  final String highlightId;
  final String initialTitle;
  final String initialCoverUrl;
  final List<String> existingStoryIds;
  final int sortOrder;

  @override
  State<EditHighlightScreen> createState() => _EditHighlightScreenState();
}

class _EditHighlightScreenState extends State<EditHighlightScreen> {
  late final TextEditingController _nameController;
  late final String _initialTitle;
  late final String _initialCoverUrl;

  String _coverUrl = '';
  File? _localCoverFile;
  final List<String> _pendingStoryIds = [];
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.initialTitle.trim();
    _initialCoverUrl = widget.initialCoverUrl.trim();
    _nameController = TextEditingController(text: _initialTitle);
    _coverUrl = _initialCoverUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _storyCount =>
      widget.existingStoryIds.length + _pendingStoryIds.length;

  List<Color> _gradientColors(StoryThemeResolver theme) => [
        theme.primary,
        theme.secondary,
        Color.lerp(theme.primary, theme.secondary, 0.35) ?? theme.primary,
      ];

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _localCoverFile = File(picked.path);
      _coverUrl = '';
    });

    try {
      final cubit = context.read<StoryCubit>();
      final uploaded = await cubit.uploadHighlightCoverFile(File(picked.path));
      if (!mounted) return;
      if (uploaded != null && uploaded.trim().isNotEmpty) {
        setState(() => _coverUrl = uploaded.trim());
      }
    } catch (_) {}
  }

  Future<void> _addStories() async {
    final cubit = context.read<StoryCubit>();
    final myStories = await cubit.getMyStories();
    if (!mounted) return;
    if (myStories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load stories')),
      );
      return;
    }

    final existing = <String>{
      ...widget.existingStoryIds
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
      ..._pendingStoryIds,
    };

    final available = myStories
        .where((s) => !existing.contains(s.id.trim()))
        .map(HighlightStoryItem.fromStory)
        .toList(growable: false);

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more past stories to add to this highlight'),
        ),
      );
      return;
    }

    final picked = await PickStoriesForHighlightScreen.push(
      context,
      stories: available,
    );
    if (!mounted || picked == null || picked.isEmpty) return;

    setState(() {
      for (final item in picked) {
        final id = item.id.trim();
        if (id.isEmpty || existing.contains(id)) continue;
        _pendingStoryIds.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final cover = _coverUrl.isNotEmpty ? _coverUrl : _initialCoverUrl;
    final titleChanged = name != _initialTitle;
    final coverChanged = cover != _initialCoverUrl;

    if (!titleChanged && !coverChanged && _pendingStoryIds.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cubit = context.read<StoryCubit>();
      final highlightId = widget.highlightId.trim();

      if (titleChanged || coverChanged) {
        final ok = await cubit.updateHighlightMetadata(
          highlightId: highlightId,
          title: name,
          coverUrl: cover.isNotEmpty ? cover : null,
          sortOrder: widget.sortOrder,
        );
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update highlight')),
          );
          return;
        }
      }

      if (_pendingStoryIds.isNotEmpty) {
        final ok = await cubit.addStoriesToHighlight(
          highlightId: highlightId,
          storyIds: List<String>.from(_pendingStoryIds),
        );
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Highlight saved, but some stories could not be added'),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);
    const coverSize = 140.0;

    Widget coverChild;
    if (_localCoverFile != null) {
      coverChild = Image.file(_localCoverFile!, fit: BoxFit.cover);
    } else if (_coverUrl.isNotEmpty) {
      coverChild = AppImage.network(_coverUrl, fit: BoxFit.cover);
    } else {
      coverChild = ColoredBox(
        color: theme.textSecondary.withValues(alpha: 0.12),
        child: Icon(Icons.image_outlined, size: 48, color: theme.textSecondary),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.textPrimary, size: 20),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        ),
        centerTitle: true,
        title: Text(
          IsrTranslationFile.editHighlight,
          style: IsrStyles.primaryText16.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  )
                : Text(
                    'Done',
                    style: IsrStyles.primaryText14.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Container(
              width: coverSize + 8,
              height: coverSize + 8,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _gradientColors(theme),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: SizedBox(
                    width: coverSize,
                    height: coverSize,
                    child: coverChild,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isSaving ? null : _pickCover,
              icon: Icon(Icons.edit_outlined, size: 18, color: theme.primary),
              label: Text(
                IsrTranslationFile.editHighlightCover,
                style: IsrStyles.primaryText14.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: IsrStyles.primaryText14.copyWith(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: IsrTranslationFile.highlightNameHint,
                hintStyle: IsrStyles.primaryText14.copyWith(
                  color: theme.textSecondary,
                ),
                filled: true,
                fillColor: theme.textSecondary.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: theme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                IsrTranslationFile.highlightStoriesSection,
                style: IsrStyles.secondaryText12.copyWith(
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: theme.textSecondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.collections_bookmark_outlined,
                      color: theme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_storyCount ${_storyCount == 1 ? 'story' : 'stories'}',
                            style: IsrStyles.primaryText14.copyWith(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_pendingStoryIds.isNotEmpty)
                            Text(
                              '${_pendingStoryIds.length} new to add when you save',
                              style: IsrStyles.secondaryText12.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _addStories,
                      child: Text(
                        IsrTranslationFile.addStoriesToHighlight,
                        style: IsrStyles.primaryText14.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
