import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/models/models.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'isr_app_routes.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

/// Simple navigator helper for SDK internal navigation
class IsrAppNavigator {
  IsrAppNavigator._();

  /// Navigate to post listing screen
  /// ✅ Wraps the destination with necessary BLoC providers
  static void navigateToPostListing(
    BuildContext context, {
    required String tagValue,
    required TagType tagType,
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<PostListingBloc>(
      create: (_) => IsmInjectionUtils.getBloc<PostListingBloc>(),
      child: PostListingView(
        tagValue: tagValue,
        tagType: tagType,
      ),
    );

    Navigator.of(context).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  /// Navigate to place details
  /// ✅ Wraps the destination with necessary BLoC providers
  static void navigateToPlaceDetails(
    BuildContext context, {
    required String placeId,
    required String placeName,
    required double latitude,
    required double longitude,
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<PlaceDetailsBloc>(
      create: (_) => IsmInjectionUtils.getBloc<PlaceDetailsBloc>(),
      child: PlaceDetailsView(
        placeId: placeId,
        placeName: placeName,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    Navigator.of(context).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  static void navigateTagDetails(
    BuildContext context, {
    required String tagValue,
    required TagType tagType,
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<TagDetailsBloc>(
      create: (_) => IsmInjectionUtils.getBloc<TagDetailsBloc>(),
      child: TagDetailsView(
        tagValue: tagValue,
        tagType: tagType,
      ),
    );

    Navigator.of(context).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  static Future<String?> goToCreatePostView(
    BuildContext context, {
    TransitionType? transitionType,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider<CreatePostBloc>(
          create: (_) => IsmInjectionUtils.getBloc<CreatePostBloc>(),
        ),
        BlocProvider<SearchUserBloc>(
          create: (_) => IsmInjectionUtils.getBloc<SearchUserBloc>(),
        ),
        BlocProvider<UploadProgressCubit>(
          create: (_) => IsmInjectionUtils.getBloc<UploadProgressCubit>(),
        ),
      ],
      child: const CreatePostMultimediaWrapper(),
    );

    final result =
        await Navigator.of(context, rootNavigator: true).push<String>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<String?> goToPostAttributionView(
      BuildContext context, {
        PostAttributeClass? postAttributeClass,
        bool isEditMode = false,
        TransitionType? transitionType,
      }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: PostAttributeView(
        postAttributeClass: postAttributeClass,
        isEditMode: isEditMode,
      ),
    );

    final result =
    await Navigator.of(context, rootNavigator: true).push<String>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<List<MentionData>?> goToTagPeopleScreen(
      BuildContext context, {
        List<MentionData>? mentionDataList,
        List<MediaData>? mediaDataList,
        TransitionType? transitionType,
      }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: TagPeopleScreen(
        mentionDataList: mentionDataList ?? [],
        mediaDataList: mediaDataList ?? [],
      ),
    );

    final result =
    await Navigator.of(context, rootNavigator: true).push<List<MentionData>?>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<List<SocialUserData>> goToSearchUserScreen(
      BuildContext context, {
        List<SocialUserData>? socialUserList,
        TransitionType? transitionType,
      }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: SearchUserView(
        socialUserList: socialUserList ?? [],
      ),
    );

    final result =
    await Navigator.of(context, rootNavigator: true).push<List<SocialUserData>?>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result?.toList() ?? [];
  }

  static void goToPostInsight(
    BuildContext context, {
    required String postId,
    required TimeLineData postData,
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<TagDetailsBloc>(
      create: (_) => IsmInjectionUtils.getBloc<TagDetailsBloc>(),
      child: SocialPostInsightView(
        postId: postId,
        postData: postData,
      ),
    );

    Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  /// Build route based on transition type
  /// Returns MaterialPageRoute if transitionType is null, otherwise PageRouteBuilder
  static Route<T> _buildRoute<T>({
    required Widget page,
    TransitionType? transitionType,
  }) {
    if (transitionType == null) {
      return MaterialPageRoute<T>(
        builder: (context) => page,
      );
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          _buildTransition(
        animation: animation,
        child: child,
        transitionType: transitionType,
      ),
    );
  }

  static Widget _buildTransition({
    required Animation<double> animation,
    required Widget child,
    required TransitionType transitionType,
  }) {
    switch (transitionType) {
      case TransitionType.rightToLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      default:
        return child;
    }
  }

  /// Pop current screen
  static void pop(BuildContext context, {Object? result}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }
}
