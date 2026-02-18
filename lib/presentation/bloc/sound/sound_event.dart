part of 'sound_bloc.dart';

abstract class SoundEvent {}

class GetSoundListEvent extends SoundEvent {
  GetSoundListEvent({
    required this.soundListTypes,
    required this.page,
    required this.pageSize,
    this.search,
    this.onComplete,
  });

  final SoundListTypes soundListTypes;
  final int page;
  final int pageSize;
  final String? search;
  final VoidCallback? onComplete;
}

class SoundPlayerPlayEvent extends SoundEvent {
  SoundPlayerPlayEvent(this.soundUrl);
  final String soundUrl;
}

class SoundPlayerStopEvent extends SoundEvent {
  SoundPlayerStopEvent(this.soundUrl);
  final String soundUrl;
}