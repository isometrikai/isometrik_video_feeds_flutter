import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/create_post_flow_coordinator.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/create_text_post_view.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';
import 'package:ism_video_reel_player/utils/navigator/ism_page_transition.dart';

/// Coordinates the text post creation flow (plain/card text + optional media).
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

  /// Opens gallery picker (images + videos) and returns processed [MediaData].
  static Future<List<MediaData>> pickFromGallery(
    BuildContext context, {
    required int remainingSlots,
    required int remainingImages,
    required int remainingVideos,
  }) async {
    if (remainingSlots <= 0) return [];

    final selected = await IsrAppNavigator.presentCreatePostMediaSelector(
      context,
      config: CreatePostFlowCoordinator.defaultMediaSelectionConfig(
        selectMediaTitle: IsrTranslationFile.choosePhotoOrVideo,
        imageMediaLimit: remainingImages.clamp(0, AppConstants.imageMediaLimit),
        videoMediaLimit: remainingVideos.clamp(0, AppConstants.videoMediaLimit),
        mediaLimit: remainingSlots.clamp(0, AppConstants.totalMediaLimit),
        mediaListType: ms.MediaListType.imageVideo,
      ),
    );
    if (selected == null || selected.isEmpty || !context.mounted) return [];

    final editItems = await CreatePostFlowCoordinator.prepareEditItemsFromSelection(
      context,
      selectedMedia: selected,
    );
    if (!context.mounted || editItems.isEmpty) return [];

    return CreatePostFlowCoordinator.mediaDataFromEditItems(editItems);
  }

  /// Opens camera (photo or video) and returns processed [MediaData].
  static Future<List<MediaData>> captureFromCamera(BuildContext context) async {
    final capture = await IsrAppNavigator.presentCameraCapture(context);
    if (capture == null || capture.mediaPath.isEmpty || !context.mounted) {
      return [];
    }

    final editItems = await CreatePostFlowCoordinator.prepareEditItemsFromCapture(
      context,
      capture: capture,
    );
    if (!context.mounted || editItems.isEmpty) return [];

    return CreatePostFlowCoordinator.mediaDataFromEditItems(editItems);
  }
}
