import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/models/models.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/utils/navigator/highlight_open_coordinator.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'isr_app_routes.dart';

final GlobalKey<NavigatorState> ismNavigatorKey = GlobalKey<NavigatorState>();

/// Simple navigator helper for SDK internal navigation
class IsrAppNavigator {
  IsrAppNavigator._();

  static const Set<String> _createPostFlowRouteNames = {
    IsrRouteNames.createPostView,
    IsrRouteNames.cameraView,
    IsrRouteNames.mediaEditView,
    IsrRouteNames.postAttributeView,
    IsrRouteNames.videoTrimView,
  };

  static void dismissCreatePostFlow(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (!nav.canPop()) {
      IsrVideoReelConfig.resumeFeedPlayback();
      return;
    }
    nav.popUntil((route) {
      final name = route.settings.name;
      return name == null || !_createPostFlowRouteNames.contains(name);
    });
    IsrVideoReelConfig.resumeFeedPlayback();
  }

  /// Navigate to post listing screen
  /// ✅ Wraps the destination with necessary BLoC providers
  /// Uses rootNavigator to hide bottom navigation bar
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

    Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  /// Navigate to post listing screen
  /// ✅ Wraps the destination with necessary BLoC providers
  /// Uses rootNavigator to hide bottom navigation bar
  static void navigateToSearch(
    BuildContext context, {
    String? search,
    List<SearchTabType>? tabList = SearchTabType.values,
    SearchScreenConfig? config,
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<PostListingBloc>(
      create: (_) => IsmInjectionUtils.getBloc<PostListingBloc>(),
      child: PostListingView(
        searchQuery: search ?? '',
        tabList:
            tabList?.takeIf((list) => list.isNotEmpty) ?? SearchTabType.values,
        config: config,
      ),
    );

    Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  /// Navigate to schedule post listing screen
  /// ✅ Wraps the destination with necessary BLoC providers
  /// Uses rootNavigator to hide bottom navigation bar
  static void navigateToSchedulePostListing(
    BuildContext context, {
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<PostListingBloc>(
      create: (_) => IsmInjectionUtils.getBloc<PostListingBloc>(),
      child: const SchedulePostView(),
    );

    Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  static void navigateToFollowRequests(
    BuildContext context, {
    TransitionType? transitionType,
  }) {
    final page = BlocProvider<FollowRequestsCubit>(
      create: (_) {
        final cubit = IsmInjectionUtils.getBloc<FollowRequestsCubit>();
        cubit.loadInitial();
        return cubit;
      },
      child: const FollowRequestsView(),
    );
    Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

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

    Navigator.of(context, rootNavigator: true).push(
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

    Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  /// Navigate to full-screen reels player with post list
  static Future<void> navigateToReelsPlayer(
    BuildContext context, {
    required List<TimeLineData> postDataList,
    required int startingPostIndex,
    required PostSectionType postSectionType,
    String? tagValue,
    TagType? tagType,
    TabConfig? tabConfig,
    PostConfig? postConfig,
    String? userId,
    String? postId,
    Function(String, String, double, double)? onTapPlace,
    TransitionType transitionType = TransitionType.rightToLeft,
  }) async {
    final tabData = TabDataModel(
      title: _getTabTitle(postSectionType),
      postSectionType: postSectionType,
      reelsDataList: postDataList,
      startingPostIndex: startingPostIndex,
      tagValue: tagValue,
      tagType: tagType,
      userId: userId,
      postId: postId,
    );

    final page = BlocProvider<SocialPostBloc>(
      create: (_) => IsmInjectionUtils.getBloc<SocialPostBloc>(),
      child: IsmPostView(
        tabDataModelList: [tabData],
        startTabIndex: 0,
        onTapPlace: onTapPlace,
        tabConfig: tabConfig,
        postConfig: postConfig,
      ),
    );

    await Navigator.of(context, rootNavigator: true).push(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  /// Helper method to get tab title based on post section type
  static String _getTabTitle(PostSectionType postSectionType) {
    switch (postSectionType) {
      case PostSectionType.forYou:
        return 'For You';
      case PostSectionType.following:
        return 'Following';
      case PostSectionType.trending:
        return 'Trending';
      case PostSectionType.myPost:
        return 'My Posts';
      case PostSectionType.savedPost:
        return 'Saved';
      case PostSectionType.tagPost:
        return 'Posts';
      default:
        return 'Posts';
    }
  }

  static Future<void> goToDubWithAudioCapture(
    BuildContext context, {
    required CreatePostLaunchConfig launchConfig,
  }) async {
    await DubWithAudioCaptureCoordinator.start(context, launchConfig);
  }

  static Future<String?> goToCreatePostView(
    BuildContext context, {
    TransitionType? transitionType,
    MediaEditSoundItem? initialSound,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider<CreatePostBloc>.value(
          value: IsmInjectionUtils.getBloc<CreatePostBloc>(),
        ),
        BlocProvider<SearchUserBloc>.value(
          value: IsmInjectionUtils.getBloc<SearchUserBloc>(),
        ),
        BlocProvider<UploadProgressCubit>.value(
          value: IsmInjectionUtils.getBloc<UploadProgressCubit>(),
        ),
      ],
      child: CreatePostMultimediaWrapper(initialSound: initialSound),
    );

    final result =
        await Navigator.of(context, rootNavigator: true).push<String>(
      _buildRoute(
        page: page,
        transitionType: transitionType,
        routeName: IsrRouteNames.createPostView,
      ),
    );
    return result;
  }

  static Future<void> goToCreateStoryView(
    BuildContext context, {
    TransitionType? transitionType,
  }) async {
    await StoryCreateFlow.open(context);
  }

  static Future<List<StoryGroup>?> presentStoryViewer(
    BuildContext context, {
    required List<StoryGroup> groups,
    required int initialGroupIndex,
    String? highlightId,
    TransitionType transitionType = TransitionType.fade,
  }) async {
    if (groups.isEmpty) return null;
    final cubit = _storyCubitFrom(context);
    final page = BlocProvider<StoryCubit>.value(
      value: cubit,
      child: StoryViewerView(
        groups: List<StoryGroup>.from(groups),
        initialGroupIndex: initialGroupIndex,
        highlightId: highlightId,
      ),
    );
    return Navigator.of(context, rootNavigator: true).push<List<StoryGroup>>(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }

  static bool hasStoryCubitInContext(BuildContext context) {
    try {
      context.read<StoryCubit>();
      return true;
    } catch (_) {
      return false;
    }
  }

  static StoryCubit _storyCubitFrom(BuildContext context) {
    try {
      debugPrint('IsrAppNavigator: StoryCubit resolved from context');
      return context.read<StoryCubit>();
    } catch (_) {
      debugPrint('IsrAppNavigator: StoryCubit missing in context, using DI');
      return IsmInjectionUtils.getBloc<StoryCubit>();
    }
  }

  /// Full highlight composer: pick stories (optional) → create new OR add to existing.
  static Future<void> presentHighlightComposerFlow(
    BuildContext context, {
    StoryData? seedStory,
    List<String>? preselectedStoryIds,
    bool openViewerAfterAdd = false,
  }) async {
    final cubit = _storyCubitFrom(context);
    await HighlightComposerCoordinator.run(
      context: context,
      cubit: cubit,
      seedStory: seedStory,
      preselectedStoryIds: preselectedStoryIds,
      openViewerAfterAdd: openViewerAfterAdd,
    );
  }

  static Future<HighlightOpenResult> presentHighlightViewer(
    BuildContext context, {
    required String highlightId,
    String? userId,
    List<String>? storyIds,
    StoryHighlightData? highlightPreview,
    TransitionType transitionType = TransitionType.fade,
  }) async {
    final cubit = _storyCubitFrom(context);
    final resolved = await HighlightOpenCoordinator.resolve(
      cubit: cubit,
      highlightId: highlightId,
      userId: userId,
      storyIds: storyIds,
    );
    final group = resolved.group;
    if (group != null) {
      await presentStoryViewer(
        context,
        groups: [group],
        initialGroupIndex: 0,
        highlightId: resolved.result.highlightId,
        transitionType: transitionType,
      );
      return resolved.result;
    }
    if (!context.mounted) return resolved.result;
    await _presentEmptyHighlight(
      context,
      cubit: cubit,
      highlightId: resolved.result.highlightId,
      userId: userId,
      highlight: resolved.highlight ?? highlightPreview,
    );
    return resolved.result;
  }

  /// Opens a profile highlight (viewer or empty state with add-stories).
  static Future<HighlightOpenResult> openHighlightFromProfile(
    BuildContext context, {
    required StoryHighlightData highlight,
  }) {
    final id = highlight.id.trim();
    if (id.isEmpty) {
      return Future.value(
        const HighlightOpenResult(
          opened: false,
          reason: 'Highlight id is required.',
          resolvedStoryCount: 0,
          highlightId: '',
        ),
      );
    }
    final storyIds = <String>{
      ...highlight.embeddedStories
          .map((s) => s.id.trim())
          .where((e) => e.isNotEmpty),
      ...highlight.items
          .map((e) => e.storyId.trim())
          .where((e) => e.isNotEmpty),
    }.toList();
    final userId = highlight.userId.trim();
    return presentHighlightViewer(
      context,
      highlightId: id,
      userId: userId.isNotEmpty ? userId : null,
      storyIds: storyIds,
      highlightPreview: highlight,
    );
  }

  static Future<void> _presentEmptyHighlight(
    BuildContext context, {
    required StoryCubit cubit,
    required String highlightId,
    String? userId,
    StoryHighlightData? highlight,
  }) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<StoryCubit>.value(
          value: cubit,
          child: EmptyHighlightScreen(
            highlightId: highlightId,
            userId: userId,
            initialHighlight: highlight,
          ),
        ),
      ),
    );
  }

  static Future<HighlightOpenResult> openHighlightById(
    String highlightId, {
    String? userId,
    TransitionType transitionType = TransitionType.fade,
  }) async {
    final context = IsrVideoReelConfig.getBuildContext?.call() ??
        IsrVideoReelConfig.buildContext;
    if (context == null) {
      const reason = 'BuildContext unavailable for highlight navigation.';
      IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryActionError
          ?.call('open_highlight_by_id', reason);
      IsrVideoReelConfig
          .storyConfig?.storyCallbackConfig.onHighlightOpenDiagnostics
          ?.call(
        HighlightOpenDiagnostics(
          highlightId: highlightId.trim(),
          targetStoryIds: const [],
          resolvedStoryIds: const [],
          stepsAttempted: const ['resolve_context_failed'],
          reason: reason,
          opened: false,
        ),
      );
      return HighlightOpenResult(
        opened: false,
        reason: reason,
        resolvedStoryCount: 0,
        highlightId: highlightId.trim(),
      );
    }
    return IsrAppNavigator.presentHighlightViewer(
      context,
      highlightId: highlightId,
      userId: userId,
      transitionType: transitionType,
    );
  }

  static Future<String?> goToEditPostView(
    BuildContext context, {
    required TimeLineData postData,
    TransitionType? transitionType,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(
            value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: PostAttributeView(
        postData: postData,
        isEditMode: true,
      ),
    );

    final result =
        await Navigator.of(context, rootNavigator: true).push<String>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<dynamic> goToCreatePostAttributionView(
    BuildContext context, {
    List<MediaData>? newMediaDataList,
    MediaEditSoundItem? selectedSound,
    bool dismissEntireFlowOnClose = false,
    TransitionType transitionType = TransitionType.bottomToTop,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(
            value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: PostAttributeView(
        newMediaDataList: newMediaDataList,
        selectedSound: selectedSound,
        isEditMode: false,
        dismissEntireFlowOnClose: dismissEntireFlowOnClose,
      ),
    );

    final result =
        await Navigator.of(context, rootNavigator: true).push<dynamic>(
      _buildRoute(
        page: page,
        transitionType: transitionType,
        routeName: IsrRouteNames.postAttributeView,
      ),
    );
    return result;
  }

  static Future<List<TaggedPlace>?> goToSearchLocation(
    BuildContext context, {
    List<TaggedPlace>? taggedPlaceList,
    TransitionType? transitionType,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(
            value: context.getOrCreateBloc<SearchLocationBloc>()),
      ],
      child: SearchLocationScreen(
        taggedPlaceList: taggedPlaceList,
      ),
    );

    final result = await Navigator.of(context, rootNavigator: true)
        .push<List<TaggedPlace>?>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<List<MentionData>?> goToTagPeopleScreen(
    BuildContext context, {
    List<MentionData>? mentionDataList,
    List<MediaData>? mediaDataList,
    String? postId,
    TransitionType? transitionType,
  }) async {
    debugPrint(
        'goToTagPeopleScreen:- MentionDataList: ${mentionDataList?.map((e) => e.toJson()).toList()}');
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(
            value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: TagPeopleScreen(
        mentionDataList: mentionDataList ?? [],
        mediaDataList: mediaDataList ?? [],
        postId: postId,
      ),
    );

    final result = await Navigator.of(context, rootNavigator: true)
        .push<List<MentionData>?>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<List<ms.MediaAssetData>?> goToMediaPickerScreen(
    BuildContext context, {
    ms.MediaSelectionConfig? mediaSelectionConfig,
    List<ms.MediaAssetData>? selectedMedia,
    Future<bool> Function(List<ms.MediaAssetData> selectedMedia)? onComplete,
    Future<dynamic> Function(String? mediaType)? onCaptureMedia,
    TransitionType? transitionType,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
      ],
      child: ms.MediaSelectionView(
        mediaSelectionConfig: mediaSelectionConfig ?? ms.MediaSelectionConfig(),
        onCaptureMedia: onCaptureMedia,
        onComplete: onComplete,
        selectedMedia: selectedMedia,
      ),
    );

    final result = await Navigator.of(context, rootNavigator: true)
        .push<List<ms.MediaAssetData>?>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result;
  }

  static Future<List<SocialUserData>> goToSearchUserScreen(
    BuildContext context, {
    List<SocialUserData>? socialUserList,
    /// Max selections allowed this session (e.g. remaining total tag slots).
    /// When null, [SearchUserView] uses [TagPeopleScreenConfig.maxTaggedPeople].
    int? maxSelectablePeople,
    TransitionType? transitionType,
  }) async {
    final page = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.getOrCreateBloc<CreatePostBloc>()),
        BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        BlocProvider.value(
            value: context.getOrCreateBloc<UploadProgressCubit>()),
      ],
      child: SearchUserView(
        socialUserList: socialUserList ?? [],
        maxSelectablePeople: maxSelectablePeople,
      ),
    );

    final result = await Navigator.of(context, rootNavigator: true)
        .push<List<SocialUserData>?>(
      _buildRoute(page: page, transitionType: transitionType),
    );
    return result?.toList() ?? [];
  }

  static void goToPostInsight(
    BuildContext context, {
    required String postId,
    TimeLineData? postData,
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
    String? routeName,
  }) {
    final settings =
        routeName != null ? RouteSettings(name: routeName) : null;
    if (transitionType == null) {
      return MaterialPageRoute<T>(
        builder: (context) => page,
        settings: settings,
      );
    }

    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => Material(
        type: MaterialType.transparency,
        child: page,
      ),
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

  static Future<CollectionData?> navigateCollectionDetailsView(
    BuildContext context, {
    required CollectionData collectionData,
    TransitionType? transitionType,
  }) async {
    final page = BlocProvider<CollectionBloc>.value(
      value: IsmInjectionUtils.getBloc<CollectionBloc>(),
      child: CollectionDetailsView(
        collectionData: collectionData,
      ),
    );

    return await Navigator.of(context, rootNavigator: true)
        .push<CollectionData>(
      _buildRoute(page: page, transitionType: transitionType),
    );
  }
}
