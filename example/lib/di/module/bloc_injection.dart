// lib/di/module/bloc_injection.dart

import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';

/// A class responsible for injecting Bloc dependencies into the service locator.
class BlocInjection {
  /// Registers all Bloc implementations with the dependency injection container.
  static void inject() {
    final _localDataUseCase = InjectionUtils.getUseCase<LocalDataUseCase>();

    InjectionUtils.registerBloc<AuthBloc>(() => AuthBloc(
          InjectionUtils.getUseCase<LoginUseCase>(),
          InjectionUtils.getUseCase<VerifyOtpUseCase>(),
          InjectionUtils.getUseCase<GuestLoginUseCase>(),
          _localDataUseCase,
        ));

    InjectionUtils.registerBloc<SplashBloc>(() => SplashBloc(_localDataUseCase));
    InjectionUtils.registerBloc<LandingBloc>(() => LandingBloc(_localDataUseCase));
    InjectionUtils.registerBloc<ProfileBloc>(() => ProfileBloc(_localDataUseCase));
    InjectionUtils.registerBloc<NavItemCubit>(NavItemCubit.new);

    InjectionUtils.registerBloc<HomeBloc>(() => HomeBloc(
          _localDataUseCase,
          InjectionUtils.getUseCase<GetFollowingPostUseCase>(),
          InjectionUtils.getUseCase<GetTrendingPostUseCase>(),
          InjectionUtils.getUseCase<FollowPostUseCase>(),
          InjectionUtils.getUseCase<SavePostUseCase>(),
          InjectionUtils.getUseCase<LikePostUseCase>(),
          InjectionUtils.getUseCase<ReportPostUseCase>(),
          InjectionUtils.getUseCase<GetReportReasonsUseCase>(),
          InjectionUtils.getUseCase<GetTimelinePostUseCase>(),
        ));

    InjectionUtils.registerBloc<CreatePostBloc>(() => CreatePostBloc(
          InjectionUtils.getUseCase<CreatePostUseCase>(),
          InjectionUtils.getUseCase<GetCloudDetailsUseCase>(),
        ));
  }
}
