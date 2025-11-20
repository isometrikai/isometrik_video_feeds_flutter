// lib/di/module/bloc_injection.dart

import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';

/// A class responsible for injecting Bloc dependencies into the service locator.
class BlocInjection {
  /// Registers all Bloc implementations with the dependency injection container.
  static void inject() {
    final localDataUseCase =
        IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>();

    // Check if IsmLandingBloc is already registered
    IsmInjectionUtils.registerBloc<IsmLandingBloc>(
      IsmLandingBloc.new,
    );

    // Check if PostBloc is already registered
    IsmInjectionUtils.registerBloc<SocialPostBloc>(
      () => SocialPostBloc(
        localDataUseCase,
        IsmInjectionUtils.getUseCase<GetTimelinePostUseCase>(),
        IsmInjectionUtils.getUseCase<GetTrendingPostUseCase>(),
        IsmInjectionUtils.getUseCase<GetForYouPostUseCase>(),
        IsmInjectionUtils.getUseCase<FollowUnFollowUserUseCase>(),
        IsmInjectionUtils.getUseCase<SavePostUseCase>(),
        IsmInjectionUtils.getUseCase<LikePostUseCase>(),
        IsmInjectionUtils.getUseCase<ReportPostUseCase>(),
        IsmInjectionUtils.getUseCase<GetReportReasonsUseCase>(),
        IsmInjectionUtils.getUseCase<GetPostDetailsUseCase>(),
        IsmInjectionUtils.getUseCase<GetPostCommentUseCase>(),
        IsmInjectionUtils.getUseCase<CommentActionUseCase>(),
        IsmInjectionUtils.getUseCase<GetSocialProductsUseCase>(),
        IsmInjectionUtils.getUseCase<GetMentionedUsersUseCase>(),
        IsmInjectionUtils.getUseCase<RemoveMentionUseCase>(),
      ),
    );

    IsmInjectionUtils.registerBloc<PostListingBloc>(() => PostListingBloc(
          IsmInjectionUtils.getUseCase<GetTaggedPostsUseCase>(),
          IsmInjectionUtils.getUseCase<SearchTagUseCase>(),
          IsmInjectionUtils.getUseCase<GeocodeSearchAddressUseCase>(),
          IsmInjectionUtils.getUseCase<GetPlaceDetailsUseCase>(),
          IsmInjectionUtils.getUseCase<SearchUserUseCase>(),
          localDataUseCase,
          IsmInjectionUtils.getUseCase<FollowUnFollowUserUseCase>(),
        ));

    IsmInjectionUtils.registerBloc<TagDetailsBloc>(() => TagDetailsBloc(
          IsmInjectionUtils.getUseCase<GetTaggedPostsUseCase>(),
        ));

    IsmInjectionUtils.registerBloc<PlaceDetailsBloc>(() => PlaceDetailsBloc(
          IsmInjectionUtils.getUseCase<GetTaggedPostsUseCase>(),
        ));

    IsmInjectionUtils.registerBloc<CreatePostBloc>(() => CreatePostBloc(
          IsmInjectionUtils.getUseCase<CreatePostUseCase>(),
          IsmInjectionUtils.getUseCase<GetSocialProductsUseCase>(),
          localDataUseCase,
          IsmInjectionUtils.getUseCase<GoogleCloudStorageUploaderUseCase>(),
          IsmInjectionUtils.getUseCase<MediaProcessingUseCase>(),
        ));

    IsmInjectionUtils.registerBloc<SearchUserBloc>(() => SearchUserBloc(
          IsmInjectionUtils.getUseCase<SearchUserUseCase>(),
          IsmInjectionUtils.getUseCase<SearchTagUseCase>(),
        ));

    IsmInjectionUtils.registerBloc<SearchLocationBloc>(() => SearchLocationBloc(
          localDataUseCase,
          IsmInjectionUtils.getUseCase<GetPlaceDetailsUseCase>(),
          IsmInjectionUtils.getUseCase<GetNearByPlacesUseCase>(),
          IsmInjectionUtils.getOtherClass<LocationManager>(),
          IsmInjectionUtils.getUseCase<GeocodeSearchAddressUseCase>(),
        ));

    IsmInjectionUtils.registerBloc<UploadProgressCubit>(
      UploadProgressCubit.new,
    );

    IsmInjectionUtils.registerBloc<CommentActionCubit>(
      () => CommentActionCubit(
        localDataUseCase,
        IsmInjectionUtils.getUseCase<CommentActionUseCase>(),
      ),
    );
  }
}
