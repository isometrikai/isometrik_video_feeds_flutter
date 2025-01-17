import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/export.dart';

class AppBlocObserver extends BlocObserver {
  final tag = 'AppBlocObserver';
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    AppLog.success('$tag: ${bloc.runtimeType} created');
    super.onCreate(bloc);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    AppLog.success('$tag: ${bloc.runtimeType} closed');
    super.onClose(bloc);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    AppLog.highlight('$tag: Event ${bloc.runtimeType} - ${event.runtimeType}');
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    AppLog('$tag: Change ${bloc.runtimeType} - ${change.currentState} -> ${change.nextState}');
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    AppLog.info(
        '$tag: Transition ${bloc.runtimeType} - ${transition.currentState.runtimeType} : ${transition.event.runtimeType} -> ${transition.nextState.runtimeType}');
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLog.error('$tag: ${bloc.runtimeType} - $error', stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
