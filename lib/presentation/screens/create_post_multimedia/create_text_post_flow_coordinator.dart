import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/create_text_post_view.dart';
import 'package:ism_video_reel_player/utils/navigator/ism_page_transition.dart';

/// Coordinates the text-only post creation flow.
abstract final class CreateTextPostFlowCoordinator {
  CreateTextPostFlowCoordinator._();

  static Future<dynamic> run(
    BuildContext context, {
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<CreatePostBloc>.value(
      value: IsmInjectionUtils.getBloc<CreatePostBloc>(),
      child: const CreateTextPostView(),
    );

    return Navigator.of(context, rootNavigator: true).push<dynamic>(
      PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
          child: child,
        ),
      ),
    );
  }
}
