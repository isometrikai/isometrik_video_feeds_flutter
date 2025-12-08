import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_models.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_image_editor_wrapper.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_video_editor_wrapper.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/video_cover_selector_view.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/widgets/media_edit_widgets.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:reorderables/reorderables.dart';

class MediaEditView extends StatefulWidget {
  const MediaEditView({
    super.key,
    required this.mediaDataList,
    required this.mediaEditConfig,
    this.onComplete,
    this.onSelectSound,
    this.addMoreMedia,
    this.pickCoverPic,
  });

  final List<MediaEditItem> mediaDataList;
  final MediaEditConfig mediaEditConfig;
  final Future<bool> Function(List<MediaEditItem> editededMedia)? onComplete;
  final Future<MediaEditSoundItem?> Function(MediaEditSoundItem? sound)?
      onSelectSound;
  final Future<List<MediaEditItem>?> Function(
      List<MediaEditItem> editededMedia)? addMoreMedia;
  final Future<String?> Function()? pickCoverPic;

  @override
  State<MediaEditView> createState() => _MediaEditViewState();
}

class _MediaEditViewState extends State<MediaEditView> {
  late final MediaEditBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.getOrCreateBloc();
    _bloc.add(MediaEditInitialEvent(mediaDataList: widget.mediaDataList));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _removeCurrentMedia(MediaEditLoadedState state) {
    _bloc.add(OnRemoveMediaEvent(index: state.currentIndex));
    widget.mediaEditConfig.showDialogFunction.call(
      context: context,
      title: widget.mediaEditConfig.removeMediaTitle,
      message: widget.mediaEditConfig.removeMediaMessage,
      positiveButtonText: widget.mediaEditConfig.removeButtonText,
      negativeButtonText: widget.mediaEditConfig.cancelButtonText,
      onPressPositiveButton: () => _bloc.add(ConfirmRemoveMediaEvent()),
      onPressNegativeButton: () {},
    );
  }

  Future<void> _addMoreMedia(MediaEditLoadedState state) async {
    final newMedia = await widget.addMoreMedia?.call(state.mediaEditItems);
    if (newMedia != null) {
      _bloc.add(AddMoreMediaEvent(newMedia: newMedia));
    }
  }

  Future<void> _navigateToTextEditor(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    // Push your editor widget directly
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditorWrapper(
          mediaPath: currentItem.editedPath ?? currentItem.originalPath,
          mediaEditConfig: widget.mediaEditConfig,
          title: 'Text Editor',
          filename: 'edited_image.jpg',
          editingMode: 'text',
          // Specify editing mode
          saveLocally: false,
        ),
      ),
    );

    _bloc.add(NavigateToTextEditorEvent(result: result));
  }

  Future<void> _navigateToFilterScreen(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    // Push your editor widget directly
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditorWrapper(
          mediaPath: currentItem.editedPath ?? currentItem.originalPath,
          mediaEditConfig: widget.mediaEditConfig,
          title: 'Filter Editor',
          filename: 'edited_image.jpg',
          editingMode: 'filter',
          // Specify editing mode
          saveLocally: false,
        ),
      ),
    );

    _bloc.add(NavigateToFilterScreenEvent(result: result));
  }

  Future<void> _navigateToImageAdjustment(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    // Push your editor widget directly
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditorWrapper(
          mediaPath: currentItem.editedPath ?? currentItem.originalPath,
          mediaEditConfig: widget.mediaEditConfig,
          title: 'Image Adjustment',
          filename: 'edited_image.jpg',
          editingMode: 'adjustment',
          // Specify editing mode
          saveLocally: false,
        ),
      ),
    );

    _bloc.add(NavigateToImageAdjustmentEvent(result: result));
  }

  Future<void> _navigateToAudioEditor(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];
    if (widget.onSelectSound != null) {
      final selectedSound = await widget.onSelectSound?.call(currentItem.sound);
      _bloc.add(NavigateToAudioEditorEvent(sound: selectedSound));
    }
  }

  Future<void> _navigateToVideoTrim(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    // Push your editor widget directly
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProVideoEditorWrapper(
          mediaPath: currentItem.editedPath ?? currentItem.originalPath,
          mediaEditConfig: widget.mediaEditConfig,
          title: 'Video Trim Editor',
          filename: 'trimmed_video.mp4',
          editingMode: 'Trim',
          // Specify editing mode
          saveLocally: false,
        ),
      ),
    );

    _bloc.add(NavigateToVideoTrimEvent(result: result));
  }

  Future<void> _navigateToVideoEdit(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    // Push your editor widget directly
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProVideoEditorWrapper(
          mediaPath: currentItem.editedPath ?? currentItem.originalPath,
          mediaEditConfig: widget.mediaEditConfig,
          title: 'Video Editor',
          filename: 'filtered_video.mp4',
          editingMode: 'edit',
          // Specify editing mode
          saveLocally: false,
        ),
      ),
    );

    _bloc.add(NavigateToVideoEditEvent(result: result));
  }

  Future<void> _navigateToVideoFilter(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    // Push your editor widget directly
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProVideoEditorWrapper(
          mediaPath: currentItem.editedPath ?? currentItem.originalPath,
          mediaEditConfig: widget.mediaEditConfig,
          title: 'Video Filter Editor',
          filename: 'filtered_video.mp4',
          editingMode: 'filter',
          // Specify editing mode
          saveLocally: false,
        ),
      ),
    );

    _bloc.add(NavigateToVideoFilterEvent(result: result));
  }

  Future<void> _navigateToCoverPhoto(MediaEditLoadedState state) async {
    final currentItem = state.mediaEditItems[state.currentIndex];

    if (currentItem.mediaType != EditMediaType.video) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Cover photo selection is only available for videos')),
      );
      return;
    }

    // Navigate to video cover selector
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCoverSelectorView(
          file: File(currentItem.editedPath ?? currentItem.originalPath),
          mediaEditConfig: widget.mediaEditConfig,
          pickCoverPic: widget.pickCoverPic,
        ),
      ),
    );

    if (result != null) {
      _bloc.add(NavigateToCoverPhotoEvent(coverFile: result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cover image updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _proceedToNext(MediaEditLoadedState state) async {
    _bloc.add(ProceedToNextEvent());
  }

  Future<void> _handleMediaEditComplete(
      List<MediaEditItem> mediaEditItems) async {
    try {
      final isPop = await widget.onComplete?.call(mediaEditItems) ?? true;
      // Return the edited media data
      if (isPop && mounted) Navigator.pop(context, mediaEditItems);
    } catch (e) {
      debugPrint('Error in _proceedToNext: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider<MediaEditBloc>.value(
        value: _bloc,
        child: BlocListener<MediaEditBloc, MediaEditState>(
          listener: (context, state) {
            if (state is MediaEditCompletedState) {
              _handleMediaEditComplete(state.mediaEditItems);
            } else if (state is MediaEditEmptyState) {
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: BlocBuilder<MediaEditBloc, MediaEditState>(
                buildWhen: (previous, current) =>
                    current is MediaEditInitialState ||
                    current is MediaEditLoadedState ||
                    current is MediaEditEmptyState,
                builder: (context, state) {
                  if (state is MediaEditInitialState) {
                    return Center(
                      child: CircularProgressIndicator(
                          color: widget.mediaEditConfig.primaryColor),
                    );
                  } else if (state is MediaEditEmptyState) {
                    return const Center(child: Text('No media selected'));
                  } else if (state is MediaEditLoadedState) {
                    return Column(
                      children: [
                        // Media Preview Section with integrated controls
                        Expanded(
                          child: _buildMediaPreviewWithControls(state),
                        ),

                        // Bottom section with media list and Next button
                        _buildBottomSection(state),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

  Widget _buildMediaPreviewWithControls(MediaEditLoadedState state) {
    if (state.mediaEditItems.isEmpty) {
      return const Center(child: Text('No media selected'));
    }

    final currentItem = state.mediaEditItems[state.currentIndex];
    final isVideo = currentItem.mediaType == EditMediaType.video;

    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16, // 9:16 aspect ratio
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Media Preview
                Center(
                  child: _buildMediaContent(currentItem, state),
                ),

                // Cross button (top-left)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _bodyAppBar(state),
                ),

                // Section buttons (bottom overlay)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildSectionButtons(currentItem, isVideo, state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bodyAppBar(MediaEditLoadedState state) => Padding(
        padding: EdgeInsets.all(7.responsiveDimension),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAppBarIcon(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [],
            ),
          ],
        ),
      );

  Widget _buildAppBarIcon({
    required IconData icon,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30.responsiveDimension,
          height: 30.responsiveDimension,
          margin: IsrDimens.edgeInsetsAll(7.responsiveDimension),
          decoration: BoxDecoration(
            color: widget.mediaEditConfig.blackColor.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      );

  Widget _buildMediaContent(
      MediaEditItem mediaItem, MediaEditLoadedState state) {
    if (mediaItem.mediaType == EditMediaType.video) {
      return _buildVideoContent(mediaItem, state);
    } else {
      return _buildImageContent(mediaItem);
    }
  }

  Widget _buildVideoContent(
          MediaEditItem mediaItem, MediaEditLoadedState state) =>
      VideoPreviewWidget(
        mediaEditItem: mediaItem,
        onRemoveMedia: () => _removeCurrentMedia(state),
        mediaEditConfig: widget.mediaEditConfig,
      );

  Widget _buildImageContent(MediaEditItem mediaItem) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                FileImage(File(mediaItem.editedPath ?? mediaItem.originalPath)),
            fit: BoxFit.cover, // Center crop
          ),
        ),
      );

  Widget _buildSectionButtons(
      MediaEditItem currentItem, bool isVideo, MediaEditLoadedState state) {
    List<Widget> buttons;

    if (isVideo) {
      // Video buttons: Audio, Filter, Trim, Cover Photo
      buttons = [
        if (widget.onSelectSound != null)
          _buildSectionButton(
            icon: Icons.audiotrack,
            label: 'Audio',
            onTap: () => _navigateToAudioEditor(state),
          ),
        _buildSectionButton(
          icon: Icons.content_cut,
          label: 'Trim',
          onTap: () => _navigateToVideoTrim(state),
        ),
        _buildSectionButton(
          icon: Icons.auto_awesome,
          label: 'Filter',
          onTap: () => _navigateToVideoFilter(state),
        ),
        _buildSectionButton(
          icon: Icons.tune,
          label: 'Edit',
          onTap: () => _navigateToVideoEdit(state),
        ),
        // _buildSectionButton(
        //   icon: Icons.image,
        //   label: 'Cover',
        //   onTap: () => _navigateToCoverPhoto(state),
        // ),
      ];
    } else {
      // Image buttons: Text, Filter, Edit
      buttons = [
        _buildSectionButton(
          icon: Icons.text_fields,
          label: 'Text',
          onTap: () => _navigateToTextEditor(state),
        ),
        _buildSectionButton(
          icon: Icons.auto_awesome,
          label: 'Filter',
          onTap: () => _navigateToFilterScreen(state),
        ),
        _buildSectionButton(
          icon: Icons.tune,
          label: 'Edit',
          onTap: () => _navigateToImageAdjustment(state),
        ),
      ];
    }

    return SizedBox(
      height: 70.responsiveDimension,
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: buttons.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 10 : 5,
              right: index == buttons.length - 1 ? 10 : 5,
            ),
            child: buttons[index],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58.responsiveDimension,
          width: 76.responsiveDimension,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: widget.mediaEditConfig.primaryText14.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  Widget _buildBottomSection(MediaEditLoadedState state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        height: 100.responsiveDimension,
        child: Row(
          children: [
            // Media list with thumbnails
            Expanded(
              child: _buildMediaList(state),
            ),

            const SizedBox(width: 16),

            // Next button
            GestureDetector(
              onTap: () => _proceedToNext(state),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.mediaEditConfig.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: widget.mediaEditConfig.primaryText14.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_sharp,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMediaList(MediaEditLoadedState state) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ReorderableWrap(
              direction: Axis.horizontal,
              // spacing: 12.responsiveDimension,
              runSpacing: 0,
              onReorder: (oldIndex, newIndex) {
                // Exclude the add button from reordering if it exists
                final maxMediaIndex = state.mediaEditItems.length;
                if (widget.addMoreMedia != null) {
                  if (oldIndex >= maxMediaIndex || newIndex >= maxMediaIndex) {
                    return;
                  }
                }
                _bloc.add(
                    ReorderMediaEvent(oldIndex: oldIndex, newIndex: newIndex));
              },
              onNoReorder: (int index) {
                // Triggered when user cancels reorder
              },
              children: state.mediaEditItems.asMap().entries.map((entry) {
                final index = entry.key;
                final mediaItem = entry.value;
                final isSelected = index == state.currentIndex;
                return Padding(
                  key: ValueKey('media_$index'),
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _bloc.add(OnSelectMediaEvent(index: index)),
                        child: Container(
                          width: 48.responsiveDimension,
                          height: 48.responsiveDimension,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? widget.mediaEditConfig.primaryColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    width: 48.responsiveDimension,
                                    height: 48.responsiveDimension,
                                    child: AppImage.file(
                                      mediaItem.thumbnailPath ??
                                          mediaItem.editedPath ??
                                          mediaItem.originalPath,
                                      fit: BoxFit.cover,
                                      width: 48.responsiveDimension,
                                      height: 48.responsiveDimension,
                                    ),
                                  ),
                                ),
                              ),
                              // Media type indicator
                              if (mediaItem.mediaType == EditMediaType.video)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            _bloc.add(OnRemoveMediaEvent(index: index));
                            widget.mediaEditConfig.showDialogFunction.call(
                              context: context,
                              title: widget.mediaEditConfig.removeMediaTitle,
                              message:
                                  widget.mediaEditConfig.removeMediaMessage,
                              positiveButtonText:
                                  widget.mediaEditConfig.removeButtonText,
                              negativeButtonText:
                                  widget.mediaEditConfig.cancelButtonText,
                              onPressPositiveButton: () =>
                                  _bloc.add(ConfirmRemoveMediaEvent()),
                              onPressNegativeButton: () {},
                            );
                          },
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Add more media button
            if (widget.addMoreMedia != null &&
                state.mediaEditItems.length < AppConstants.totalMediaLimit)
              GestureDetector(
                key: const ValueKey('add_more_media'),
                onTap: () => _addMoreMedia(state),
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: widget.mediaEditConfig.primaryColor),
                    color: widget.mediaEditConfig.primaryColor
                        .withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: widget.mediaEditConfig.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
