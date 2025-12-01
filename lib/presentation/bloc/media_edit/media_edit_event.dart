part of 'media_edit_bloc.dart';

abstract class MediaEditEvent {}

class MediaEditInitialEvent extends MediaEditEvent {
  MediaEditInitialEvent({required this.mediaDataList});

  final List<MediaEditItem> mediaDataList;
}

class UpdateMediaItemEvent extends MediaEditEvent {
  UpdateMediaItemEvent({
    required this.currentItem,
    required this.updatedItem,
  });

  final MediaEditItem currentItem;
  final MediaEditItem updatedItem;
}

class OnRemoveMediaEvent extends MediaEditEvent {
  OnRemoveMediaEvent({required this.index});

  final int index;
}

class ConfirmRemoveMediaEvent extends MediaEditEvent {}

class AddMoreMediaEvent extends MediaEditEvent {
  AddMoreMediaEvent({required this.newMedia});

  final List<MediaEditItem> newMedia;
}

class OnSelectMediaEvent extends MediaEditEvent {
  OnSelectMediaEvent({required this.index});

  final int index;
}

class ReorderMediaEvent extends MediaEditEvent {
  ReorderMediaEvent({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;
}

class NavigateToTextEditorEvent extends MediaEditEvent {
  NavigateToTextEditorEvent({required this.result});

  final Map<String, dynamic>? result;
}

class NavigateToFilterScreenEvent extends MediaEditEvent {
  NavigateToFilterScreenEvent({required this.result});

  final Map<String, dynamic>? result;
}

class NavigateToImageAdjustmentEvent extends MediaEditEvent {
  NavigateToImageAdjustmentEvent({required this.result});

  final Map<String, dynamic>? result;
}

class NavigateToAudioEditorEvent extends MediaEditEvent {
  NavigateToAudioEditorEvent({required this.sound});

  final MediaEditSoundItem? sound;
}

class NavigateToVideoTrimEvent extends MediaEditEvent {
  NavigateToVideoTrimEvent({required this.result});

  final Map<String, dynamic>? result;
}

class NavigateToVideoEditEvent extends MediaEditEvent {
  NavigateToVideoEditEvent({required this.result});

  final Map<String, dynamic>? result;
}

class NavigateToVideoFilterEvent extends MediaEditEvent {
  NavigateToVideoFilterEvent({required this.result});

  final Map<String, dynamic>? result;
}

class NavigateToCoverPhotoEvent extends MediaEditEvent {
  NavigateToCoverPhotoEvent({required this.coverFile});

  final File? coverFile;
}

class ProceedToNextEvent extends MediaEditEvent {}
