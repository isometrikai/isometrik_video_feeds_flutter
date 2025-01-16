import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/export.dart';

class IsmLandingView extends StatefulWidget {
  IsmLandingView({
    super.key,
    this.isFromExample = false,
    this.onBackPress,
    this.isValid,
    this.isProp,
  }) {
    IsrReelsProperties.onBackPress = onBackPress;
    IsrReelsProperties.isValid = isValid;
    IsrReelsProperties.isProp = isProp;
  }

  final bool? isFromExample;
  final VoidCallback? onBackPress;
  final Function(bool)? isValid;
  final bool Function(bool)? isProp;

  @override
  State<IsmLandingView> createState() => _IsmLandingViewState();
}

class _IsmLandingViewState extends State<IsmLandingView> {
  bool _isFirstBuild = true;

  void _handleInitialRoute() {
    if (!mounted) return;

    if (!IsmVideoReelConfig.isSdkInitialize) {
      IsmVideoReelUtility.showAppDialog(message: 'sdk not initialized');
      return;
    }

    // Here you can add your routing conditions
    RouteManagement.goToPostView();
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
