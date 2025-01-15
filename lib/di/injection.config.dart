// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:ism_video_reel_player/bloc/landing/ism_landing_bloc.dart'
    as _i934;
import 'package:ism_video_reel_player/bloc/posts/post_bloc.dart' as _i187;
import 'package:ism_video_reel_player/data/data_source_impl.dart' as _i593;
import 'package:ism_video_reel_player/data/managers/local_storage_manager.dart'
    as _i996;
import 'package:ism_video_reel_player/data/managers/shared_preferences_manager.dart'
    as _i477;
import 'package:ism_video_reel_player/domain/post_repository.dart' as _i432;
import 'package:ism_video_reel_player/ism_video_reel_config.dart' as _i922;
import 'package:ism_video_reel_player/viewmodels/post_view_model.dart' as _i102;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i102.PostViewModel>(() => _i102.PostViewModel());
    gh.lazySingleton<_i922.IsmVideoReelConfig>(
        () => _i922.IsmVideoReelConfig());
    gh.lazySingleton<_i477.SharedPreferencesManager>(
        () => _i477.SharedPreferencesManager());
    gh.lazySingleton<_i996.LocalStorageManager>(
        () => _i996.LocalStorageManager());
    gh.lazySingleton<_i593.DataSourceImpl>(() => _i593.DataSourceImpl());
    gh.lazySingleton<_i432.PostRepository>(() => _i432.PostRepository());
    gh.lazySingleton<_i934.IsmLandingBloc>(() => _i934.IsmLandingBloc());
    gh.lazySingleton<_i187.PostBloc>(() => _i187.PostBloc());
    return this;
  }
}
