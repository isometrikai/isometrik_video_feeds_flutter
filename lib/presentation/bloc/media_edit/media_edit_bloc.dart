import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_models.dart';

part 'media_edit_event.dart';
part 'media_edit_state.dart';

class MediaEditBloc extends Bloc<MediaEditEvent, MediaEditState> {
  MediaEditBloc() : super(MediaEditInitialState()) {
    on<MediaEditInitialEvent>(_onInitial);
    on<UpdateMediaItemEvent>(_onUpdateMediaItem);
    on<OnRemoveMediaEvent>(_onRemoveMedia);
    on<ConfirmRemoveMediaEvent>(_onConfirmRemoveMedia);
    on<AddMoreMediaEvent>(_onAddMoreMedia);
    on<OnSelectMediaEvent>(_onSelectMedia);
    on<ReorderMediaEvent>(_onReorderMedia);
    on<NavigateToTextEditorEvent>(_onNavigateToTextEditor);
    on<NavigateToFilterScreenEvent>(_onNavigateToFilterScreen);
    on<NavigateToImageAdjustmentEvent>(_onNavigateToImageAdjustment);
    on<NavigateToAudioEditorEvent>(_onNavigateToAudioEditor);
    on<NavigateToVideoTrimEvent>(_onNavigateToVideoTrim);
    on<NavigateToVideoEditEvent>(_onNavigateToVideoEdit);
    on<NavigateToVideoFilterEvent>(_onNavigateToVideoFilter);
    on<NavigateToCoverPhotoEvent>(_onNavigateToCoverPhoto);
    on<ProceedToNextEvent>(_onProceedToNext);
  }

  final List<MediaEditItem> _mediaEditItems = [];
  int _currentIndex = 0;
  int? _pendingRemoveIndex;

  Future<void> _onInitial(
    MediaEditInitialEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    _mediaEditItems.clear();
    _mediaEditItems.addAll(event.mediaDataList);
    _currentIndex = 0;

    if (_mediaEditItems.isEmpty) {
      emit(MediaEditEmptyState());
    } else {
      emit(MediaEditLoadedState(
        mediaEditItems: List.from(_mediaEditItems),
        currentIndex: _currentIndex,
      ));
    }
  }

  Future<void> _onUpdateMediaItem(
    UpdateMediaItemEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (_currentIndex >= 0 && _currentIndex < _mediaEditItems.length) {
      _mediaEditItems[_currentIndex] = event.updatedItem;
      emit(MediaEditLoadedState(
        mediaEditItems: List.from(_mediaEditItems),
        currentIndex: _currentIndex,
      ));
    }
  }

  Future<void> _onRemoveMedia(
    OnRemoveMediaEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    _pendingRemoveIndex = event.index;
    // The dialog will be shown by the view, then ConfirmRemoveMediaEvent will be triggered
  }

  Future<void> _onConfirmRemoveMedia(
    ConfirmRemoveMediaEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (_pendingRemoveIndex == null) return;

    final index = _pendingRemoveIndex!;
    _pendingRemoveIndex = null;

    if (_mediaEditItems.length <= 1) {
      emit(MediaEditEmptyState());
      return;
    }

    _mediaEditItems.removeAt(index);
    if (_currentIndex >= _mediaEditItems.length) {
      _currentIndex = _mediaEditItems.length - 1;
    } else if (_currentIndex > index) {
      _currentIndex--;
    }

    if (_mediaEditItems.isEmpty) {
      emit(MediaEditEmptyState());
    } else {
      emit(MediaEditLoadedState(
        mediaEditItems: List.from(_mediaEditItems),
        currentIndex: _currentIndex,
      ));
    }
  }

  Future<void> _onAddMoreMedia(
    AddMoreMediaEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    _mediaEditItems.addAll(event.newMedia);
    emit(MediaEditLoadedState(
      mediaEditItems: List.from(_mediaEditItems),
      currentIndex: _currentIndex,
    ));
  }

  Future<void> _onSelectMedia(
    OnSelectMediaEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.index >= 0 && event.index < _mediaEditItems.length) {
      _currentIndex = event.index;
      emit(MediaEditLoadedState(
        mediaEditItems: List.from(_mediaEditItems),
        currentIndex: _currentIndex,
      ));
    }
  }

  Future<void> _onReorderMedia(
    ReorderMediaEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    final maxMediaIndex = _mediaEditItems.length;

    // Validate indices - exclude add button from reordering
    if (event.oldIndex < 0 ||
        event.oldIndex >= maxMediaIndex ||
        event.newIndex < 0 ||
        event.newIndex >= maxMediaIndex) {
      return;
    }

    final item = _mediaEditItems.removeAt(event.oldIndex);
    _mediaEditItems.insert(event.newIndex, item);

    // Update current index to follow the reordered item
    if (_currentIndex == event.oldIndex) {
      _currentIndex = event.newIndex;
    } else if (_currentIndex > event.oldIndex &&
        _currentIndex <= event.newIndex) {
      _currentIndex--;
    } else if (_currentIndex < event.oldIndex &&
        _currentIndex >= event.newIndex) {
      _currentIndex++;
    }

    emit(MediaEditLoadedState(
      mediaEditItems: List.from(_mediaEditItems),
      currentIndex: _currentIndex,
    ));
  }

  Future<void> _onNavigateToTextEditor(
    NavigateToTextEditorEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.result != null && event.result!['success'] == true) {
      final editedFile = event.result!['file'] as File?;
      if (editedFile != null && _currentIndex < _mediaEditItems.length) {
        final currentItem = _mediaEditItems[_currentIndex];
        final updatedItem = MediaEditItem(
          editedPath: editedFile.path,
          originalPath: currentItem.originalPath,
          mediaType: currentItem.mediaType,
          width: currentItem.width,
          height: currentItem.height,
          duration: currentItem.duration,
          thumbnailPath: editedFile.path,
          sound: currentItem.sound,
          metaData: currentItem.metaData,
        );
        _mediaEditItems[_currentIndex] = updatedItem;
        emit(MediaEditLoadedState(
          mediaEditItems: List.from(_mediaEditItems),
          currentIndex: _currentIndex,
        ));
      }
    }
  }

  Future<void> _onNavigateToFilterScreen(
    NavigateToFilterScreenEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.result != null && event.result!['success'] == true) {
      final editedFile = event.result!['file'] as File?;
      if (editedFile != null && _currentIndex < _mediaEditItems.length) {
        final currentItem = _mediaEditItems[_currentIndex];
        final updatedItem = MediaEditItem(
          editedPath: editedFile.path,
          originalPath: currentItem.originalPath,
          mediaType: currentItem.mediaType,
          width: currentItem.width,
          height: currentItem.height,
          duration: currentItem.duration,
          thumbnailPath: editedFile.path,
          sound: currentItem.sound,
          metaData: currentItem.metaData,
        );
        _mediaEditItems[_currentIndex] = updatedItem;
        emit(MediaEditLoadedState(
          mediaEditItems: List.from(_mediaEditItems),
          currentIndex: _currentIndex,
        ));
      }
    }
  }

  Future<void> _onNavigateToImageAdjustment(
    NavigateToImageAdjustmentEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.result != null && event.result!['success'] == true) {
      final editedFile = event.result!['file'] as File?;
      if (editedFile != null && _currentIndex < _mediaEditItems.length) {
        final currentItem = _mediaEditItems[_currentIndex];
        final updatedItem = MediaEditItem(
          editedPath: editedFile.path,
          originalPath: currentItem.originalPath,
          mediaType: currentItem.mediaType,
          width: currentItem.width,
          height: currentItem.height,
          duration: currentItem.duration,
          thumbnailPath: editedFile.path,
          sound: currentItem.sound,
          metaData: currentItem.metaData,
        );
        _mediaEditItems[_currentIndex] = updatedItem;
        emit(MediaEditLoadedState(
          mediaEditItems: List.from(_mediaEditItems),
          currentIndex: _currentIndex,
        ));
      }
    }
  }

  Future<void> _onNavigateToAudioEditor(
    NavigateToAudioEditorEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (_currentIndex < _mediaEditItems.length) {
      _mediaEditItems[_currentIndex].sound = event.sound;
      emit(MediaEditLoadedState(
        mediaEditItems: List.from(_mediaEditItems),
        currentIndex: _currentIndex,
      ));
    }
  }

  Future<void> _onNavigateToVideoTrim(
    NavigateToVideoTrimEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.result != null && event.result!['success'] == true) {
      final editedFile = event.result!['file'] as File?;
      if (editedFile != null && _currentIndex < _mediaEditItems.length) {
        final currentItem = _mediaEditItems[_currentIndex];
        final updatedItem = MediaEditItem(
          editedPath: editedFile.path,
          originalPath: currentItem.originalPath,
          mediaType: currentItem.mediaType,
          width: currentItem.width,
          height: currentItem.height,
          duration: currentItem.duration,
          thumbnailPath: currentItem.thumbnailPath,
          sound: currentItem.sound,
          metaData: currentItem.metaData,
        );
        _mediaEditItems[_currentIndex] = updatedItem;
        emit(MediaEditLoadedState(
          mediaEditItems: List.from(_mediaEditItems),
          currentIndex: _currentIndex,
        ));
      }
    }
  }

  Future<void> _onNavigateToVideoEdit(
    NavigateToVideoEditEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.result != null && event.result!['success'] == true) {
      final editedFile = event.result!['file'] as File?;
      if (editedFile != null && _currentIndex < _mediaEditItems.length) {
        final currentItem = _mediaEditItems[_currentIndex];
        final updatedItem = MediaEditItem(
          editedPath: editedFile.path,
          originalPath: currentItem.originalPath,
          mediaType: currentItem.mediaType,
          width: currentItem.width,
          height: currentItem.height,
          duration: currentItem.duration,
          thumbnailPath: currentItem.thumbnailPath,
          sound: currentItem.sound,
          metaData: currentItem.metaData,
        );
        _mediaEditItems[_currentIndex] = updatedItem;
        emit(MediaEditLoadedState(
          mediaEditItems: List.from(_mediaEditItems),
          currentIndex: _currentIndex,
        ));
      }
    }
  }

  Future<void> _onNavigateToVideoFilter(
    NavigateToVideoFilterEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.result != null && event.result!['success'] == true) {
      final editedFile = event.result!['file'] as File?;
      if (editedFile != null && _currentIndex < _mediaEditItems.length) {
        final currentItem = _mediaEditItems[_currentIndex];
        final updatedItem = MediaEditItem(
          editedPath: editedFile.path,
          originalPath: currentItem.originalPath,
          mediaType: currentItem.mediaType,
          width: currentItem.width,
          height: currentItem.height,
          duration: currentItem.duration,
          thumbnailPath: currentItem.thumbnailPath,
          sound: currentItem.sound,
          metaData: currentItem.metaData,
        );
        _mediaEditItems[_currentIndex] = updatedItem;
        emit(MediaEditLoadedState(
          mediaEditItems: List.from(_mediaEditItems),
          currentIndex: _currentIndex,
        ));
      }
    }
  }

  Future<void> _onNavigateToCoverPhoto(
    NavigateToCoverPhotoEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    if (event.coverFile != null && _currentIndex < _mediaEditItems.length) {
      final currentItem = _mediaEditItems[_currentIndex];
      final updatedItem = MediaEditItem(
        editedPath: currentItem.editedPath,
        originalPath: currentItem.originalPath,
        mediaType: currentItem.mediaType,
        width: currentItem.width,
        height: currentItem.height,
        duration: currentItem.duration,
        thumbnailPath: event.coverFile!.path,
        sound: currentItem.sound,
        metaData: currentItem.metaData,
      );
      _mediaEditItems[_currentIndex] = updatedItem;
      emit(MediaEditLoadedState(
        mediaEditItems: List.from(_mediaEditItems),
        currentIndex: _currentIndex,
      ));
    }
  }

  Future<void> _onProceedToNext(
    ProceedToNextEvent event,
    Emitter<MediaEditState> emit,
  ) async {
    emit(MediaEditCompletedState(mediaEditItems: List.from(_mediaEditItems)));
  }

  int? get pendingRemoveIndex => _pendingRemoveIndex;
}
