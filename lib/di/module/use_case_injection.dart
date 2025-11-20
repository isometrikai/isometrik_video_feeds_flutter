// lib/di/module/use_case_injection.dart

import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

/// A class responsible for injecting use case dependencies into the service locator.
class UseCaseInjection {
  /// Registers all use case implementations with the dependency injection container.
  static void inject() {
    // Register use cases with their respective repositories

    IsmInjectionUtils.registerUseCase<IsmLocalDataUseCase>(() =>
        IsmLocalDataUseCase(
            IsmInjectionUtils.getRepo<IsrLocalStorageRepository>()));

    /// Social Repository UseCase
    IsmInjectionUtils.registerUseCase<CreatePostUseCase>(
        () => CreatePostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetFollowingPostUseCase>(() =>
        GetFollowingPostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetTrendingPostUseCase>(() =>
        GetTrendingPostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetForYouPostUseCase>(() =>
        GetForYouPostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetMentionedUsersUseCase>(() =>
        GetMentionedUsersUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<RemoveMentionUseCase>(() =>
        RemoveMentionUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<FollowUnFollowUserUseCase>(() =>
        FollowUnFollowUserUseCase(
            IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<SavePostUseCase>(
        () => SavePostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<LikePostUseCase>(
        () => LikePostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<ReportPostUseCase>(
        () => ReportPostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetReportReasonsUseCase>(() =>
        GetReportReasonsUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetTimelinePostUseCase>(() =>
        GetTimelinePostUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));

    IsmInjectionUtils.registerUseCase<GetPostDetailsUseCase>(() =>
        GetPostDetailsUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GoogleCloudStorageUploaderUseCase>(() =>
        GoogleCloudStorageUploaderUseCase(
            IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<CommentActionUseCase>(() =>
        CommentActionUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetSocialProductsUseCase>(() =>
        GetSocialProductsUseCase(
            IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetPostCommentUseCase>(() =>
        GetPostCommentUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<MediaProcessingUseCase>(() =>
        MediaProcessingUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<SearchUserUseCase>(
        () => SearchUserUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<SearchTagUseCase>(
        () => SearchTagUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));
    IsmInjectionUtils.registerUseCase<GetTaggedPostsUseCase>(() =>
        GetTaggedPostsUseCase(IsmInjectionUtils.getRepo<SocialRepository>()));

    // Google Repository use cases
    IsmInjectionUtils.registerUseCase<GetAddressFromPinCodeUseCase>(() =>
        GetAddressFromPinCodeUseCase(
            IsmInjectionUtils.getRepo<GoogleRepository>()));
    IsmInjectionUtils.registerUseCase<GetNearByPlacesUseCase>(() =>
        GetNearByPlacesUseCase(IsmInjectionUtils.getRepo<GoogleRepository>()));
    IsmInjectionUtils.registerUseCase<GetAddressFromLatLongUseCase>(() =>
        GetAddressFromLatLongUseCase(
            IsmInjectionUtils.getRepo<GoogleRepository>()));
    IsmInjectionUtils.registerUseCase<GeocodeSearchAddressUseCase>(() =>
        GeocodeSearchAddressUseCase(
            IsmInjectionUtils.getRepo<GoogleRepository>()));
    IsmInjectionUtils.registerUseCase<GetPlaceDetailsUseCase>(() =>
        GetPlaceDetailsUseCase(IsmInjectionUtils.getRepo<GoogleRepository>()));
  }
}
