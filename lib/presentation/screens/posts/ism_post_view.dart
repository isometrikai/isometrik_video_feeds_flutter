import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;

class IsmPostView extends StatefulWidget {
  const IsmPostView({
    super.key,
    required this.tabDataModelList,
    this.startTabIndex = 0,
    this.allowImplicitScrolling = false,
    this.onTapPlace,
    this.tabConfig,
    this.postConfig,
  });

  final List<TabDataModel> tabDataModelList;
  final num? startTabIndex;
  final bool? allowImplicitScrolling;
  final TabConfig? tabConfig;
  final PostConfig? postConfig;

  /// Optional callback to override default place navigation
  /// If not provided, SDK will navigate to PlaceDetailsView automatically
  /// Parameters: placeId, placeName, latitude, longitude
  final Function(String placeId, String placeName, double lat, double long)?
      onTapPlace;

  @override
  State<IsmPostView> createState() => _PostViewState();
}

class _PostViewState extends State<IsmPostView> with TickerProviderStateMixin {
  TabController? _postTabController;
  late List<RefreshController> _refreshControllers;
  var _currentIndex = 1;
  var _loggedInUserId = '';
  final ValueNotifier<bool> _tabsVisibilityNotifier = ValueNotifier<bool>(true);
  List<TabStateModel> _tabDataModelList = [];
  VideoCacheManager? _videoCacheManager;
  late SocialPostBloc _socialPostBloc; // Will be initialized from context
  late IsmSocialActionCubit _socialActionCubit;
  var _currentPostSectionType = PostSectionType.forYou;
  PostConfig get _postConfig =>
      widget.postConfig ?? IsrVideoReelConfig.postConfig;
  TabConfig get _tabConfig => widget.tabConfig ?? IsrVideoReelConfig.tabConfig;
  SocialConfig get _socialConfig => IsrVideoReelConfig.socialConfig;

  // Tab config helper getters
  TabUIConfig? get _tabUIConfig => _tabConfig.tabUIConfig;
  TabBarConfig? get _tabBarConfig => _tabUIConfig?.tabBarConfig;
  BackButtonConfig? get _backButtonConfig => _tabUIConfig?.backButtonConfig;
  LoadingViewConfig? get _loadingViewConfig => _tabUIConfig?.loadingViewConfig;
  StatusBarConfig? get _statusBarConfig => _tabUIConfig?.statusBarConfig;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the BuildContext for SDK use
    IsrVideoReelConfig.buildContext = context;
  }

  void _onStartInit() async {
    _tabDataModelList = widget.tabDataModelList
        .map((tab) => TabStateModel(
            isLoading: tab.reelsDataList.isEmpty, tabDataModel: tab))
        .toList();
    _currentIndex = widget.startTabIndex?.toInt() ?? 0;
    _currentPostSectionType =
        _tabDataModelList[_currentIndex].tabDataModel.postSectionType;
    if (_currentIndex >= _tabDataModelList.length) {
      _currentIndex = 0;
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
    _socialPostBloc = context.getOrCreateBloc();
    if (_socialPostBloc.isClosed) {
      isrConfigureInjection();
      _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
    }
    _socialActionCubit = context.getOrCreateBloc();

    _tabsVisibilityNotifier.value = _tabDataModelList.length > 1;

    if (_isFollowingPostsEmpty()) {
      // _tabsVisibilityNotifier.value = false;
    }
    _loggedInUserId = await _socialPostBloc.userId;
    _postTabController?.addListener(() async {
      if (!mounted) return;
      final newIndex = _postTabController?.index ?? 0;
      final lastIndex = _currentIndex;
      if (_currentIndex != newIndex) {
        _currentIndex = newIndex;
        final tabData = _tabDataModelList[newIndex];
        if (tabData.tabDataModel.postSectionType.isUserDependent) {
          var isUserLoggedIn = await _socialPostBloc.isUserLoggedIn;
          if (!isUserLoggedIn) {
            await _socialConfig.socialCallBackConfig?.onLoginInvoked?.call();
            isUserLoggedIn = await _socialPostBloc.isUserLoggedIn;
          }
          if (!isUserLoggedIn) {
            _currentIndex = lastIndex;
            _postTabController?.animateTo(_currentIndex);
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
        setState(() {});
        if (tabData.tabDataModel.reelsDataList.isEmpty && !tabData.isLoading) {
          final result = await _handlePostRefresh(tabData);
          if (result) {
            setState(() {});
          }
        }
      }
    });
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

  // ✅ Provide BLoCs at the root of build
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: _getAllBlocProviders(),
        child: _buildContent(),
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
          statusBarColor:
              _statusBarConfig?.statusBarColor ?? IsrColors.transparent,
          statusBarBrightness:
              _statusBarConfig?.statusBarBrightness ?? Brightness.dark,
          statusBarIconBrightness:
              _statusBarConfig?.statusBarIconBrightness ?? Brightness.light,
        ),
        child: context.attachBlocIfNeeded<IsmSocialActionCubit>(
          bloc: _socialActionCubit,
          child: BlocListener<IsmSocialActionCubit, IsmSocialActionState>(
            listenWhen: (previousState, currentState) =>
                currentState is IsmDeletedPostActionListenerState ||
                currentState is IsmEditPostActionListenerState ||
                currentState is IsmUserChangedActionListenerState,
            listener: (context, state) {
              // Do Not setState to prevent reels to start from first
              // this is only to update data to update ui it is done in post_item_widget
              if (state is IsmDeletedPostActionListenerState &&
                  state.postId?.isNotEmpty == true) {
                _removePostFromList(state.postId!);
              } else if (state is IsmEditPostActionListenerState &&
                  state.postData != null) {
                _replacePostFromList(state.postData!);
              } else if (state is IsmUserChangedActionListenerState) {
                _onUserChanged(state.userId);
              }
            },
            child: Stack(
              children: [
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
                      tabStateData?.tabDataModel.reelsDataList =
                          state.postList.toList();
                      tabStateData?.isLoading = false;
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
                    child: TabBarView(
                      controller: _postTabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _tabDataModelList.map(_buildTabView).toList(),
                    ),
                  ),
                ),
                if (_tabDataModelList.length > 1) ...[
                  _buildTabBar()
                ] else ...[
                  _buildBackButton()
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildBackButton() => Positioned(
        top: MediaQuery.of(context).padding.top +
            (_backButtonConfig?.topOffset ?? 10),
        left: (_backButtonConfig?.leftOffset ?? 16.0).responsiveDimension,
        child: Container(
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
      );

  Widget _buildTabView(TabStateModel tab) =>
      BlocBuilder<SocialPostBloc, SocialPostState>(
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
              ));

  Widget _buildTabBarView(TabStateModel tabState, int index) => PostItemWidget(
        key: ValueKey(_getUniqueKey(tabState.tabDataModel, index)),
        videoCacheManager:
            _loggedInUserId.isNotEmpty ? _videoCacheManager : null,
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
        reelsDataList: tabState.tabDataModel.reelsDataList
            .map((_) => getReelData(_, loggedInUserId: _loggedInUserId))
            .toList(),
        reelsConfig: _getReelsConfig(tabState.tabDataModel),
        onLoadMore: () async => await _handleLoadMore(tabState.tabDataModel),
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
      );

  ReelsConfig _getReelsConfig(TabDataModel tabData) => ReelsConfig(
      postConfig: _postConfig,
      overlayPadding: _postConfig.postUIConfig?.overlayPadding,
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
          _socialPostBloc.add(PlayPauseVideoEvent(play: false));
          await _postConfig.postCallBackConfig?.onTagProductClick
              ?.call(reelsData.postData as TimeLineData);
          _socialPostBloc.add(PlayPauseVideoEvent(play: true));
        }
      },
      onTapShare: (reelsData) async {
        if (reelsData.postData is TimeLineData) {
          _socialPostBloc.add(PlayPauseVideoEvent(play: false));
          final shareRes = await _postConfig.postCallBackConfig?.onShareClicked
              ?.call(reelsData.postData as TimeLineData);
          _socialPostBloc.add(PlayPauseVideoEvent(play: true));
          if (shareRes != null){
            _socialPostBloc.add(OnShareSuccessEvent(shareSuccessData: shareRes));
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
          } else {
            if (mention.userId.isStringEmptyOrNull == false) {
              _postConfig.postCallBackConfig?.onProfileClick?.call(
                  reelData.postData is TimeLineData
                      ? reelData.postData as TimeLineData
                      : null,
                  mention.userId!,
                  null);
              _logProfileEvent(reelData.userId ?? '', reelData.userName ?? '');
            }
          }
        } else if (reelData.postData is TimeLineData) {
          return _showMentionList(mentionList, tabData.postSectionType,
              reelData.postData as TimeLineData);
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
        _socialPostBloc.add(PlayPauseVideoEvent(play: false));
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
                : null);
        _socialPostBloc.add(PlayPauseVideoEvent(play: true));
        return result;
      },
      onPressMoreButton: (reelsData) async {
        if (reelsData.postData is TimeLineData) {
          _socialPostBloc.add(PlayPauseVideoEvent(play: false));
          await _handleMoreOptions(reelsData.postData as TimeLineData, tabData);
          _socialPostBloc.add(PlayPauseVideoEvent(play: true));
        }
      },
      onPressLike: _postConfig.postCallBackConfig?.onLikeClick == null
          ? null
          : (reelsData, isLiked) async {
              _socialPostBloc.add(PlayPauseVideoEvent(play: false));
              final postData = reelsData.postData is TimeLineData
                  ? reelsData.postData as TimeLineData
                  : null;
              final result = await _postConfig.postCallBackConfig?.onLikeClick
                  ?.call(postData, isLiked);
              _socialPostBloc.add(PlayPauseVideoEvent(play: true));
              return result ?? false;
            },
      onPressSave: (reelsData, currentSaved) async {
        if (_postConfig.postCallBackConfig?.onSaveClicked == null) {
          return await _handleCollection(reelsData, currentSaved);
        } else {
          _socialPostBloc.add(PlayPauseVideoEvent(play: false));
          final postData = reelsData.postData is TimeLineData
              ? reelsData.postData as TimeLineData
              : null;
          final result = await _postConfig.postCallBackConfig?.onSaveClicked
              ?.call(postData, currentSaved);
          _socialPostBloc.add(PlayPauseVideoEvent(play: true));
          return result ?? false;
        }
      },
      onPressFollow: _postConfig.postCallBackConfig?.onFollowClick == null
          ? null
          : (reelsData, isFollowed) async {
              _socialPostBloc.add(PlayPauseVideoEvent(play: false));
              final postData = reelsData.postData is TimeLineData
                  ? reelsData.postData as TimeLineData
                  : null;
              final result = await _postConfig.postCallBackConfig?.onFollowClick
                  ?.call(postData, isFollowed);
              _socialPostBloc.add(PlayPauseVideoEvent(play: true));
              return result ?? false;
            });

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
  Future<List<ReelsData>> _handleLoadMore(TabDataModel tabData) async {
    try {
      final completer = Completer<List<TimeLineData>>();
      _socialPostBloc.add(GetMorePostEvent(
        isLoading: false,
        isPagination: true,
        isRefresh: false,
        postSectionType: tabData.postSectionType,
        memberUserId: '',
        onComplete: completer.complete,
      ));
      final timeLinePostList = await completer.future;
      if (timeLinePostList.isEmpty) return [];
      final timeLineReelDataList = timeLinePostList
          .map((post) => getReelData(post, loggedInUserId: _loggedInUserId))
          .toList();
      return timeLineReelDataList;
    } catch (e) {
      debugPrint('Error handling load more: $e');
      return [];
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

  Widget _buildTabBar() => ValueListenableBuilder<bool>(
      valueListenable: _tabsVisibilityNotifier,
      builder: (context, value, child) => value == true
          ? Container(
              decoration: BoxDecoration(
                // Gradient overlay for better tab visibility on any background
                gradient: _tabBarConfig?.containerGradient ??
                    LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.changeOpacity(0.6),
                        Colors.black.changeOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
              ),
              padding: _tabBarConfig?.containerPadding ??
                  EdgeInsets.only(
                      top:
                          MediaQuery.of(context).padding.top + IsrDimens.twenty,
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
                        highlightColor:
                            _tabBarConfig?.highlightColor ?? Colors.transparent,
                      ),
                      child: TabBar(
                        controller: _postTabController,
                        isScrollable: _tabBarConfig?.isScrollable ?? true,
                        tabAlignment:
                            _tabBarConfig?.tabAlignment ?? TabAlignment.start,
                        labelColor:
                            _tabBarConfig?.labelColor ?? IsrColors.white,
                        unselectedLabelColor:
                            _tabBarConfig?.unselectedLabelColor ??
                                IsrColors.white.changeOpacity(0.7),
                        indicatorColor:
                            _tabBarConfig?.indicatorColor ?? IsrColors.white,
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
                            IsrStyles.white16.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.changeOpacity(0.8),
                                  offset: const Offset(0, 1),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: Colors.black.changeOpacity(0.5),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                        unselectedLabelStyle:
                            _tabBarConfig?.unselectedLabelStyle ??
                                IsrStyles.white16.copyWith(
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.changeOpacity(0.8),
                                      offset: const Offset(0, 1),
                                      blurRadius: 4,
                                    ),
                                    Shadow(
                                      color: Colors.black.changeOpacity(0.5),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
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

  @override
  void dispose() {
    _postTabController?.dispose();
    for (var controller in _refreshControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  final Map<int, int> _refreshCounts = {};

  String _getUniqueKey(TabDataModel tabData, int index) {
    _refreshCounts[index] ??= 0;
    return '${tabData.reelsDataList.length}_${_refreshCounts[index]}';
  }

  bool _isFollowingPostsEmpty() {
    final isFollowingPostEmpty = widget.tabDataModelList.length > 1 &&
        widget.tabDataModelList[0].postSectionType ==
            PostSectionType.following &&
        widget.tabDataModelList[0].reelsDataList.isListEmptyOrNull;
    return isFollowingPostEmpty;
  }

  Future<int> _handleCommentAction(String postId, int totalCommentsCount,
      TabDataModel tabData, TimeLineData? postData) async {
    final completer = Completer<int>();

    final result = await Utility.showBottomSheet<int>(
      isSafeArea: false,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _socialPostBloc),
          BlocProvider.value(
              value: context.getOrCreateBloc<CommentActionCubit>()),
          BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        ],
        child: CommentsBottomSheet(
          postId: postId,
          onTapProfile: (userId) {
            context.pop(totalCommentsCount);
            _postConfig.postCallBackConfig?.onProfileClick
                ?.call(postData, userId, null);
            _logProfileEvent(userId, postData?.user?.username ?? '');
          },
          onTapHasTag: (hashTag) {
            context.pop(totalCommentsCount);
            _redirectToHashtag(hashTag, tabData.postSectionType, postId);
          },
          postData: postData,
          tabData: tabData,
        ),
      ),
      isDarkBG: true,
      backgroundColor: Colors.black,
    );
    completer.complete(max(totalCommentsCount + (result ?? 0), 0));
    return completer.future;
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
    PostSectionType postSectionType,
    TimeLineData postData,
  ) async {
    final userid = await _socialPostBloc.userId;
    final updatedMentionList =
        await Utility.showBottomSheet<List<MentionMetaData>>(
      isScrollControlled: true,
      child: MentionListBottomSheet(
        initialMentionList: [],
        postData: postData,
        myUserId: userid,
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
      postSectionType: _currentPostSectionType,
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

  /// Handles the more options menu for a post
  Future<dynamic> _handleMoreOptions(
      TimeLineData postDataModel, TabDataModel tabData) async {
    try {
      return await _showMoreOptionsDialog(
        tabData: tabData,
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
        isSelfProfile: postDataModel.user?.id == _loggedInUserId,
        onEditPost: () async {
          unawaited(_handleEditPost(postDataModel));
        },
        onShowPostInsight: () async {
          IsrAppNavigator.goToPostInsight(context,
              postId: postDataModel.id ?? '', postData: postDataModel);
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
  }

  // Additional handlers for likes, follows, etc.
  // ... (implement other handlers similarly)
  Future<dynamic> _showMoreOptionsDialog({
    Future<dynamic> Function()? onReportPost,
    Future<dynamic> Function()? onDeletePost,
    Future<dynamic> Function()? onEditPost,
    Future<dynamic> Function()? onShowPostInsight,
    bool? isSelfProfile,
    required TabDataModel tabData,
  }) async {
    final completer = Completer<dynamic>();
    final result = await Utility.showBottomSheet<dynamic>(
      isDismissible: true,
      child: MoreOptionsBottomSheet(
        onReportPost: () async {
          if (onReportPost != null) {
            await onReportPost();
          }
          completer.complete(true);
        },
        isSelfProfile: isSelfProfile == true,
        onDeletePost: () async {
          if (onDeletePost != null) {
            await onDeletePost();
          }
          completer.complete(true);
        },
        onEditPost: () async {
          if (onEditPost != null) {
            await onEditPost();
          }
          completer.complete(true);
        },
        onShowPostInsight: () async {
          if (onShowPostInsight != null) {
            await onShowPostInsight();
          }
          completer.complete(true);
        },
      ),
    );
    // If the bottom sheet was dismissed without any action, complete the completer with null
    if (!completer.isCompleted && result != true) {
      completer.complete(result);
    }
    return completer.future;
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
      child: BlocProvider<CollectionBloc>(
        create: (context) => IsmInjectionUtils.getBloc<CollectionBloc>(),
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
