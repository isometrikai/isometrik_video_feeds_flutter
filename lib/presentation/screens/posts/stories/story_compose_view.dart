import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_image_cropper.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/story_theme_resolver.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/stories/widgets/story_posted_success_dialog.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:video_player/video_player.dart';

class StoryComposeView extends StatefulWidget {
  const StoryComposeView({
    super.key,
    required this.file,
    required this.mediaType,
  });

  final File file;
  final String mediaType;

  @override
  State<StoryComposeView> createState() => _StoryComposeViewState();
}

class _StoryComposeViewState extends State<StoryComposeView> {
  final _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  var _isSubmitting = false;
  late File _mediaFile = widget.file;

  bool get _isVideo => widget.mediaType == 'video';

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _videoController = VideoPlayerController.file(_mediaFile)
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  bool get _useBackgroundStoryUi =>
      IsrVideoReelConfig.storyConfig?.storyCallbackConfig
          .onBackgroundStoryOperation !=
      null;

  Future<void> _recropImage() async {
    if (_isVideo || _isSubmitting) return;
    final cropped = await StoryImageCropper.crop(_mediaFile.path);
    if (!mounted || cropped == null) return;
    setState(() => _mediaFile = cropped);
  }

  Future<void> _submit(BuildContext context) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final payload = StoryUploadPayload(
      file: _mediaFile,
      mediaType: widget.mediaType,
      mediaPosition: 1,
      caption: _captionController.text.trim(),
      videoDurationSeconds:
          _isVideo ? _videoController?.value.duration.inSeconds : null,
    );
    if (_useBackgroundStoryUi) {
      unawaited(context.read<StoryCubit>().createStoryFromPayload(payload));
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    await context.read<StoryCubit>().createStoryFromPayload(payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemeResolver.of(context);

    return BlocListener<StoryCubit, StoryState>(
      listenWhen: (prev, next) =>
          !_useBackgroundStoryUi &&
          (next is StoryActionSuccess || next is StoryError),
      listener: (context, state) {
        if (state is StoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          if (mounted) setState(() => _isSubmitting = false);
          return;
        }
        if (state is StoryActionSuccess && state.actionName == 'create_story') {
          Navigator.of(context).pop();
          StoryPostedSuccessDialog.show(context);
          if (mounted) setState(() => _isSubmitting = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                minimum: const EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      if (!_isVideo) ...[
                        const SizedBox(width: 8),
                        _CircleIconButton(
                          icon: Icons.crop_rounded,
                          onTap: _isSubmitting ? () {} : _recropImage,
                        ),
                      ],
                      const Spacer(),
                      FilledButton(
                        onPressed:
                            _isSubmitting ? null : () => _submit(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.onPrimary,
                                ),
                              )
                            : Text(
                                IsrTranslationFile.shareStory,
                                style: IsrStyles.white14.copyWith(
                                  color: theme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _captionController,
                    enabled: !_isSubmitting,
                    style: IsrStyles.white14,
                    decoration: InputDecoration(
                      hintText: IsrTranslationFile.writeToAddToStory,
                      hintStyle: IsrStyles.white14.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.35),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(color: theme.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (_isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    return Image.file(_mediaFile, fit: BoxFit.cover);
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.onTap,
    this.icon = Icons.arrow_back_ios_new_rounded,
  });

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
}
