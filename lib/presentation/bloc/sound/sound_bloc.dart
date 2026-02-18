import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'sound_event.dart';

part 'sound_state.dart';

class SoundBloc extends Bloc<SoundEvent, SoundState> {
  SoundBloc(
    this._getSoundUseCase,
  ) : super(SoundInitialState()) {
    on<GetSoundListEvent>(_getSoundList);
    on<SoundPlayerPlayEvent>(_soundPlayerPlay);
    on<SoundPlayerStopEvent>(_soundPlayerStop);
  }

  final SoundUseCase _getSoundUseCase;

  // sound player
  final IsmAudioPlayer _audioPlayer = IsmAudioPlayer();
  IsmAudioPlayer get player => _audioPlayer;


  FutureOr<void> _getSoundList(
      GetSoundListEvent event, Emitter<SoundState> emit) async {
    emit(SoundListLoadingState(
        soundListTypes: event.soundListTypes, search: event.search));
    final res = await _getSoundUseCase.executeGetSoundList(
      isLoading: false,
      page: event.page,
      pageSize: event.pageSize,
      soundListTypes: event.soundListTypes,
      search: event.search,
    );

    if (res.isSuccess) {
      emit(SoundListLoadedState(
        sounds: res.data?.data ?? [],
        page: event.page,
        soundListTypes: event.soundListTypes,
        search: event.search,
      ));
    } else {
      emit(SoundListErrorState(
        error: res.error?.message ?? 'Something went wrong',
        soundListTypes: event.soundListTypes,
        search: event.search,
      ));
    }
    event.onComplete?.call();
  }

  Stream<IsmAudioPlayerListener> get audioStream =>
      _audioPlayer.listenerStream;

  FutureOr<void> _soundPlayerPlay(
      SoundPlayerPlayEvent event, Emitter<SoundState> emit) async {
    if (_audioPlayer.url != null && _audioPlayer.url != event.soundUrl) {
      await _audioPlayer.stop();
    }
    await _audioPlayer.setUrl(event.soundUrl);
    await _audioPlayer.play();
  }

  FutureOr<void> _soundPlayerStop(
      SoundPlayerStopEvent event, Emitter<SoundState> emit) async {
    await _audioPlayer.stop();
  }


  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
