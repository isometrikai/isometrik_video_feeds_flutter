// lib/di/module/bloc_injection.dart

import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';

/// A class responsible for injecting Bloc dependencies into the service locator.
class BlocInjection {
  /// Registers all Bloc implementations with the dependency injection container.
  static void inject() {
    final localDataUseCase = InjectionUtils.getUseCase<LocalDataUseCase>();
    InjectionUtils.registerBloc<IsmLandingBloc>(
      IsmLandingBloc.new,
    );
    InjectionUtils.registerBloc<PostBloc>(
      () => PostBloc(
        localDataUseCase,
        InjectionUtils.getUseCase<GetFollowingPostUseCase>(),
        InjectionUtils.getUseCase<GetTrendingPostUseCase>(),
        InjectionUtils.getUseCase<CreatePostUseCase>(),
        InjectionUtils.getUseCase<FollowPostUseCase>(),
        InjectionUtils.getUseCase<SavePostUseCase>(),
        InjectionUtils.getUseCase<LikePostUseCase>(),
        InjectionUtils.getUseCase<ReportPostUseCase>(),
        InjectionUtils.getUseCase<GetReportReasonsUseCase>(),
      ),
    );
  }
}
