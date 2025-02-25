import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsrReelView extends StatefulWidget {
  IsrReelView({
    super.key,
    this.onTapProfilePic,
    this.onTapShare,
    this.onTapProduct,
    required this.context,
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

  @override
  State<IsrReelView> createState() => _IsrReelViewState();
}

class _IsrReelViewState extends State<IsrReelView> {
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => InjectionUtils.getBloc<IsmLandingBloc>()),
          BlocProvider(create: (context) => InjectionUtils.getBloc<PostBloc>()),
        ],
        child: BlocListener<IsmLandingBloc, IsmLandingState>(
          listener: (context, state) {
            // Call _handleInitialRoute when the BLoC is created or in a specific state
            if (state is StartIsmLandingState) {
              // Adjust this condition based on your BLoC's initial state
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
              routerConfig: IsrAppRouter.router,
            ),
          ),
        ),
      );

  void _handleInitialRoute() {
    if (!mounted) return;

    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showAppDialog(message: 'sdk not initialized');
      return;
    }

    // Here you can add your routing conditions
    InjectionUtils.getRouteManagement().goToPostView(context: context);
  }
}
