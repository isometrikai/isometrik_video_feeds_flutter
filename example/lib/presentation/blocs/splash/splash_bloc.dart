import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._localDataUseCase) : super(SplashInitial()) {
    on<InitializeSplash>(_onInitializeSplash);
  }

  final LocalDataUseCase _localDataUseCase;

  Future<void> _onInitializeSplash(
    InitializeSplash event,
    Emitter<SplashState> emit,
  ) async {
    final isLoggedIn = await _localDataUseCase.isLoggedIn();
    try {
      await Future.delayed(
        const Duration(milliseconds: 1500),
        () {
          emit(SplashCompleted(isLoggedIn: isLoggedIn));
        },
      );
    } catch (error) {
      emit(SplashError(error.toString()));
    }
  }
}
