import 'package:flutter_bloc/flutter_bloc.dart';

class UploadProgressCubit extends Cubit<ProgressState> {
  UploadProgressCubit()
      : super(ProgressState(
            progress: 0, title: 'Loading', subtitle: '', isSuccess: false));

  void updateProgress(double value) {
    emit(state.copyWith(progress: value));
  }

  void updateTitle(String value) {
    emit(state.copyWith(title: value));
  }

  void updateSubtitle(String value) {
    emit(state.copyWith(subtitle: value));
  }

  void updateIsError(bool value) {
    emit(state.copyWith(isError: value));
  }

  void showSuccess() {
    emit(state.copyWith(isSuccess: true));
  }

  void reset() {
    emit(ProgressState(
        progress: 0, title: 'Loading', subtitle: '', isSuccess: false));
  }
}

class ProgressState {
  ProgressState({
    required this.progress,
    required this.title,
    required this.subtitle,
    required this.isSuccess,
    this.isError = false
  });

  final double progress;
  final String title;
  final String subtitle;
  final bool isSuccess;
  final bool isError;

  ProgressState copyWith({
    double? progress,
    String? title,
    String? subtitle,
    bool? isSuccess,
    bool? isError,
  }) =>
      ProgressState(
        progress: progress ?? this.progress,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        isSuccess: isSuccess ?? this.isSuccess,
        isError: isError ?? this.isError,
      );
}
