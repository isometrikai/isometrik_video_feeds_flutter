// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:ism_video_reel_player/isr_video_reel_config.dart' as _i227;
import 'package:ism_video_reel_player/presentation/bloc/landing/ism_landing_bloc.dart' as _i999;

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
    gh.lazySingleton<_i227.IsrVideoReelConfig>(() => _i227.IsrVideoReelConfig());
    gh.lazySingleton<_i999.IsmLandingBloc>(() => _i999.IsmLandingBloc());
    return this;
  }
}
