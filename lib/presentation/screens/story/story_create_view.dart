import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// SDK full-screen story composer (photo/video + caption), similar flow to create post media pick + upload.
class StoryCreateView extends StatefulWidget {
  const StoryCreateView({super.key});

  @override
  State<StoryCreateView> createState() => _StoryCreateViewState();
}

class _StoryCreateViewState extends State<StoryCreateView> {
  late final StoryComposerCubit _composerCubit = StoryComposerCubit();

  @override
  void dispose() {
    _composerCubit.close();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final composerState = _composerCubit.state;
    if (!composerState.hasSelectedMedia || composerState.isSubmitting) return;
    _composerCubit.setSubmitting(true);
    try {
      await context.read<StoryCubit>().createStoryFromPayload(
            StoryUploadPayload(
              file: composerState.file,
              mediaType: composerState.mediaType,
              mediaPosition: 1,
              caption: composerState.caption.trim(),
              videoDurationSeconds: composerState.videoDurationSeconds,
            ),
          );
    } finally {
      if (mounted) _composerCubit.setSubmitting(false);
    }
  }

  Widget _pickerButton({
    required BuildContext context,
    required StoryComposerState composerState,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      OutlinedButton.icon(
      onPressed: composerState.isSubmitting ? null : onTap,
      icon: Icon(icon),
      label: Text(text, style: IsrStyles.primaryText14),
      style: OutlinedButton.styleFrom(
        padding: IsrDimens.edgeInsetsSymmetric(
          vertical: IsrDimens.twelve,
          horizontal: IsrDimens.twelve,
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.fourteen),
        ),
      ),
    );

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _composerCubit,
        child: BlocListener<StoryCubit, StoryState>(
          listenWhen: (prev, next) =>
              next is StoryActionSuccess || next is StoryError,
          listener: (context, state) {
            if (state is StoryActionSuccess && state.actionName == 'create_story') {
              Navigator.of(context).pop();
              return;
            }
            if (state is StoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<StoryComposerCubit, StoryComposerState>(
            builder: (context, composerState) => Scaffold(
              appBar: AppBar(
                title: const Text('New story'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: IsrDimens.edgeInsets(
                    left: IsrDimens.sixteen,
                    top: IsrDimens.ten,
                    right: IsrDimens.sixteen,
                    bottom: IsrDimens.twelve,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            if (composerState.file != null)
                              Container(
                                padding: IsrDimens.edgeInsetsSymmetric(
                                  horizontal: IsrDimens.twelve,
                                  vertical: IsrDimens.ten,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(
                                    IsrDimens.twelve,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      composerState.mediaType == 'video'
                                          ? Icons.videocam_rounded
                                          : Icons.image_rounded,
                                      size: 18,
                                    ),
                                    SizedBox(width: IsrDimens.eight),
                                    Expanded(
                                      child: Text(
                                        composerState.selectedFileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: IsrStyles.secondaryText12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (composerState.file != null)
                              SizedBox(height: IsrDimens.twelve),
                            TextField(
                              maxLines: 2,
                              minLines: 1,
                              enabled: !composerState.isSubmitting,
                              textInputAction: TextInputAction.done,
                              onChanged:
                                  context.read<StoryComposerCubit>().updateCaption,
                              decoration: InputDecoration(
                                hintText: 'Write to add to story',
                                prefixIcon:
                                    const Icon(Icons.mode_edit_outline_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    IsrDimens.fourteen,
                                  ),
                                ),
                                contentPadding: IsrDimens.edgeInsetsSymmetric(
                                  horizontal: IsrDimens.fourteen,
                                  vertical: IsrDimens.fourteen,
                                ),
                              ),
                            ),
                            SizedBox(height: IsrDimens.twelve),
                            Row(
                              children: [
                                Expanded(
                                  child: _pickerButton(
                                    context: context,
                                    composerState: composerState,
                                    text: 'Pick photo',
                                    icon: Icons.photo_library_outlined,
                                    onTap: context.read<StoryComposerCubit>().pickPhoto,
                                  ),
                                ),
                                SizedBox(width: IsrDimens.ten),
                                Expanded(
                                  child: _pickerButton(
                                    context: context,
                                    composerState: composerState,
                                    text: 'Pick video',
                                    icon: Icons.video_library_outlined,
                                    onTap: context.read<StoryComposerCubit>().pickVideo,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: IsrDimens.ten),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: !composerState.hasSelectedMedia ||
                                  composerState.isSubmitting
                              ? null
                              : () => _submit(context),
                          style: FilledButton.styleFrom(
                            padding: IsrDimens.edgeInsetsSymmetric(
                              vertical: IsrDimens.fourteen,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                IsrDimens.fourteen,
                              ),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: composerState.isSubmitting
                                ? const SizedBox(
                                    key: ValueKey('story_create_loading'),
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    key: const ValueKey('story_create_label'),
                                    'Share story',
                                    style: IsrStyles.white14,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
