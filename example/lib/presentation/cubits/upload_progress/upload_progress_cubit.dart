import 'package:flutter_bloc/flutter_bloc.dart';

class UploadProgressCubit extends Cubit<ProgressState> {
  UploadProgressCubit() : super(ProgressState(progress: 0, title: 'Loading', subtitle: ''));

  void updateProgress(double value) {
    emit(state.copyWith(progress: value));
  }

  void updateTitle(String value) {
    emit(state.copyWith(title: value));
  }

  void updateSubtitle(String value) {
    emit(state.copyWith(subtitle: value));
  }

  void reset() {
    emit(ProgressState(progress: 0, title: 'Loading', subtitle: ''));
  }
}

class ProgressState {
  ProgressState({
    required this.progress,
    required this.title,
    required this.subtitle,
  });

  final double progress;
  final String title;
  final String subtitle;

  ProgressState copyWith({
    double? progress,
    String? title,
    String? subtitle,
  }) =>
      ProgressState(
        progress: progress ?? this.progress,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
      );
}
