part of 'sound_bloc.dart';

abstract class SoundState {}

class SoundInitialState extends SoundState {}

abstract class SoundListState extends SoundState {
  SoundListState({
    required this.soundListTypes,
    this.search,
  });

  final SoundListTypes soundListTypes;
  final String? search;
}

class SoundListLoadingState extends SoundListState {
  SoundListLoadingState({
    required super.soundListTypes,
    super.search,
  });
}

class SoundListLoadedState extends SoundListState {
  SoundListLoadedState({
    required this.sounds,
    required this.page,
    required super.soundListTypes,
    super.search,
  });

  final List<SoundData> sounds;
  final int page;
}

class SoundListErrorState extends SoundListState {
  SoundListErrorState({
    required this.error,
    required super.soundListTypes,
    super.search,
  });

  final String error;
}
