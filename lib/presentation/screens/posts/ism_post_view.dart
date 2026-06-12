import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_active_video_player_registry.dart';
import 'package:ism_video_reel_player/utils/isr_image_sound_registry.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;
import 'package:visibility_detector/visibility_detector.dart';

class IsmPostView extends StatefulWidget {
  const IsmPostView({
    super.key,
    required this.tabDataModelList,
    this.startTabIndex = 0,
    this.allowImplicitScrolling = false,
    this.onTapPlace,
    this.tabConfig,
    this.postConfig,
    this.centralKey,
    this.isOverlayPlayer = false,
  });

  final List<TabDataModel> tabDataModelList;
  final num? startTabIndex;
  final bool? allowImplicitScrolling;
  final TabConfig? tabConfig;
  final PostConfig? postConfig;
  final String? centralKey;

  /// Full-screen player pushed over Explore/Profile; ignores host tab pause.
  final bool isOverlayPlayer;

  /// Optional callback to override default place navigation
  /// If not provided, SDK will navigate to PlaceDetailsView automatically
  /// Parameters: placeId, placeName, latitude, longitude
  final Function(String placeId, String placeName, double lat, double long)?
      onTapPlace;

  static Map<PostSectionType, List<TimeLineData>>? getLoadedTabReels(
          String cacheKey) =>
      _PostViewState.getLoadedTabReels(cacheKey);

  @override
  State<IsmPostView> createState() => _PostViewState();
}

class _PostViewState extends State<IsmPostView> with TickerProviderStateMixin {
  TabController? _postTabController;
  late List<RefreshController> _refreshControllers;
  var _currentIndex = 1;
  var _loggedInUserId = '';
  final ValueNotifier<bool> _tabsVisibilityNotifier = ValueNotifier<bool>(true);
  List<TabStateModel> get _tabDataModelList =>
      _centralTadData.putIfAbsent(centralKey, () => <TabStateModel>[]);
  VideoCacheManager? _videoCacheManager;
  late SocialPostBloc _socialPostBloc; // Will be initialized from context
  late IsmSocialActionCubit _socialActionCubit;
  var _currentPostSectionType = PostSectionType.forYou;
  PostConfig get _postConfig =>
      widget.postConfig ?? IsrVideoReelConfig.postConfig;
  TabDataModel get _currentTabDataModel =>
      _tabDataModelList[_currentIndex].tabDataModel;

  bool get _isCurrentTabPostFeed =>
      _currentTabDataModel.feedLayoutType == FeedLayoutType.postFeed;

  TabConfig get _tabConfig => widget.tabConfig ?? IsrVideoReelConfig.tabConfig;
  SocialConfig get _socialConfig => IsrVideoReelConfig.socialConfig;

  // Tab config helper getters
  TabUIConfig? get _tabUIConfig => _tabConfig.tabUIConfig;
  TabBarConfig? get _tabBarConfig => _tabUIConfig?.tabBarConfig;
  BackButtonConfig? get _backButtonConfig => _tabUIConfig?.backButtonConfig;
  LoadingViewConfig? get _loadingViewConfig => _tabUIConfig?.loadingViewConfig;
  StatusBarConfig? get _statusBarConfig => _tabUIConfig?.statusBarConfig;

  //caches
  static final Map<String, List<TabStateModel>> _centralTadData = {};
  final Map<PostSectionType, List<ReelsData>> _mappedReelsByTab = {};
  final Map<PostSectionType, int> _mappedReelsVersionByTab = {};
  late String centralKey;
  static Map<PostSectionType, List<TimeLineData>>? getLoadedTabReels(
          String centralKey) =>
      _centralTadData[centralKey]?.asMap().map((key, value) => MapEntry(
          value.tabDataModel.postSectionType,
          value.tabDataModel.reelsDataList.toList()));

  /// When false, tab bodies stay a cheap placeholder so the push transition
  /// is not competing with [PostItemWidget] / video precache on the GPU.
  var _reelsBodyReady = false;
  var _routeEnterListenerScheduled = false;
  Animation<double>? _routeEnterAnimation;
  AnimationStatusListener? _routeEnterStatusListener;
  var _initialPostLoadDispatched = false;
  var _initialCommentOpenAttempted = false;
  var _tabChangeRequestId = 0;
  final Set<int> _materializedTabIndices = <int>{};

  @override
  void initState() {
    centralKey = widget.centralKey ??
        '${runtimeType}_${DateTime.now().millisecondsSinceEpoch}_default_central';
    _socialPostBloc = context.getOrCreateBloc();
    if (_socialPostBloc.isClosed) {
      isrConfigureInjection();
      _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
    }
    _socialActionCubit = context.getOrCreateBloc();
    if (!widget.isOverlayPlayer) {
      IsrVideoReelConfig.onHostFeedTabResumed = _onHostFeedTabResumed;
      IsrVideoReelConfig.getActiveHostPostSection = () => _currentPostSectionType;
    }
    IsrVideoReelConfig.registerAppForegroundResumedListener(
      _onAppForegroundResumed,
    );
    _onStartInit();
    super.initState();
  }

  void _onHostFeedTabResumed() {
    _markCurrentTabVisibleForPlayback();
  }

  void _onAppForegroundResumed() {
    if (widget.isOverlayPlayer) {
      if (!IsrVideoReelConfig.isOverlayReelsPlayerActive) return;
    } else if (IsrVideoReelConfig.isOverlayReelsPlayerActive) {
      return;
    }
    _markCurrentTabVisibleForPlayback();
  }

  void _markCurrentTabVisibleForPlayback() {
    if (!mounted) return;
    if (_currentIndex >= 0 && _currentIndex < _tabDataModelList.length) {
      _tabDataModelList[_currentIndex].isVisible = true;
    }
    VisibilityDetectorController.instance.notifyNow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the BuildContext for SDK use
    IsrVideoReelConfig.buildContext = context;
  }

  void _onStartInit() async {
    _tabDataModelList.clear();
    _tabDataModelList.addAll(widget.tabDataModelList
        .map((tab) => TabStateModel(
            isLoading: tab.reelsDataList.isEmpty, tabDataModel: tab))
        .toList());
    _currentIndex = (_tabDataModelList.length > (widget.startTabIndex ?? 0))
        ? widget.startTabIndex?.toInt() ?? 0
        : 0;
    _currentPostSectionType =
        _tabDataModelList[_currentIndex].tabDataModel.postSectionType;
    if (_currentIndex >= _tabDataModelList.length) {
      _currentIndex = 0;
    }
    _materializedTabIndices.add(_currentIndex);
    if (widget.isOverlayPlayer && _tabDataModelList.isNotEmpty) {
      _tabDataModelList[_currentIndex].isVisible = true;
    }
    if (!IsrVideoReelConfig.isSdkInitialize) {
      Utility.showToastMessage('sdk not initialized');
      return;
    }
    // Initialize TabController with initialIndex = _currentIndex
    _postTabController = TabController(
      length: _tabDataModelList.length,
      vsync: this,
      initialIndex: _currentIndex,
    );

    _refreshControllers =
        List.generate(_tabDataModelList.length, (index) => RefreshController());

    _tabsVisibilityNotifier.value = _tabDataModelList.length > 1;

    if (_isFollowingPostsEmpty()) {
      // _tabsVisibilityNotifier.value = false;
    }
    _scheduleReelsBodyWhenRouteSettled();
    _loggedInUserId = await _socialPostBloc.userId;
    _postTabController?.addListener(() async {
      if (!mounted) return;
      final controller = _postTabController;
      if (controller == null || controller.indexIsChanging) return;

      final newIndex = controller.index;
      if (newIndex < 0 || newIndex >= _tabDataModelList.length) return;
      final lastIndex = _currentIndex;
      if (_currentIndex != newIndex) {
        final requestId = ++_tabChangeRequestId;
        _currentIndex = newIndex;
        _materializedTabIndices.add(newIndex);
        final tabData = _tabDataModelList[newIndex];
        if (tabData.tabDataModel.postSectionType.isUserDependent) {
          var isUserLoggedIn = await _socialPostBloc.isUserLoggedIn;
          if (!mounted || requestId != _tabChangeRequestId) return;
          if (!isUserLoggedIn) {
            await _socialConfig.socialCallBackConfig?.onLoginInvoked?.call();
            isUserLoggedIn = await _socialPostBloc.isUserLoggedIn;
            if (!mounted || requestId != _tabChangeRequestId) return;
          }
          if (!isUserLoggedIn) {
            _currentIndex = lastIndex;
            final safeIndex = lastIndex.clamp(0, _tabDataModelList.length - 1);
            if ((_postTabController?.index ?? safeIndex) != safeIndex) {
              _postTabController?.animateTo(safeIndex);
            }
            return;
          }
        }
        _currentPostSectionType = tabData.tabDataModel.postSectionType;
        _tabConfig.tabCallBackConfig?.onChangeOfTab?.call(tabData.tabDataModel);
        // Handle tab change if we have a user
        if (_loggedInUserId.isNotEmpty) {
          try {
            _videoCacheManager = VideoCacheManager();
          } catch (e) {
            debugPrint('Error during tab change: $e');
          }
        }
        if (!mounted || requestId != _tabChangeRequestId) return;
        _handoffTabPlayback(lastIndex: lastIndex, newIndex: newIndex);
        setState(() {});
        if (tabData.tabDataModel.reelsDataList.isEmpty) {
          _requestHomeTabLoad(tabData);
        }
      }
    });
  }

  /// Stops image/sound bleed from a kept-alive offstage tab (e.g. Feed → Following).
  void _handoffTabPlayback({required int lastIndex, required int newIndex}) {
    unawaited(
      _handoffTabPlaybackAsync(lastIndex: lastIndex, newIndex: newIndex),
    );
  }

  Future<void> _handoffTabPlaybackAsync({
    required int lastIndex,
    required int newIndex,
  }) async {
    if (lastIndex >= 0 && lastIndex < _tabDataModelList.length) {
      _tabDataModelList[lastIndex].isVisible = false;
      final oldSection =
          _tabDataModelList[lastIndex].tabDataModel.postSectionType;
      IsrActiveVideoPlayerRegistry.pauseAll();
      _emitScopedPlayPause(oldSection, play: false);
      await IsrImageSoundRegistry.stopAll();
    }
    if (newIndex >= 0 && newIndex < _tabDataModelList.length) {
      _tabDataModelList[newIndex].isVisible = true;
    }
    final newSection = _tabDataModelList[newIndex].tabDataModel.postSectionType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitScopedPlayPause(
        newSection,
        play: true,
        pausePlayback: true,
      );
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  void _emitScopedPlayPause(
    PostSectionType section, {
    required bool play,
    bool pausePlayback = true,
  }) {
    _socialPostBloc.add(
      PlayPauseVideoEvent(
        play: play,
        pausePlayback: pausePlayback,
        scopedPostSection: section,
      ),
    );
  }

  void _scheduleReelsBodyWhenRouteSettled() {
    if (_routeEnterListenerScheduled) return;
    _routeEnterListenerScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = ModalRoute.of(context)?.animation;
      void onEnterCompleted() {
        if (!mounted || _reelsBodyReady) return;
        _tearDownRouteEnterListener();
        _reelsBodyReady = true;
        _dispatchInitialPostLoad();
        _scheduleInitialCommentOpen();
        setState(() {});
      }

      if (animation == null ||
          animation.status == AnimationStatus.completed ||
          animation.value >= 1.0) {
        onEnterCompleted();
        return;
      }

      _routeEnterAnimation = animation;
      _routeEnterStatusListener = (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          onEnterCompleted();
        }
      };
      animation.addStatusListener(_routeEnterStatusListener!);
    });
  }

  void _tearDownRouteEnterListener() {
    final anim = _routeEnterAnimation;
    final listener = _routeEnterStatusListener;
    if (anim != null && listener != null) {
      anim.removeStatusListener(listener);
    }
    _routeEnterAnimation = null;
    _routeEnterStatusListener = null;
  }

  void _dispatchInitialPostLoad() {
    if (_initialPostLoadDispatched ||
        !IsrVideoReelConfig.isSdkInitialize ||
        _postTabController == null) {
      return;
    }
    _initialPostLoadDispatched = true;
    _socialPostBloc.add(LoadPostData(
        startTabIndex: _currentIndex,
        postSections: widget.tabDataModelList
            .map((_) => PostTabAssistData(
                postSectionType: _.postSectionType,
                postList: _.reelsDataList,
                postId: _.postId,
                userId: _.userId,
                tagType: _.tagType,
                tagValue: _.tagValue))
            .toList()));
  }

  void _requestHomeTabLoad(TabStateModel tabState) {
    tabState.isLoading = true;
    final section = tabState.tabDataModel.postSectionType;
    if (!_socialPostBloc.hasTabAssistData(section)) {
      _dispatchInitialPostLoad();
      return;
    }
    _socialPostBloc.add(LoadHomeTabEvent(postSectionType: section));
  }

  void _scheduleInitialCommentOpen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_maybeOpenInitialComment());
        }
      });
    });
  }

  Future<void> _maybeOpenInitialComment() async {
    if (_initialCommentOpenAttempted || !_reelsBodyReady) return;

    final tabData = _tabDataModelList[_currentIndex].tabDataModel;
    final commentId = tabData.initialCommentId?.trim();
    if (commentId == null || commentId.isEmpty) return;

    final posts = tabData.reelsDataList;
    if (posts.isEmpty) return;

    _initialCommentOpenAttempted = true;
    final startIndex = tabData.startingPostIndex ?? 0;
    final safeIndex = startIndex < 0
        ? 0
        : (startIndex >= posts.length ? posts.length - 1 : startIndex);
    final postData = posts[safeIndex];
    final postId = (tabData.postId ?? postData.id ?? '').trim();
    if (postId.isEmpty) return;

    var isUserLoggedIn = await _socialActionCubit.isUserLoggedIn;
    if (!isUserLoggedIn) {
      await _socialConfig.socialCallBackConfig?.onLoginInvoked?.call();
    }
    isUserLoggedIn = await _socialActionCubit.isUserLoggedIn;
    if (!isUserLoggedIn || !mounted) return;

    final commentCount = postData.engagementMetrics?.comments?.toInt() ?? 0;

    _emitScopedPlayPause(tabData.postSectionType, play: false);
    try {
      await _handleCommentAction(
        postId,
        commentCount,
        tabData,
        postData,
        highlightCommentId: commentId,
      );
    } finally {
      if (mounted) {
        _emitScopedPlayPause(tabData.postSectionType, play: true);
      }
    }
  }

  // ✅ Provide BLoCs at the root of build
  @override
  Widget build(BuildContext context) => IsrSdkTextStyleScope(
        useReelsOverlayDefaults: !_isCurrentTabPostFeed,
        child: MultiBlocProvider(
          providers: _getAllBlocProviders(),
          child: _buildContent(),
        ),
      );

  /// ✅ Get all BLoC providers needed by the SDK
  /// Note: PostListingBloc and PlaceDetailsBloc are provided during navigation
  List<BlocProvider> _getAllBlocProviders() => [
        // Social Post BLoC (main BLoC for this screen)
        BlocProvider<SocialPostBloc>(
          create: (_) => _socialPostBloc, // ✅ Trigger initial load
        ),
      ];

  // ✅ Don't wrap with BlocProvider again - just use BlocConsumer
  Widget _buildContent() => AnnotatedRegion(
        value: SystemUiOverlayStyle(
          statusBarColor: _statusBarConfig?.statusBarColor ??
              (_isCurrentTabPostFeed
                  ? _postConfig.resolvedPostFeedUIConfig.backgroundColor
                  : IsrColors.transparent),
          statusBarBrightness: _statusBarConfig?.statusBarBrightness ??
              (_isCurrentTabPostFeed ? Brightness.light : Brightness.dark),
          statusBarIconBrightness: _statusBarConfig?.statusBarIconBrightness ??
              (_isCurrentTabPostFeed ? Brightness.dark : Brightness.light),
        ),
        child: context.attachBlocIfNeeded<IsmSocialActionCubit>(
          bloc: _socialActionCubit,
          child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
            listenWhen: (previousState, currentState) =>
                currentState is IsmDeletedPostActionListenerState ||
                currentState is IsmMentionRemovedActionListenerState ||
                currentState is IsmEditPostActionListenerState ||
                currentState is IsmUserChangedActionListenerState,
            listener: (context, state) {
              // Do Not setState to prevent reels to start from first
              // this is only to update data to update ui it is done in post_item_widget
              if (state is IsmDeletedPostActionListenerState &&
                  state.postId?.isNotEmpty == true) {
                _removePostFromList(state.postId!);
              } else if (state is IsmMentionRemovedActionListenerState) {
                _stripSelfMentionFromTimelinePost(state.postId);
                if (state.postId.isNotEmpty &&
                    _tabDataModelList.any(
                      (tab) =>
                          tab.tabDataModel.postSectionType ==
                          PostSectionType.myTaggedPost,
                    )) {
                  _removePostFromList(state.postId);
                }
              } else if (state is IsmEditPostActionListenerState &&
                  state.postData != null) {
                _replacePostFromList(state.postData!);
              } else if (state is IsmUserChangedActionListenerState) {
                _onUserChanged(state.userId);
              }
            },
            child: Stack(
              children: [
                if (_isCurrentTabPostFeed)
                  Positioned.fill(
                    child: ColoredBox(
                      color:
                          _postConfig.resolvedPostFeedUIConfig.backgroundColor,
                    ),
                  ),
                BlocListener<SocialPostBloc, SocialPostState>(
                  bloc: _socialPostBloc,
                  listenWhen: (previousState, currentState) =>
                      currentState is SocialPostLoadedState ||
                      currentState is PostLoadingState,
                  listener: (context, state) {
                    // ✅ Update _socialPostBloc reference if needed
                    debugPrint(
                        'ism_post_view: listener called with state: $state');
                    if (state is SocialPostLoadedState) {
                      final tabStateData = _tabDataModelList
                          .where((_) =>
                              _.tabDataModel.postSectionType == state.postType)
                          .firstOrNull;
                      final tabData = tabStateData?.tabDataModel;
                      if (tabData != null) {
                        final existing = tabData.reelsDataList;
                        final incoming = state.postList;
                        if (existing.isEmpty) {
                          tabData.reelsDataList = incoming.toList();
                        } else if (incoming.length >= existing.length) {
                          tabData.reelsDataList = incoming.toList();
                        } else {
                          // Keep paginated items if a late initial load arrives
                          // with only the first API page.
                          final existingIds = existing
                              .map((p) => p.id)
                              .whereType<String>()
                              .toSet();
                          final newOnly = incoming
                              .where((p) =>
                                  p.id != null &&
                                  p.id!.isNotEmpty &&
                                  !existingIds.contains(p.id))
                              .toList();
                          if (newOnly.isNotEmpty) {
                            tabData.reelsDataList = [
                              ...newOnly,
                              ...existing,
                            ];
                          }
                        }
                      }
                      _mappedReelsByTab.remove(state.postType);
                      _mappedReelsVersionByTab.remove(state.postType);
                      tabStateData?.isLoading = false;
                      if (mounted) setState(() {});
                    } else if (state is PostLoadingState &&
                        state.postType != null) {
                      final tabStateData = _tabDataModelList
                          .where((_) =>
                              _.tabDataModel.postSectionType == state.postType)
                          .firstOrNull;
                      tabStateData?.isLoading = true;
                    }
                  },
                  child: DefaultTabController(
                    length: _tabDataModelList.isListEmptyOrNull
                        ? 0
                        : _tabDataModelList.length,
                    initialIndex: _currentIndex,
                    child: _buildLazyTabStack(),
                  ),
                ),
                if (_tabDataModelList.length > 1) ...[
                  _buildTabBar()
                ] else if (_isCurrentTabPostFeed)
                  _buildPostFeedHeader()
                else ...[
                  _buildSingleTabTopBar()
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildPostFeedHeader() {
    final feedUi = _postConfig.resolvedPostFeedUIConfig;
    if (!feedUi.showHeader) {
      return const SizedBox.shrink();
    }

    final configuredTitle = feedUi.title?.trim();
    final title = configuredTitle?.isNotEmpty == true
        ? configuredTitle!
        : (_tabDataModelList.isNotEmpty
            ? _tabDataModelList[_currentIndex].tabDataModel.title
            : '');

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ColoredBox(
        color: feedUi.backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: IsrDimens.edgeInsetsSymmetric(
              horizontal: IsrDimens.sixteen,
              vertical: IsrDimens.twelve,
            ),
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: feedUi.headerTextColor,
                    ),
                    onPressed: () => context.pop(),
                  ),
                if (title.isNotEmpty)
                  Expanded(
                    child: Text(
                      title,
                      style: feedUi.titleTextStyle ??
                          IsrStyles.primaryText18.copyWith(
                            fontWeight: FontWeight.w700,
                            color: feedUi.headerTextColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (_tabBarConfig?.rightWidget != null)
                  _tabBarConfig!.rightWidget!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleTabTopBar() {
    final rightWidget = _tabBarConfig?.rightWidget;
    final showRight = rightWidget != null;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: _backButtonConfig?.buttonDecoration ??
                BoxDecoration(
                  color: Colors.black.applyOpacity(0.5),
                  shape: BoxShape.circle,
                ),
            child: IconButton(
              icon: _backButtonConfig?.icon ??
                  Icon(
                    Icons.arrow_back,
                    color: _backButtonConfig?.iconColor ?? Colors.white,
                    size: _backButtonConfig?.iconSize,
                  ),
              onPressed: () {
                context.pop();
              },
            ),
          ),
          if (showRight) rightWidget,
        ],
      ),
    );
  }

  Widget _buildLazyTabStack() {
    _materializedTabIndices.add(_currentIndex);
    final indices = _materializedTabIndices.toList()..sort();
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in indices)
          Offstage(
            offstage: index != _currentIndex,
            child: TickerMode(
              enabled: index == _currentIndex,
              child: _reelsBodyReady
                  ? _buildTabView(_tabDataModelList[index])
                  : _buildTransitionPlaceholder(),
            ),
          ),
      ],
    );
  }

  Widget _buildTabView(TabStateModel tab) => VisibilityDetector(
        key: Key(
            'reels_tab_${tab.tabDataModel.title}_${tab.tabDataModel.postSectionType.name}_${tab.tabDataModel.tagValue}_${tab.tabDataModel.userId}_${tab.tabDataModel.postId}_'),
        onVisibilityChanged: (VisibilityInfo info) {
          final tabIndex = _tabDataModelList.indexOf(tab);
          if (tabIndex != _currentIndex) {
            tab.isVisible = false;
            return;
          }
          tab.isVisible = info.visibleFraction >= 0.85;
        },
        child: BlocBuilder<SocialPostBloc, SocialPostState>(
            buildWhen: (previousState, currentState) =>
                currentState is SocialPostLoadedState &&
                    currentState.postType == tab.tabDataModel.postSectionType ||
                currentState is PostLoadingState &&
                    currentState.postType == tab.tabDataModel.postSectionType,
            builder: (BuildContext context, SocialPostState state) =>
                ValueListenableBuilder(
                  valueListenable: tab.loadingNotifier,
                  builder: (context, value, child) => value
                      ? _buildInitialLoadingView()
                      : _buildTabBarView(tab, _tabDataModelList.indexOf(tab)),
                )),
      );

  int _timelineListVersion(List<TimeLineData> timeline) {
    if (timeline.isEmpty) return 0;
    return Object.hash(
      timeline.length,
      timeline.first.id,
      timeline.last.id,
      Object.hashAll(
        timeline.map(
          (post) => Object.hash(
            post.id,
            post.isLocked,
            post.lockReason,
            post.media?.length ?? 0,
          ),
        ),
      ),
    );
  }

  List<ReelsData> _mappedReelsForTab(TabStateModel tabState) {
    final section = tabState.tabDataModel.postSectionType;
    final timeline = tabState.tabDataModel.reelsDataList;
    final version = _timelineListVersion(timeline);
    final cachedVersion = _mappedReelsVersionByTab[section];
    if (cachedVersion == version && _mappedReelsByTab.containsKey(section)) {
      return _mappedReelsByTab[section]!;
    }
    final mapped = timeline
        .map((post) => getReelData(post, loggedInUserId: _loggedInUserId))
        .toList();
    _mappedReelsByTab[section] = mapped;
    _mappedReelsVersionByTab[section] = version;
    return mapped;
  }

  void _invalidateMappedReelsCache() {
    _mappedReelsByTab.clear();
    _mappedReelsVersionByTab.clear();
  }

  Widget _buildTabBarView(TabStateModel tabState, int index) {
    Widget buildPostItem() => PostItemWidget(
          key: ValueKey(_getUniqueKey(tabState.tabDataModel, index)),
          videoCacheManager:
              _loggedInUserId.isNotEmpty ? _videoCacheManager : null,
          getEmptyScreen: () => _tabConfig.tabCallBackConfig?.getEmptyScreen
              ?.call(tabState.tabDataModel),
          onTapPlaceHolder: () {
            if ((_postTabController?.length ?? 0) > 1) {
              _tabsVisibilityNotifier.value = true;
              final trendingTabIndex = _tabDataModelList.indexWhere((tabData) =>
                  tabData.tabDataModel.postSectionType ==
                  PostSectionType.trending);
              if (trendingTabIndex != -1) {
                _postTabController?.animateTo(trendingTabIndex);
              }
            }
          },
          loggedInUserId: _loggedInUserId,
          allowImplicitScrolling: widget.allowImplicitScrolling,
          reelsDataList: _mappedReelsForTab(tabState),
          reelsConfig: _getReelsConfig(context, tabState),
          onLoadMore: () async => await _handleLoadMore(tabState),
          onPostFeedLoadMore: () async =>
              await _handlePostFeedLoadMore(tabState),
          onRefresh: () async {
            var result = await _handlePostRefresh(tabState);
            // Increment refresh count to force rebuild
            if (result) {
              setState(() {
                _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
              });
            }
            return result;
          },
          startingPostIndex: tabState.tabDataModel.startingPostIndex,
          postSectionType: tabState.tabDataModel.postSectionType,
          feedLayoutType: tabState.tabDataModel.feedLayoutType,
          postFeedListTopInset:
              tabState.tabDataModel.feedLayoutType == FeedLayoutType.postFeed
                  ? _overlayTabBarContentInset(context)
                  : null,
          postFeedListBottomInset:
              tabState.tabDataModel.feedLayoutType == FeedLayoutType.postFeed
                  ? _postFeedListBottomInset(context)
                  : null,
        );

    return buildPostItem();
  }

  bool _isPostFeedLayout(TabDataModel tabData) =>
      tabData.feedLayoutType == FeedLayoutType.postFeed;

  /// While comment/share sheets are open: block auto-advance to the next clip
  /// or post. Post-feed keeps media playing; full-screen reels also pause.
  void _setOverlayPlaybackGate(
    TabDataModel tabData, {
    required bool allowPlayback,
  }) {
    final isPostFeed = _isPostFeedLayout(tabData);
    _emitScopedPlayPause(
      tabData.postSectionType,
      play: allowPlayback,
      pausePlayback: !isPostFeed,
    );
  }

  EdgeInsetsGeometry _resolvedReelsOverlayPadding(BuildContext context) {
    final overlay = _postConfig.postUIConfig?.overlayPadding;
    final bottom = IsrDimens.resolveOverlayBottomInset(
      context,
      overlay,
      includeHostBottomNav: !widget.isOverlayPlayer,
    );
    if (overlay == null) {
      return EdgeInsets.only(bottom: bottom);
    }
    final resolved = overlay.resolve(Directionality.of(context));
    return EdgeInsets.only(
      left: resolved.left,
      top: resolved.top,
      right: resolved.right,
      bottom: bottom,
    );
  }

  ReelsConfig _getReelsConfig(BuildContext context, TabStateModel tabState) {
    final tabData = tabState.tabDataModel;
    final tabIndex = _tabDataModelList.indexOf(tabState);
    return ReelsConfig(
      postConfig: _postConfig,
      isTabVisible: () {
        if (widget.isOverlayPlayer) return tabState.isVisible;
        if (!IsrVideoReelConfig.isHostFeedTabVisible) return false;
        if (tabIndex == _currentIndex) return true;
        return tabState.isVisible;
      },
      overlayPadding: _resolvedReelsOverlayPadding(context),
      autoMoveNextMedia: _postConfig.autoMoveToNextMedia ||
          _tabConfig.autoMoveToNextPost ||
          _postConfig.autoMoveToNextPost,
      onTapPlace: (reelData, placeList) async {
        if (placeList.isListEmptyOrNull) return;
        if (placeList.length == 1) {
          _goToPlaceDetailsView(
            tabData.postSectionType,
            placeList.first,
            TagType.place,
            reelData.postId ?? '',
          );
        } else {
          // _showPlaceList(placeList, postSectionType);
        }
      },
      onTaggedProduct: (reelsData) async {
        if (reelsData.postData is TimeLineData) {
          _emitScopedPlayPause(tabData.postSectionType, play: false);
          await _postConfig.postCallBackConfig?.onTagProductClick
              ?.call(reelsData.postData as TimeLineData);
          _emitScopedPlayPause(tabData.postSectionType, play: true);
        }
      },
      onTapShare: (reelsData) async {
        if (reelsData.postData is TimeLineData) {
          _setOverlayPlaybackGate(tabData, allowPlayback: false);
          final shareRes = await _postConfig.postCallBackConfig?.onShareClicked
              ?.call(reelsData.postData as TimeLineData);
          _setOverlayPlaybackGate(tabData, allowPlayback: true);
          if (shareRes != null) {
            _socialPostBloc
                .add(OnShareSuccessEvent(shareSuccessData: shareRes));
          }
        }
      },
      onTapMentionTag: (reelData, mentionList) async {
        if (mentionList.isListEmptyOrNull) return [];
        if (mentionList.length == 1) {
          final mention = mentionList.first;
          if (mention.tag.isStringEmptyOrNull == false) {
            _redirectToHashtag(
              mention.tag,
              tabData.postSectionType,
              reelData.postId ?? '',
            );
            return null;
          }
        }
        if (reelData.postData is TimeLineData) {
          _emitScopedPlayPause(tabData.postSectionType, play: false);
          final res = await _showMentionList(
            mentionList,
            reelData.postData as TimeLineData,
          );
          _emitScopedPlayPause(tabData.postSectionType, play: true);
          return res;
        }
        return mentionList;
      },
      onCreatePost: (reelsData) async => await _handleCreatePost(tabData),
      onTapUserProfile: (reelsData) async {
        final postData =
            await _socialActionCubit.getAsyncPostById(reelsData.postId ?? '');
        _postConfig.postCallBackConfig?.onProfileClick?.call(
          postData,
          reelsData.userId ?? '',
          postData?.isFollowing,
        );
        _logProfileEvent(reelsData.userId ?? '', reelsData.userName ?? '');
      },
      onTapComment: (reelsData, totalCommentsCount) async {
        _setOverlayPlaybackGate(tabData, allowPlayback: false);
        try {
          var isUserLoggedIn = await _socialActionCubit.isUserLoggedIn;
          if (!isUserLoggedIn) {
            await _socialConfig.socialCallBackConfig?.onLoginInvoked?.call();
          }
          isUserLoggedIn = await _socialActionCubit.isUserLoggedIn;
          if (!isUserLoggedIn) return totalCommentsCount;
          final result = await _handleCommentAction(
            reelsData.postId ?? '',
            totalCommentsCount,
            tabData,
            reelsData.postData is TimeLineData
                ? reelsData.postData as TimeLineData
                : null,
          );
          return result;
        } finally {
          _setOverlayPlaybackGate(tabData, allowPlayback: true);
        }
      },
      onPressMoreButton: (reelsData) async {
        if (reelsData.postData is TimeLineData) {
          _emitScopedPlayPause(tabData.postSectionType, play: false);
          final sheetResult = await _handleMoreOptions(
            reelsData.postData as TimeLineData,
            tabData,
          );
          if (sheetResult == MoreOptionsSheetResult.dubWithAudio) {
            await DubWithAudioCaptureCoordinator.handleFromPost(
              context,
              reelsData.postData as TimeLineData,
              config: _postConfig.dubWithAudioConfig,
              customHandler: _postConfig.postCallBackConfig?.onDubWithAudio,
            );
            _emitScopedPlayPause(tabData.postSectionType, play: true);
            IsrVideoReelConfig.resumePlaybackIfAllowed();
          } else if (sheetResult == MoreOptionsSheetResult.download) {
            await _downloadPost(reelsData.postData as TimeLineData);
            _emitScopedPlayPause(tabData.postSectionType, play: true);
          } else {
            _emitScopedPlayPause(tabData.postSectionType, play: true);
          }
        }
      },
      onPressLike: _postConfig.postCallBackConfig?.onLikeClick == null
          ? null
          : (reelsData, isLiked) async {
              _emitScopedPlayPause(tabData.postSectionType, play: false);
              final postData = reelsData.postData is TimeLineData
                  ? reelsData.postData as TimeLineData
                  : null;
              final result = await _postConfig.postCallBackConfig?.onLikeClick
                  ?.call(postData, isLiked);
              _emitScopedPlayPause(tabData.postSectionType, play: true);
              return result ?? false;
            },
      onPressSave: (reelsData, currentSaved) async {
        if (_postConfig.postCallBackConfig?.onSaveClicked == null) {
          _emitScopedPlayPause(tabData.postSectionType, play: false);
          final res = await _handleCollection(reelsData, currentSaved);
          _emitScopedPlayPause(tabData.postSectionType, play: true);
          return res;
        } else {
          _emitScopedPlayPause(tabData.postSectionType, play: false);
          final postData = reelsData.postData is TimeLineData
              ? reelsData.postData as TimeLineData
              : null;
          final result = await _postConfig.postCallBackConfig?.onSaveClicked
              ?.call(postData, currentSaved);
          _emitScopedPlayPause(tabData.postSectionType, play: true);
          return result ?? false;
        }
      },
      onPressFollow: _postConfig.postCallBackConfig?.onFollowClick == null
          ? null
          : (reelsData, isFollowed) async {
              _emitScopedPlayPause(tabData.postSectionType, play: false);
              final postData = reelsData.postData is TimeLineData
                  ? reelsData.postData as TimeLineData
                  : null;
              final result = await _postConfig.postCallBackConfig?.onFollowClick
                  ?.call(postData, isFollowed);
              _emitScopedPlayPause(tabData.postSectionType, play: true);
              return result ?? false;
            },
    );
  }

  void _goToPlaceDetailsView(
    PostSectionType postSectionType,
    PlaceMetaData placeMetaData,
    TagType place,
    String postId,
  ) async {
    var lat = 0.0;
    var long = 0.0;
    if ((placeMetaData.coordinates?.length ?? 0) > 1) {
      lat = placeMetaData.coordinates?.first ?? 0;
      long = placeMetaData.coordinates?[1] ?? 0;
    }

    // Use callback if provided (allows custom behavior)
    if (widget.onTapPlace != null) {
      widget.onTapPlace!(
        placeMetaData.placeId ?? '',
        placeMetaData.placeName,
        lat,
        long,
      );
      return;
    }

    // ✅ Default: SDK handles navigation using Navigator with BLoC provider
    try {
      IsrAppNavigator.navigateToPlaceDetails(
        context,
        placeId: placeMetaData.placeId ?? '',
        placeName: placeMetaData.placeName,
        latitude: lat,
        longitude: long,
      );
    } catch (e) {
      debugPrint('Navigation failed: $e');
    }
  }

  /// Handles loading more posts for infinite scrolling
  Future<List<ReelsData>> _handleLoadMore(TabStateModel tabState) async {
    final result = await _handlePostFeedLoadMore(tabState);
    return result.items;
  }

  Future<PostFeedLoadMoreResult> _handlePostFeedLoadMore(
    TabStateModel tabState,
  ) async {
    try {
      final section = tabState.tabDataModel.postSectionType;
      final completer = Completer<List<TimeLineData>>();
      _socialPostBloc.add(GetMorePostEvent(
        isLoading: false,
        isPagination: true,
        isRefresh: false,
        postSectionType: section,
        memberUserId: '',
        onComplete: (value) async {
          final newReels = value.where((newReel) => !tabState
              .tabDataModel.reelsDataList
              .any((existingReel) => existingReel.id == newReel.id));
          tabState.tabDataModel.reelsDataList.addAll(newReels);
          _mappedReelsByTab.remove(section);
          _mappedReelsVersionByTab.remove(section);
          completer.complete(newReels.toList());
        },
      ));
      final timeLinePostList = await completer.future;
      final hasMore = _socialPostBloc.hasMorePagesForTab(section);
      if (timeLinePostList.isEmpty) {
        return PostFeedLoadMoreResult(items: const [], hasMore: hasMore);
      }
      final timeLineReelDataList = timeLinePostList
          .map((post) => getReelData(post, loggedInUserId: _loggedInUserId))
          .toList();
      return PostFeedLoadMoreResult(
        items: timeLineReelDataList,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('Error handling load more: $e');
      return const PostFeedLoadMoreResult(items: [], hasMore: false);
    }
  }

  // Interaction handlers
  Future<ReelsData?> _handleCreatePost(TabDataModel tabData) async {
    final completer = Completer<ReelsData>();
    final postDataModelString =
        await IsrAppNavigator.goToCreatePostView(context);
    if (postDataModelString.isStringEmptyOrNull == false) {
      final postDataModel = TimeLineData.fromMap(
          jsonDecode(postDataModelString!) as Map<String, dynamic>);
      final reelsData =
          getReelData(postDataModel, loggedInUserId: _loggedInUserId);
      completer.complete(reelsData);
    }
    return completer.future;
  }

  /// Top padding for post-card lists when the reels tab bar overlays the feed.
  double _overlayTabBarContentInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top +
      IsrDimens.twenty +
      kTextTabBarHeight +
      IsrDimens.sixteen;

  /// Bottom padding so the last post clears a host bottom navigation bar.
  double _postFeedListBottomInset(BuildContext context) =>
      IsrDimens.resolveOverlayBottomInset(
        context,
        _postConfig.postUIConfig?.overlayPadding,
        includeHostBottomNav: !widget.isOverlayPlayer,
      );

  Widget _buildTabBar() {
    final feedUi = _postConfig.resolvedPostFeedUIConfig;
    final usePostFeedChrome = _isCurrentTabPostFeed;

    return ValueListenableBuilder<bool>(
        valueListenable: _tabsVisibilityNotifier,
        builder: (context, value, child) => value == true
            ? Container(
                decoration: BoxDecoration(
                  color: usePostFeedChrome ? feedUi.backgroundColor : null,
                  gradient: usePostFeedChrome
                      ? null
                      : (_tabBarConfig?.containerGradient ??
                          LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.changeOpacity(0.6),
                              Colors.black.changeOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          )),
                ),
                padding: _tabBarConfig?.containerPadding ??
                    EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top +
                            IsrDimens.twenty,
                        bottom: IsrDimens.sixteen),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Left widget (e.g., back button, logo)
                    if (_tabBarConfig?.leftWidget != null)
                      _tabBarConfig!.leftWidget!,
                    // Tab bar
                    Expanded(
                      child: Theme(
                        data: ThemeData(
                          splashColor:
                              _tabBarConfig?.splashColor ?? Colors.transparent,
                          highlightColor: _tabBarConfig?.highlightColor ??
                              Colors.transparent,
                        ),
                        child: TabBar(
                          controller: _postTabController,
                          isScrollable: _tabBarConfig?.isScrollable ?? true,
                          tabAlignment:
                              _tabBarConfig?.tabAlignment ?? TabAlignment.start,
                          labelColor: _tabBarConfig?.labelColor ??
                              (usePostFeedChrome
                                  ? feedUi.headerTextColor
                                  : IsrColors.white),
                          unselectedLabelColor:
                              _tabBarConfig?.unselectedLabelColor ??
                                  (usePostFeedChrome
                                      ? feedUi.secondaryTextColor
                                      : IsrColors.white.changeOpacity(0.7)),
                          indicatorColor: _tabBarConfig?.indicatorColor ??
                              (usePostFeedChrome
                                  ? feedUi.headerTextColor
                                  : IsrColors.white),
                          indicatorWeight: _tabBarConfig?.indicatorWeight ?? 3,
                          dividerColor:
                              _tabBarConfig?.dividerColor ?? Colors.transparent,
                          indicatorSize: _tabBarConfig?.indicatorSize ??
                              TabBarIndicatorSize.label,
                          padding: _tabBarConfig?.tabPadding ??
                              IsrDimens.edgeInsetsSymmetric(
                                  horizontal: IsrDimens.sixteen),
                          labelPadding: _tabBarConfig?.labelPadding ??
                              IsrDimens.edgeInsetsSymmetric(
                                  horizontal: IsrDimens.eight),
                          labelStyle: _tabBarConfig?.labelStyle ??
                              (usePostFeedChrome
                                  ? IsrStyles.primaryText16.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: feedUi.headerTextColor,
                                    )
                                  : IsrStyles.white16.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                      shadows: [
                                        Shadow(
                                          color:
                                              Colors.black.changeOpacity(0.8),
                                          offset: const Offset(0, 1),
                                          blurRadius: 4,
                                        ),
                                        Shadow(
                                          color:
                                              Colors.black.changeOpacity(0.5),
                                          offset: const Offset(0, 2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    )),
                          unselectedLabelStyle: _tabBarConfig
                                  ?.unselectedLabelStyle ??
                              (usePostFeedChrome
                                  ? IsrStyles.primaryText16.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: feedUi.secondaryTextColor,
                                    )
                                  : IsrStyles.white16.copyWith(
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                      shadows: [
                                        Shadow(
                                          color:
                                              Colors.black.changeOpacity(0.8),
                                          offset: const Offset(0, 1),
                                          blurRadius: 4,
                                        ),
                                        Shadow(
                                          color:
                                              Colors.black.changeOpacity(0.5),
                                          offset: const Offset(0, 2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    )),
                          tabs: _tabDataModelList
                              .map(
                                (tab) => Tab(
                                  child: Text(
                                    tab.tabDataModel.title,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    // Right widget (e.g., search icon, menu icon)
                    if (_tabBarConfig?.rightWidget != null)
                      _tabBarConfig!.rightWidget!,
                  ],
                ),
              )
            : const SizedBox.shrink());
  }

  @override
  void dispose() {
    if (!widget.isOverlayPlayer &&
        IsrVideoReelConfig.onHostFeedTabResumed == _onHostFeedTabResumed) {
      IsrVideoReelConfig.onHostFeedTabResumed = null;
      IsrVideoReelConfig.getActiveHostPostSection = null;
    }
    IsrVideoReelConfig.unregisterAppForegroundResumedListener(
      _onAppForegroundResumed,
    );
    _tearDownRouteEnterListener();
    _postTabController?.dispose();
    _centralTadData.remove(centralKey);
    for (var controller in _refreshControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  final Map<int, int> _refreshCounts = {};

  String _getUniqueKey(TabDataModel tabData, int index) {
    _refreshCounts[index] ??= 0;
    // Do not key on list length — pagination appends rows and remounting
    // [PostItemWidget] resets scroll / page index back to the first post.
    return '${tabData.postSectionType.name}_${_refreshCounts[index]}';
  }

  bool _isFollowingPostsEmpty() {
    final isFollowingPostEmpty = widget.tabDataModelList.length > 1 &&
        widget.tabDataModelList[0].postSectionType ==
            PostSectionType.following &&
        widget.tabDataModelList[0].reelsDataList.isListEmptyOrNull;
    return isFollowingPostEmpty;
  }

  Future<int> _handleCommentAction(
    String postId,
    int totalCommentsCount,
    TabDataModel tabData,
    TimeLineData? postData, {
    String? highlightCommentId,
  }) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(sheetContext),
              child: const ColoredBox(color: Color(0x99000000)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: _socialPostBloc),
                BlocProvider.value(
                    value: context.getOrCreateBloc<CommentActionCubit>()),
                BlocProvider.value(
                    value: context.getOrCreateBloc<SearchUserBloc>()),
              ],
              child: CommentsBottomSheet(
                postId: postId,
                highlightCommentId: highlightCommentId,
                onTapProfile: (userId) {
                  _postConfig.postCallBackConfig?.onProfileClick
                      ?.call(postData, userId, null);
                  _logProfileEvent(userId, postData?.user?.username ?? '');
                },
                onTapHasTag: (hashTag) {
                  _redirectToHashtag(hashTag, tabData.postSectionType, postId);
                },
                postData: postData,
                tabData: tabData,
              ),
            ),
          ),
        ],
      ),
    );
    final updatedCount = totalCommentsCount + (result ?? 0);
    return updatedCount < 0 ? 0 : updatedCount;
  }

  void _redirectToHashtag(
    String? tag,
    PostSectionType postSectionType,
    String postId,
  ) {
    _logHashtagEvent(tag ?? '');
    _goToPostListingView(postSectionType, tag ?? '', TagType.hashtag, postId);
  }

  void _goToPostListingView(
    PostSectionType postTabType,
    String tagValue,
    TagType tagType,
    String postId,
  ) async {
    // ✅ Navigation now works because we wrap PostListingView with BlocProvider during navigation
    IsrAppNavigator.navigateToPostListing(
      context,
      tagValue: tagValue,
      tagType: tagType,
    );
  }

  Future<List<MentionMetaData>> _showMentionList(
    List<MentionMetaData> mentionList,
    TimeLineData postData,
  ) async {
    final userid = await _socialPostBloc.userId;
    final updatedMentionList =
        await Utility.showBottomSheet<List<MentionMetaData>>(
      isScrollControlled: true,
      child: MentionListBottomSheet(
        initialMentionList: mentionList,
        postData: postData,
        myUserId: userid,
        onMentionRemoved: () {
          _stripSelfMentionFromTimelinePost(postData.id ?? '');
        },
        onTapUserProfile: (userId, isFollowing) {
          context.pop();
          _postConfig.postCallBackConfig?.onProfileClick
              ?.call(postData, userId, isFollowing);
          _logProfileEvent(userId, postData.user?.username ?? '');
        },
      ),
    );
    return updatedMentionList ?? mentionList;
  }

  /// Solid backdrop only — no shimmer/listeners — during the route transition.
  Widget _buildTransitionPlaceholder() => ColoredBox(
        color: _loadingViewConfig?.backgroundColor ?? Colors.black,
        child: const SizedBox.expand(),
      );

  /// Builds the initial loading view to prevent background flicker during navigation
  Widget _buildInitialLoadingView() => Container(
        width: double.infinity,
        height: double.infinity,
        color: _loadingViewConfig?.backgroundColor ?? Colors.black,
        child: Center(
          child: _loadingViewConfig?.loadingWidget ?? const PostShimmerView(),
        ),
      );

  /// Handles refresh for user posts
  Future<bool> _handlePostRefresh(TabStateModel tabState) async {
    final completer = Completer<bool>();
    tabState.isLoading = true;
    _socialPostBloc.add(GetMorePostEvent(
      isLoading: false,
      isPagination: false,
      isRefresh: true,
      postSectionType: tabState.tabDataModel.postSectionType,
      memberUserId: '',
      onComplete: (postDataList) async {
        tabState.tabDataModel.reelsDataList
          ..clear()
          ..addAll(postDataList);
        tabState.isLoading = false;
        completer.complete(true);
      },
    ));
    return await completer.future;
  }

  bool _shouldOfferDownload(TimeLineData post) =>
      ReelDownloadUtil.isPostDownloadAllowed(
        postConfig: _postConfig,
        post: post,
      );

  Future<void> _downloadPost(TimeLineData post) async {
    if (!ReelDownloadUtil.isPostDownloadAllowed(
      postConfig: _postConfig,
      post: post,
    )) {
      Utility.showToastMessage(IsrTranslationFile.downloadNotAllowed);
      return;
    }
    Utility.showToastMessage(IsrTranslationFile.downloading);
    final outcome = await ReelDownloadUtil.downloadPostMedia(post);
    if (!mounted) return;
    switch (outcome) {
      case ReelDownloadOutcome.saved:
        Utility.showToastMessage(IsrTranslationFile.downloadSavedToGallery);
      case ReelDownloadOutcome.permissionDenied:
        Utility.showToastMessage(IsrTranslationFile.downloadPermissionDenied);
      case ReelDownloadOutcome.failed:
        Utility.showToastMessage(IsrTranslationFile.downloadFailed);
    }
  }

  bool _shouldOfferDubWithAudio(TimeLineData post) {
    if (!_postConfig.enableDubWithAudio) return false;
    if (post.user?.id == _loggedInUserId) return false;
    final media = post.media;
    if (media == null || media.isEmpty) return false;
    return media.any(
      (m) =>
          m.postType == PostType.video ||
          (m.mediaType?.toLowerCase().contains('video') ?? false),
    );
  }

  bool _isCurrentUserMentioned(TimeLineData post) {
    if (_loggedInUserId.isEmpty) return false;
    final mentions = post.tags?.mentions;
    if (mentions == null || mentions.isEmpty) return false;
    return mentions.any((m) => m.userId == _loggedInUserId);
  }

  void _stripSelfMentionFromTimelinePost(String postId) {
    for (final tabData in _tabDataModelList) {
      for (final post in tabData.tabDataModel.reelsDataList) {
        if (post.id != postId) continue;
        post.tags?.mentions?.removeWhere((m) => m.userId == _loggedInUserId);
        return;
      }
    }
  }

  Future<bool> _executeRemoveMentionFromPost({
    required String postId,
  }) async {
    final confirmed = await Utility.showRemoveMeFromPostConfirmDialog(context);
    if (confirmed != true) return false;

    final completer = Completer<bool>();
    _socialPostBloc.add(
      RemoveMentionEvent(
        postId: postId,
        onComplete: (success) {
          if (success) {
            Utility.showToastMessage(
              IsrTranslationFile.mentionRemovedSuccessfully,
            );
          }
          if (!completer.isCompleted) {
            completer.complete(success);
          }
        },
      ),
    );
    return completer.future;
  }

  /// Handles the more options menu for a post
  Future<dynamic> _handleMoreOptions(
      TimeLineData postDataModel, TabDataModel tabData) async {
    try {
      final isOwner = postDataModel.user?.id == _loggedInUserId;
      return await _showMoreOptionsDialog(
        tabData: tabData,
        showDubWithAudio: _shouldOfferDubWithAudio(postDataModel),
        showDownload: _shouldOfferDownload(postDataModel),
        showRemoveMeFromPost:
            !isOwner && _isCurrentUserMentioned(postDataModel),
        onRemoveMeFromPost: () async {
          await _executeRemoveMentionFromPost(
            postId: postDataModel.id ?? '',
          );
        },
        onReportPost: () async {
          final completer = Completer<dynamic>();
          final result = await showDialog<dynamic>(
            context: context,
            builder: (_) => ReportReasonDialog(
              reasonFor: ReasonsFor.socialPost,
              contentId: postDataModel.id ?? '',
              showToastOnSuccess: false,
              onReportInvoked: (reason) {
                completer.complete(true);
              },
              onReportCanceled: (reason) {
                completer.complete(false);
              },
              onReportSuccess: (reason) {
                Utility.showInSnackBar(
                    IsrTranslationFile.postReportedSuccessfully, context,
                    isSuccessIcon: true);
                _logReportEvent(postDataModel, reason.name ?? '', tabData);
              },
            ),
          );
          if (!completer.isCompleted && result != true) {
            completer.complete(result);
          }
          return completer.future;
        },
        onDeletePost: () async {
          final result = await _showDeletePostDialog(context);
          if (result == true) {
            _socialPostBloc.add(
              DeletePostEvent(
                postId: postDataModel.id ?? '',
                onComplete: (success) {
                  if (success) {
                    Utility.showToastMessage(
                        IsrTranslationFile.postDeletedSuccessfully);
                  }
                },
              ),
            );
          }
        },
        isSelfProfile: isOwner,
        onEditPost: () async {
          unawaited(_handleEditPost(postDataModel));
        },
        onShowPostInsight: () async {
          IsrAppNavigator.goToPostInsight(context,
              postId: postDataModel.id ?? '', postData: postDataModel);
        },
        onDownloadPost: () async {
          await _downloadPost(postDataModel);
        },
      );
    } catch (e) {
      debugPrint('Error handling more options: $e');
      return false;
    }
  }

  void _onUserChanged(String userId) {
    var updateState = false;
    debugPrint('ism_post_view: user changed: $userId');
    //data update
    _invalidateMappedReelsCache();
    if (userId.isNotEmpty && _loggedInUserId != userId) {
      _videoCacheManager = VideoCacheManager();
    } else if (userId.isEmpty && _loggedInUserId.isNotEmpty) {
      _videoCacheManager?.clearCache();
      _videoCacheManager = null;
    }
    _loggedInUserId = userId;
    for (var tabData in _tabDataModelList) {
      if (tabData.tabDataModel.postSectionType.isUserDependent) {
        tabData.tabDataModel.reelsDataList.clear();
        tabData.isLoading = true;
        if (userId.isNotEmpty) {
          _requestHomeTabLoad(tabData);
        } else {
          tabData.isLoading = false;
        }
        updateState = true;
        debugPrint(
            'ism_post_view: user changed: $userId, reels cleared ${tabData.tabDataModel.title} ');
      }
    }

    if (mounted) {
      debugPrint('ism_post_view: user changed: $userId, ui updatable ');
      // Ui update
      if (_currentPostSectionType.isUserDependent) {
        var index = _tabDataModelList.indexWhere(
            (tab) => !tab.tabDataModel.postSectionType.isUserDependent);
        if (index >= 0) {
          // Store the new index
          _currentIndex = index;
          _currentPostSectionType =
              _tabDataModelList[index].tabDataModel.postSectionType;

          // Use post-frame callback to ensure tab change happens when widget is visible
          // This handles the case when the page is in background
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _postTabController != null) {
              // Check if controller is still attached and index is valid
              if (_postTabController!.index != index &&
                  index >= 0 &&
                  index < _postTabController!.length) {
                _postTabController!.animateTo(index);
                debugPrint(
                    'ism_post_view: user changed: $userId, tab changed to ${_tabDataModelList[index].tabDataModel.title}');
              }
            }
          });
        }
      }
      if (updateState) {
        setState(() {
          debugPrint('ism_post_view: user changed: $userId, state update');
        });
      }
    }
  }

  void _removePostFromList(String postId) {
    for (var tabData in _tabDataModelList) {
      tabData.tabDataModel.reelsDataList
          .removeWhere((element) => element.id == postId);
    }
    if (_tabConfig.exitOnEmptyReelsAfterModification) {
      final isAllTabsEmpty = !_tabDataModelList
          .any((tab) => tab.tabDataModel.reelsDataList.isNotEmpty);
      if (isAllTabsEmpty && mounted && context.canPop()) {
        context.pop();
      }
    }
  }

  void _replacePostFromList(TimeLineData postData) {
    for (var tabData in _tabDataModelList) {
      final index = tabData.tabDataModel.reelsDataList.indexWhere(
        (element) => element.id == postData.id,
      );

      if (index != -1) {
        tabData.tabDataModel.reelsDataList[index] = postData; // replace
      }
    }
    _invalidateMappedReelsCache();
  }

  // Additional handlers for likes, follows, etc.
  // ... (implement other handlers similarly)
  Future<String?> _showMoreOptionsDialog({
    Future<dynamic> Function()? onReportPost,
    bool showDubWithAudio = false,
    bool showDownload = false,
    bool showRemoveMeFromPost = false,
    Future<void> Function()? onRemoveMeFromPost,
    Future<dynamic> Function()? onDeletePost,
    Future<dynamic> Function()? onEditPost,
    Future<dynamic> Function()? onShowPostInsight,
    Future<void> Function()? onDownloadPost,
    bool? isSelfProfile,
    required TabDataModel tabData,
  }) async {
    final sheetResult = await Utility.showBottomSheet<String?>(
      isDismissible: true,
      child: MoreOptionsBottomSheet(
        showDubWithAudio: showDubWithAudio,
        showDownload: showDownload,
        showRemoveMeFromPost: showRemoveMeFromPost,
        isSelfProfile: isSelfProfile == true,
      ),
    );

    switch (sheetResult) {
      case MoreOptionsSheetResult.dubWithAudio:
        return sheetResult;
      case MoreOptionsSheetResult.removeMeFromPost:
        if (onRemoveMeFromPost != null) {
          await onRemoveMeFromPost();
        }
        return null;
      case MoreOptionsSheetResult.report:
        if (onReportPost != null) {
          await onReportPost();
        }
        return null;
      case MoreOptionsSheetResult.delete:
        if (onDeletePost != null) {
          await onDeletePost();
        }
        return null;
      case MoreOptionsSheetResult.edit:
        if (onEditPost != null) {
          await onEditPost();
        }
        return null;
      case MoreOptionsSheetResult.insight:
        if (onShowPostInsight != null) {
          await onShowPostInsight();
        }
        return null;
      case MoreOptionsSheetResult.download:
        if (onDownloadPost != null) {
          await onDownloadPost();
        }
        return null;
      default:
        return null;
    }
  }

  Future<bool?> _showDeletePostDialog(BuildContext context) {
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final borderRadius = dialogConfig?.borderRadius ?? 20.0;
    final backgroundColor = dialogConfig?.backgroundColor ?? Colors.white;
    final padding = dialogConfig?.padding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 28);
    final titleStyle = dialogConfig?.titleTextStyle ??
        IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w700);
    final messageStyle = dialogConfig?.messageTextStyle ??
        IsrStyles.primaryText14.copyWith(color: '4A4A4A'.toColor());

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        backgroundColor: backgroundColor,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                IsrTranslationFile.deletePost,
                style: titleStyle,
              ),
              16.responsiveVerticalSpace,
              Text(
                IsrTranslationFile.deletePostConfirmation,
                style: messageStyle,
              ),
              32.responsiveVerticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDialogButton(
                    context: context,
                    title: IsrTranslationFile.delete,
                    buttonConfig: IsrVideoReelConfig.socialConfig.primaryButton,
                    onPress: () => Navigator.of(context).pop(true),
                    defaultBackgroundColor: 'E04755'.toColor(),
                  ),
                  _buildDialogButton(
                    context: context,
                    title: IsrTranslationFile.cancel,
                    buttonConfig:
                        IsrVideoReelConfig.socialConfig.secondaryButton,
                    buttonType: ButtonType.secondary,
                    onPress: () => Navigator.of(context).pop(false),
                    defaultBackgroundColor: 'F6F6F6'.toColor(),
                    defaultTextColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required BuildContext context,
    required String title,
    ButtonConfig? buttonConfig,
    ButtonType buttonType = ButtonType.primary,
    required VoidCallback? onPress,
    Color? defaultBackgroundColor,
    Color? defaultTextColor,
  }) =>
      AppButton(
        title: title,
        width: 102.responsiveDimension,
        type: buttonType,
        onPress: onPress,
        backgroundColor:
            buttonConfig?.backgroundColor ?? defaultBackgroundColor,
        textColor: buttonConfig?.textColor ?? defaultTextColor,
        borderColor: buttonConfig?.borderColor,
        borderRadius: buttonConfig?.borderRadius,
      );

  Future<String?> _handleEditPost(TimeLineData postDataModel) async {
    final postDataString = await IsrAppNavigator.goToEditPostView(context,
        postData: postDataModel);
    return postDataString;
  }

  void _logReportEvent(TimeLineData postDataModel, String reportReason,
      TabDataModel tabDataModel) async {
    final postReportEvent = {
      'post_id': postDataModel.id ?? '',
      'post_type': postDataModel.media?.first.mediaType,
      'post_author_id': postDataModel.userId ?? '',
      'feed_type': tabDataModel.postSectionType.title,
      'interests': postDataModel.interests ?? [],
      'hashtags': postDataModel.tags?.hashtags?.map((e) => '#$e').toList(),
      'report_reason': reportReason
    };

    EventQueueProvider.instance.logEvent(
        EventType.postReported.value, postReportEvent.removeEmptyValues());
  }

  void _logProfileEvent(String profileUserId, String profileUserName) {
    final profileEvent = {
      'profile_user_id': profileUserId,
      'profile_username': profileUserName,
    };

    EventQueueProvider.instance.logEvent(
        EventType.profileViewed.value, profileEvent.removeEmptyValues());
  }

  void _logHashtagEvent(String hashTag) {
    final hashTagEventMap = {'hashtag': hashTag};
    EventQueueProvider.instance.logEvent(
        EventType.hashTagClicked.value, hashTagEventMap.removeEmptyValues());
  }

  Future<bool> _handleCollection(ReelsData reelsData, bool isSavedPost) async {
    final postData = reelsData.postData as TimeLineData;
    var coverUrl = '';
    if (postData.previews.isEmptyOrNull == false) {
      final previewUrl = postData.previews?.first.url ?? '';
      if (previewUrl.isEmptyOrNull == false) {
        coverUrl = previewUrl;
      }
    }
    if (coverUrl.isEmptyOrNull && postData.media.isEmptyOrNull == false) {
      coverUrl = postData.media?.first.mediaType?.mediaType == MediaType.video
          ? (postData.media?.first.previewUrl.toString() ?? '')
          : postData.media?.first.url.toString() ?? '';
    }
    final updatedSaveStatus = await Utility.showBottomSheet(
      child: BlocProvider<CollectionBloc>.value(
        value: IsmInjectionUtils.getBloc<CollectionBloc>(),
        child: CollectionBottomSheetWidget(
          postId: reelsData.postId ?? '',
          isFromPost: true,
          isSaved: isSavedPost,
          thumbnailUrl: coverUrl,
        ),
      ),
      isScrollControlled: false,
      isDismissible: true,
    );
    return updatedSaveStatus != isSavedPost;
  }
}
