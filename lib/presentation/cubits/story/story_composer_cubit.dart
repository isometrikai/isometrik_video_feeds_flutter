import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/cubits/story/story_composer_state.dart';
import 'package:video_compress/video_compress.dart';

class StoryComposerCubit extends Cubit<StoryComposerState> {
  StoryComposerCubit({
    ImagePicker? picker,
  })  : _picker = picker ?? ImagePicker(),
        super(const StoryComposerState());

  final ImagePicker _picker;

  Future<void> pickPhoto() async {
    if (state.isSubmitting) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    emit(
      state.copyWith(
        file: File(picked.path),
        mediaType: 'image',
        clearVideoDuration: true,
      ),
    );
  }

  Future<void> pickVideo() async {
    if (state.isSubmitting) return;
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final mediaInfo = await VideoCompress.getMediaInfo(picked.path);
    emit(
      state.copyWith(
        file: File(picked.path),
        mediaType: 'video',
        videoDurationSeconds: ((mediaInfo.duration ?? 0) / 1000).round(),
      ),
    );
  }

  void updateCaption(String value) {
    emit(state.copyWith(caption: value));
  }

  void setSubmitting(bool value) {
    if (state.isSubmitting == value) return;
    emit(state.copyWith(isSubmitting: value));
  }
}

