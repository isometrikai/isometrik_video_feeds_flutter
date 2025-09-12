import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class IsmInjectionUtils {
  static bool _isRegistered<T extends Object>() => isrGetIt.isRegistered<T>();

  static T getBloc<T extends BlocBase<Object>>() => isrGetIt<T>();

  static T getCubit<T extends BlocBase<Object>>() => isrGetIt<T>();

  static T getUseCase<T extends BaseUseCase>() =>
      isrGetIt<T>(); // Generic method to get use cases

  // Generic function to register a Bloc
  static void registerBloc<T extends BlocBase<Object>>(
      T Function() factoryFunc) {
    unRegister<T>();
    isrGetIt.registerLazySingleton<T>(factoryFunc);
  }

  // Generic function to register a UseCase
  static void registerUseCase<T extends BaseUseCase>(T Function() factoryFunc) {
    unRegister<T>();
    isrGetIt.registerLazySingleton<T>(factoryFunc);
  }

  // Generic function to register a repository
  static void registerRepo<T extends BaseRepository>(T Function() factoryFunc) {
    unRegister<T>();
    isrGetIt.registerLazySingleton<T>(factoryFunc);
  }

  static void unRegister<T extends Object>() {
    if (_isRegistered<T>()) {
      isrGetIt.unregister<T>();
    }
  }

  static T getRepo<T extends BaseRepository>() =>
      isrGetIt<T>(); // Generic method to get repository

  // Generic function to register a api service
  static void registerApiService<T extends BaseService>(
      T Function() factoryFunc) {
    unRegister<T>();
    isrGetIt.registerLazySingleton<T>(factoryFunc);
  }

  static T getApiService<T extends BaseService>() =>
      isrGetIt<T>(); // Generic method to get api service

  static IsrRouteManagement getRouteManagement() =>
      isrGetIt<IsrRouteManagement>();

  // Generic function to register a class
  static void registerOtherClass<T extends Object>(T Function() factoryFunc) {
    unRegister<T>();
    isrGetIt.registerLazySingleton<T>(factoryFunc);
  }

  static T getOtherClass<T extends Object>() =>
      isrGetIt<T>(); // Generic method to get api service
}
