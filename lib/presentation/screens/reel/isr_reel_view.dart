import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsrReelView extends StatefulWidget {
  IsrReelView({
    super.key,
    this.isFromExample = false,
    this.onTapProfilePic,
    this.onTapShare,
    this.onTapProduct,
  }) {
    IsrReelsProperties.onTapProfilePic = onTapProfilePic;
    IsrReelsProperties.onTapShare = onTapShare;
    IsrReelsProperties.onTapProduct = onTapProduct;
  }

  final bool? isFromExample;
  final Function(String)? onTapProfilePic;
  final Function(String)? onTapShare;
  final Function(String)? onTapProduct;

  @override
  State<IsrReelView> createState() => _IsrReelViewState();
}

class _IsrReelViewState extends State<IsrReelView> {
  bool _isFirstBuild = true;

  void _handleInitialRoute() {
    if (!mounted) return;

    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showAppDialog(message: 'sdk not initialized');
      return;
    }

    // Here you can add your routing conditions
    InjectionUtils.getRouteManagement().goToPostView();
  }

  @override
  Widget build(BuildContext context) {
    // Schedule the routing check after the first build
    if (_isFirstBuild) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialRoute();
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => isrGetIt<PostBloc>(),
        ),
      ],
      child: widget.isFromExample == true
          ? const Scaffold(
              backgroundColor: Colors.black26,
              body: SizedBox.shrink(),
            )
          : MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: isrTheme,
              routerConfig: IsrAppRouter.router,
            ),
    );
  }
}
