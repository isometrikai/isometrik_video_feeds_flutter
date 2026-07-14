import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Full-screen "New Highlight" composer.
class CreateHighlightScreen extends StatefulWidget {
  const CreateHighlightScreen({
    super.key,
    required this.storyIds,
    required this.initialCoverUrl,
  });

  final List<String> storyIds;
  final String initialCoverUrl;

  static Future<bool?> push(
    BuildContext context, {
    required List<String> storyIds,
    required String initialCoverUrl,
  }) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (ctx) => CreateHighlightScreen(
            storyIds: storyIds,
            initialCoverUrl: initialCoverUrl,
          ),
          fullscreenDialog: true,
        ),
      );

  @override
  State<CreateHighlightScreen> createState() => _CreateHighlightScreenState();
}

class _CreateHighlightScreenState extends State<CreateHighlightScreen> {
  late final TextEditingController _nameController;
  String _coverUrl = '';
  File? _localCoverFile;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _coverUrl = widget.initialCoverUrl.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (_isSaving || widget.storyIds.isEmpty) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final cover =
          _coverUrl.isNotEmpty ? _coverUrl : widget.initialCoverUrl.trim();
      final ok = await context.read<StoryCubit>().createHighlightWithStories(
            title: name,
            coverUrl: cover.isNotEmpty ? cover : null,
            sortOrder: 0,
            storyIds: widget.storyIds,
          );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create highlight')),
        );
        return;
      }
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
          IsrTranslationFile.createNewHighlight,
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
                'Edit Cover',
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
                hintText: 'Highlight Name',
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Give your collection a memorable name.',
                style: IsrStyles.secondaryText12.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
