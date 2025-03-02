import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

class IsrReelView extends StatefulWidget {
  IsrReelView({
    super.key,
    this.onTapProfilePic,
    this.onTapShare,
    this.onTapProduct,
    required this.context,
    this.followingPosts,
    this.trendingPosts,
  }) {
    IsrReelsProperties.onTapProfilePic = onTapProfilePic;
    IsrReelsProperties.onTapShare = onTapShare;
    IsrReelsProperties.onTapProduct = onTapProduct;
    IsrVideoReelConfig.buildContext = context;
  }

  final Function(String)? onTapProfilePic;
  final Function(String)? onTapShare;
  final Function(String)? onTapProduct;
  final BuildContext context;
  final List<PostDataModel>? followingPosts;
  final List<PostDataModel>? trendingPosts;

  @override
  State<IsrReelView> createState() => _IsrReelViewState();
}

class _IsrReelViewState extends State<IsrReelView> {
  late final GoRouter _sdkRouter;

  @override
  void initState() {
    super.initState();
    _sdkRouter = _createRouter();
  }

  GoRouter _createRouter() => GoRouter(
        initialLocation: IsrAppRoutes.postView,
        navigatorKey: ismNavigatorKey,
        routes: [
          GoRoute(
            path: IsrAppRoutes.postView,
            name: IsrRouteNames.postView,
            builder: (context, state) => BlocProvider.value(
              value: IsmInjectionUtils.getBloc<PostBloc>(), // Provide PostBloc here
              child: const SizedBox(),
            ),
          ),
          GoRoute(
            path: IsrAppRoutes.landingView,
            name: IsrRouteNames.landingView,
            builder: (context, state) => IsrReelView(
              context: context,
            ),
          ),
          // GoRoute(
          //   path: IsrAppRoutes.createPostView,
          //   name: IsrRouteNames.createPostView,
          //   builder: (context, state) => BlocProvider.value(
          //     value: InjectionUtils.getBloc<PostBloc>(), // Provide PostBloc here
          //     child: const IsmCreatePostView(),
          //   ),
          // ),
          // GoRoute(
          //   path: IsrAppRoutes.cameraView,
          //   name: IsrRouteNames.cameraView,
          //   builder: (context, state) {
          //     final extras = state.extra as Map<String, dynamic>;
          //     final mediaType = extras['mediaType'] as MediaType? ?? MediaType.photo;
          //     return IsmCameraView(mediaType: mediaType);
          //   },
          // ),
          // GoRoute(
          //   path: IsrAppRoutes.postAttributeView,
          //   name: IsrRouteNames.postAttributeView,
          //   builder: (context, state) {
          //     final extraMap = state.extra as Map;
          //     return IsrPostAttributeView(
          //       postAttributeClass: extraMap['postAttributeClass'] as PostAttributeClass?,
          //     );
          //   },
          // ),
        ],
      );

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => IsmInjectionUtils.getBloc<IsmLandingBloc>()), // Provide IsmLandingBloc here
          BlocProvider(create: (_) => IsmInjectionUtils.getBloc<PostBloc>()), // Provide PostBloc here
        ],
        child: BlocListener<IsmLandingBloc, IsmLandingState>(
          listener: (context, state) {
            if (state is StartIsmLandingState) {
              _handleInitialRoute();
            }
          },
          child: AnnotatedRegion(
            value: const SystemUiOverlayStyle(
              statusBarColor: IsrColors.transparent,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: isrTheme,
              routerConfig: _sdkRouter,
            ),
          ),
        ),
      );

  void _handleInitialRoute() {
    if (!mounted) return;

    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showAppDialog(message: 'SDK not initialized');
      return;
    }

    IsmInjectionUtils.getRouteManagement().goToPostView(context: context);
  }
}
