// lib/di/module/use_case_injection.dart

import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

/// A class responsible for injecting use case dependencies into the service locator.
class UseCaseInjection {
  /// Registers all use case implementations with the dependency injection container.
  static void inject() {
    // Register use cases with their respective repositories

    InjectionUtils.registerUseCase<LocalDataUseCase>(
        () => LocalDataUseCase(InjectionUtils.getRepo<LocalStorageRepository>()));

    /// Auth UseCase
    InjectionUtils.registerUseCase<LoginUseCase>(
        () => LoginUseCase(InjectionUtils.getRepo<AuthRepository>()));
    InjectionUtils.registerUseCase<VerifyOtpUseCase>(
        () => VerifyOtpUseCase(InjectionUtils.getRepo<AuthRepository>()));
    InjectionUtils.registerUseCase<SendOtpUseCase>(
        () => SendOtpUseCase(InjectionUtils.getRepo<AuthRepository>()));
    InjectionUtils.registerUseCase<GuestLoginUseCase>(
        () => GuestLoginUseCase(InjectionUtils.getRepo<AuthRepository>()));

    /// Post UseCase
    InjectionUtils.registerUseCase<CreatePostUseCase>(
        () => CreatePostUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<GetFollowingPostUseCase>(
        () => GetFollowingPostUseCase(InjectionUtils.getRepo<PostRepository>()));
    InjectionUtils.registerUseCase<GetTrendingPostUseCase>(
        () => GetTrendingPostUseCase(InjectionUtils.getRepo<PostRepository>()));
    InjectionUtils.registerUseCase<FollowPostUseCase>(
        () => FollowPostUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<SavePostUseCase>(
        () => SavePostUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<LikePostUseCase>(
        () => LikePostUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<ReportPostUseCase>(
        () => ReportPostUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<GetReportReasonsUseCase>(
        () => GetReportReasonsUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<GetCloudDetailsUseCase>(
        () => GetCloudDetailsUseCase(InjectionUtils.getRepo<PostRepository>()));
    InjectionUtils.registerUseCase<GetTimelinePostUseCase>(
        () => GetTimelinePostUseCase(InjectionUtils.getRepo<SocialRepository>()));

    InjectionUtils.registerUseCase<GetPostDetailsUseCase>(
        () => GetPostDetailsUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<GoogleCloudStorageUploaderUseCase>(
        () => GoogleCloudStorageUploaderUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<CommentActionUseCase>(
        () => CommentActionUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<GetPostCommentUseCase>(
        () => GetPostCommentUseCase(InjectionUtils.getRepo<SocialRepository>()));
    InjectionUtils.registerUseCase<MediaProcessingUseCase>(
        () => MediaProcessingUseCase(InjectionUtils.getRepo<SocialRepository>()));
  }
}
