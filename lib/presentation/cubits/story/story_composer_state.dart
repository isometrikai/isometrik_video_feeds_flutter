import 'dart:io';

class StoryComposerState {
  const StoryComposerState({
    this.file,
    this.mediaType = 'image',
    this.videoDurationSeconds,
    this.caption = '',
    this.isSubmitting = false,
  });

  final File? file;
  final String mediaType;
  final int? videoDurationSeconds;
  final String caption;
  final bool isSubmitting;

  bool get hasSelectedMedia => file != null;

  String get selectedFileName {
    final value = file?.path ?? '';
    if (value.isEmpty) return '';
    return value.split('/').last;
  }

  StoryComposerState copyWith({
    File? file,
    bool clearFile = false,
    String? mediaType,
    int? videoDurationSeconds,
    bool clearVideoDuration = false,
    String? caption,
    bool? isSubmitting,
  }) =>
      StoryComposerState(
        file: clearFile ? null : (file ?? this.file),
        mediaType: mediaType ?? this.mediaType,
        videoDurationSeconds: clearVideoDuration
            ? null
            : (videoDurationSeconds ?? this.videoDurationSeconds),
        caption: caption ?? this.caption,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

