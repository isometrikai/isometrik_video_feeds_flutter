import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class InjectionUtils {
  static bool _isRegistered<T extends Object>() => kGetIt.isRegistered<T>();

  static T getBloc<T extends BlocBase<Object>>() => kGetIt<T>();
  static T getCubit<T extends BlocBase<Object>>() => kGetIt<T>();

  static T getUseCase<T extends BaseUseCase>() =>
      kGetIt<T>(); // Generic method to get use cases

  // Generic function to register a Bloc
  static void registerBloc<T extends BlocBase<Object>>(
      T Function() factoryFunc) {
    kGetIt.registerLazySingleton<T>(factoryFunc);
  }

  // Generic function to register a UseCase
  static void registerUseCase<T extends BaseUseCase>(T Function() factoryFunc) {
    if (_isRegistered<T>()) return;
    kGetIt.registerLazySingleton<T>(factoryFunc);
  }

  // Generic function to register a repository
  static void registerRepo<T extends BaseRepository>(T Function() factoryFunc) {
    if (_isRegistered<T>()) return;
    kGetIt.registerLazySingleton<T>(factoryFunc);
  }

  static T getRepo<T extends BaseRepository>() =>
      kGetIt<T>(); // Generic method to get repository

  // Generic function to register a api service
  static void registerApiService<T extends BaseService>(
      T Function() factoryFunc) {
    if (_isRegistered<T>()) return;
    kGetIt.registerLazySingleton<T>(factoryFunc);
  }

  static T getApiService<T extends BaseService>() =>
      kGetIt<T>(); // Generic method to get api service

  static RouteManagement getRouteManagement() => kGetIt<RouteManagement>();

  // Generic function to register a class
  static void registerOtherClass<T extends Object>(T Function() factoryFunc) {
    if (_isRegistered<T>()) return;
    kGetIt.registerLazySingleton<T>(factoryFunc);
  }

  static T getOtherClass<T extends Object>() =>
      kGetIt<T>(); // Generic method to get api service
}
