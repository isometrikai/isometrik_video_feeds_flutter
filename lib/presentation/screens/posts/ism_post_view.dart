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
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;

class IsmPostView extends StatefulWidget {
  const IsmPostView({
    super.key,
    required this.tabDataModelList,
    this.currentIndex = 0,
    this.allowImplicitScrolling = false,
    this.onTapPlace,
    this.onLinkProduct,
    this.tabConfig = const TabConfig(),
    this.postConfig = const PostConfig(),
  });

  final List<TabDataModel> tabDataModelList;
  final num? currentIndex;
  final bool? allowImplicitScrolling;
  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
      onLinkProduct;
  final TabConfig tabConfig;
  final PostConfig postConfig;

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
  List<TabDataModel> _tabDataModelList = [];
  VideoCacheManager? _videoCacheManager;
  late SocialPostBloc _socialPostBloc; // Will be initialized from context
  late IsmSocialActionCubit _socialActionCubit;
  var _currentPostSectionType = PostSectionType.forYou;

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
    _tabDataModelList = widget.tabDataModelList;
    _currentIndex = widget.currentIndex?.toInt() ?? 0;
    _currentPostSectionType = _tabDataModelList[_currentIndex].postSectionType;
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
    _postTabController?.addListener(() async {
      if (!mounted) return;
      final newIndex = _postTabController?.index ?? 0;
      if (_currentIndex != newIndex) {
        final tabData = _tabDataModelList[newIndex];
        _currentPostSectionType = tabData.postSectionType;
        widget.tabConfig.tabCallBackConfig?.onChangeOfTab?.call(tabData);
        // Handle tab change if we have a user
        if (_loggedInUserId.isNotEmpty) {
          try {
            _videoCacheManager = VideoCacheManager();
          } catch (e) {
            debugPrint('Error during tab change: $e');
          }
        }
        setState(() {
          _currentIndex = newIndex;
        });
        if (tabData.reelsDataList.isEmpty) {
          final result = await _handlePostRefresh(tabData);
          if (result) {
            setState(() {});
          }
        }
      }
    });
    _socialPostBloc.add(LoadPostData(
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
        BlocProvider.value(value: _socialActionCubit),
      ];

  // ✅ Don't wrap with BlocProvider again - just use BlocConsumer
  Widget _buildContent() => AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: IsrColors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        child: BlocConsumer<SocialPostBloc, SocialPostState>(
          bloc: _socialPostBloc,
          listenWhen: (previousState, currentState) =>
              currentState is SocialPostLoadedState,
          listener: (context, state) {
            // ✅ Update _socialPostBloc reference if needed
            debugPrint('ism_post_view: listener called with state: $state');
            if (state is SocialPostLoadedState) {
              state.postsByTab.forEach((sectionType, posts) {
                _tabDataModelList
                    .where((_) => _.postSectionType == sectionType)
                    .firstOrNull
                    ?.let(
                        (tabData) => {tabData.reelsDataList = posts.toList()});
              });
            }
          },
          buildWhen: (previousState, currentState) =>
              currentState is SocialPostLoadedState ||
              currentState is PostLoadingState,
          builder: (context, state) {
            final newUserId =
                state is SocialPostLoadedState ? state.userId : '';
            if (newUserId.isNotEmpty && _loggedInUserId.isEmpty) {
              _videoCacheManager = VideoCacheManager();
            } else if (newUserId.isEmpty && _loggedInUserId.isNotEmpty) {
              _videoCacheManager?.clearCache();
              _videoCacheManager = null;
            }
            _loggedInUserId = newUserId;

            return state is PostLoadingState
                ? state.isLoading == true
                    ? _buildInitialLoadingView()
                    : const SizedBox.shrink()
                : state is SocialPostLoadedState
                    ? DefaultTabController(
                        length: _tabDataModelList.isListEmptyOrNull
                            ? 0
                            : _tabDataModelList.length,
                        initialIndex: _currentIndex,
                        child: Stack(
                          children: [
                            TabBarView(
                              controller: _postTabController,
                              children: _tabDataModelList
                                  .map((tabData) => _buildTabBarView(tabData,
                                      _tabDataModelList.indexOf(tabData)))
                                  .toList(),
                            ),
                            if (_tabDataModelList.length > 1) ...[
                              _buildTabBar()
                            ] else ...[
                              _buildBackButton()
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink();
          },
        ),
      );

  Widget _buildBackButton() => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16.responsiveDimension,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.applyOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.pop();
            },
          ),
        ),
      );

  Widget _buildTabBarView(TabDataModel tabData, int index) => PostItemWidget(
        key: ValueKey(_getUniqueKey(tabData, index)),
        videoCacheManager:
            _loggedInUserId.isNotEmpty ? _videoCacheManager : null,
        onTapPlaceHolder: () {
          if ((_postTabController?.length ?? 0) > 1) {
            _tabsVisibilityNotifier.value = true;
            final trendingTabIndex = _tabDataModelList.indexWhere((tabData) =>
                tabData.postSectionType == PostSectionType.trending);
            if (trendingTabIndex != -1) {
              _postTabController?.animateTo(trendingTabIndex);
            }
          }
        },
        loggedInUserId: _loggedInUserId,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        reelsDataList: tabData.reelsDataList
            .map((_) => getReelData(_, loggedInUserId: _loggedInUserId))
            .toList(),
        reelsConfig: _getReelsConfig(tabData),
        onLoadMore: () async => await _handleLoadMore(tabData),
        onRefresh: () async {
          var result = await _handlePostRefresh(tabData);
          // Increment refresh count to force rebuild
          if (result) {
            setState(() {
              _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
            });
          }
          return result;
        },
        startingPostIndex: tabData.startingPostIndex,
        postSectionType: tabData.postSectionType,
      );

  ReelsConfig _getReelsConfig(TabDataModel tabData) => ReelsConfig(
        overlayPadding: widget.postConfig.postUIConfig?.overlayPadding,
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
            await widget.postConfig.postCallBackConfig?.onTagProductClick
                ?.call(reelsData.postData as TimeLineData);
            _socialPostBloc.add(PlayPauseVideoEvent(play: true));
          }
        },
        onTapShare: (reelsData) async {
          if (reelsData.postData is TimeLineData) {
            _socialPostBloc.add(PlayPauseVideoEvent(play: false));
            await widget.postConfig.postCallBackConfig?.onShareClicked
                ?.call(reelsData.postData as TimeLineData);
            _socialPostBloc.add(PlayPauseVideoEvent(play: true));
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
                widget.postConfig.postCallBackConfig?.onProfileClick?.call(
                    reelData.postData is TimeLineData
                        ? reelData.postData as TimeLineData
                        : null,
                    mention.userId!);
                _logProfileEvent(
                    reelData.userId ?? '', reelData.userName ?? '');
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
          widget.postConfig.postCallBackConfig?.onProfileClick?.call(
              reelsData.postData is TimeLineData
                  ? reelsData.postData as TimeLineData
                  : null,
              reelsData.userId ?? '');
          _logProfileEvent(reelsData.userId ?? '', reelsData.userName ?? '');
        },
        onTapComment: (reelsData, totalCommentsCount) async {
          _socialPostBloc.add(PlayPauseVideoEvent(play: false));
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
            final result = await _handleMoreOptions(
                reelsData.postData as TimeLineData, tabData);
            _socialPostBloc.add(PlayPauseVideoEvent(play: true));
            return result;
          }
        },
      onPressLike: widget.postConfig.postCallBackConfig?.onLikeClick == null
          ? null
          : (reelsData, isLiked) async {
              _socialPostBloc.add(PlayPauseVideoEvent(play: false));
              final postData = reelsData.postData is TimeLineData ? reelsData.postData as TimeLineData : null;
              final result = await widget
                  .postConfig.postCallBackConfig?.onLikeClick
                  ?.call(postData, isLiked);
              _socialPostBloc.add(PlayPauseVideoEvent(play: true));
              return result ?? false;
            },
      onPressSave: widget.postConfig.postCallBackConfig?.onSaveClicked == null
          ? null
          : (reelsData, isSaved) async {
              _socialPostBloc.add(PlayPauseVideoEvent(play: false));
              final postData = reelsData.postData is TimeLineData ? reelsData.postData as TimeLineData : null;
              final result = await widget
                  .postConfig.postCallBackConfig?.onSaveClicked
                  ?.call(postData, isSaved);
              _socialPostBloc.add(PlayPauseVideoEvent(play: true));
              return result ?? false;
            },
      onPressFollow: widget.postConfig.postCallBackConfig?.onFollowClick == null
          ? null
          : (reelsData, isFollowed) async {
              _socialPostBloc.add(PlayPauseVideoEvent(play: false));
              final postData = reelsData.postData is TimeLineData ? reelsData.postData as TimeLineData : null;
              final result = await widget
                  .postConfig.postCallBackConfig?.onFollowClick
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
        placeMetaData.placeName ?? '',
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
        placeName: placeMetaData.placeName ?? '',
        latitude: lat,
        longitude: long,
        tabConfig: widget.tabConfig,
        postConfig: widget.postConfig,
      );
    } catch (e) {
      debugPrint('Navigation failed: $e');
    }
  }

  Future<bool> _handleLikeAction(bool isLiked, TimeLineData postData) async {
    try {
      final completer = Completer<bool>();

      _socialPostBloc.add(LikePostEvent(
        postId: postData.id ?? '',
        userId: postData.user?.id ?? '',
        likeAction: isLiked ? LikeAction.unlike : LikeAction.like,
        onComplete: (success) {
          completer.complete(success);
        },
      ));
      return await completer.future;
    } catch (e) {
      return false;
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
              color: Colors.transparent,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + IsrDimens.twenty),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Theme(
                      data: ThemeData(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: TabBar(
                        controller: _postTabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: _tabDataModelList[_currentIndex]
                                .reelsDataList
                                .isListEmptyOrNull
                            ? IsrColors.black
                            : IsrColors.white,
                        unselectedLabelColor: _tabDataModelList[_currentIndex]
                                .reelsDataList
                                .isListEmptyOrNull
                            ? IsrColors.black
                            : IsrColors.white.changeOpacity(0.6),
                        indicatorColor: _tabDataModelList[_currentIndex]
                                .reelsDataList
                                .isListEmptyOrNull
                            ? IsrColors.black
                            : IsrColors.white,
                        indicatorWeight: 3,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.label,
                        padding: IsrDimens.edgeInsetsSymmetric(
                            horizontal: IsrDimens.sixteen),
                        labelPadding: IsrDimens.edgeInsetsSymmetric(
                            horizontal: IsrDimens.eight),
                        labelStyle: IsrStyles.white16.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                        unselectedLabelStyle: IsrStyles.white16.copyWith(
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        tabs: _tabDataModelList
                            .map(
                              (tab) => Tab(
                                child: Text(
                                  tab.title,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
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
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _socialPostBloc),
          BlocProvider.value(
              value: context.getOrCreateBloc<CommentActionCubit>()),
          BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        ],
        child: CommentsBottomSheet(
          postId: postId,
          totalCommentsCount: totalCommentsCount,
          onTapProfile: (userId) {
            context.pop(totalCommentsCount);
            widget.postConfig.postCallBackConfig?.onProfileClick
                ?.call(postData, userId);
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
    completer.complete(result ?? 0);

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
      tabConfig: widget.tabConfig,
      postConfig: widget.postConfig,
    );
  }

  Future<List<MentionMetaData>> _showMentionList(
    List<MentionMetaData> mentionList,
    PostSectionType postSectionType,
    TimeLineData postData,
  ) async {
    final updatedMentionList =
        await Utility.showBottomSheet<List<MentionMetaData>>(
      isScrollControlled: true,
      child: MentionListBottomSheet(
        initialMentionList: [],
        postData: postData,
        myUserId: '',
        onTapUserProfile: (userId) {
          context.pop();
          widget.postConfig.postCallBackConfig?.onProfileClick
              ?.call(postData, userId);
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
        color: Colors.black,
        child: const Center(child: PostShimmerView()),
      );

  /// Handles refresh for user posts
  Future<bool> _handlePostRefresh(TabDataModel tabData) async {
    final completer = Completer<bool>();
    _socialPostBloc.add(GetMorePostEvent(
      isLoading: false,
      isPagination: false,
      isRefresh: true,
      postSectionType: _currentPostSectionType,
      memberUserId: '',
      onComplete: (postDataList) async {
        tabData.reelsDataList
          ..clear()
          ..addAll(postDataList);
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
        onPressReport: ({String message = '', String reason = ''}) async {
          final result = await _showReportPostDialog(context);

          if (result == true) {
            final completer = Completer<bool>();
            _socialPostBloc.add(
              ReportPostEvent(
                postId: postDataModel.id ?? '',
                message: message,
                reason: reason,
                onComplete: (success, reportReason) {
                  if (success) {
                    Utility.showInSnackBar(
                        IsrTranslationFile.postReportedSuccessfully, context,
                        isSuccessIcon: true);
                    _logReportEvent(postDataModel, reportReason, tabData);
                  }
                  completer.complete(success);
                },
              ),
            );
            return await completer.future;
          } else {
            return false;
          }
        },
        onDeletePost: () async {
          final result = await _showDeletePostDialog(context);
          if (result == true) {
            final completer = Completer<bool>();
            _socialPostBloc.add(
              DeletePostEvent(
                postId: postDataModel.id ?? '',
                onComplete: (success) {
                  if (success) {
                    Utility.showToastMessage(
                        IsrTranslationFile.postDeletedSuccessfully);
                    _removePostFromList(postDataModel.id ?? '', tabData);
                  }
                  completer.complete(success);
                },
              ),
            );
            return await completer.future;
          }
          return false;
        },
        isSelfProfile: postDataModel.user?.id == _loggedInUserId,
        onEditPost: () async {
          final postDataString =
              await _showEditPostDialog(context, postDataModel);
          return postDataString ?? '';
        },
        onShowPostInsight: () {
          IsrAppNavigator.goToPostInsight(context,
              postId: postDataModel.id ?? '', postData: postDataModel);
        },
      );
    } catch (e) {
      debugPrint('Error handling more options: $e');
      return false;
    }
  }

  void _removePostFromList(String postId, TabDataModel tabData) {
    for (var tabData in _tabDataModelList) {
      tabData.reelsDataList.removeWhere((element) => element.id == postId);
    }
  }

  // Additional handlers for likes, follows, etc.
  // ... (implement other handlers similarly)
  Future<dynamic> _showMoreOptionsDialog({
    Future<bool> Function({String message, String reason})? onPressReport,
    Future<bool> Function()? onDeletePost,
    Future<String> Function()? onEditPost,
    VoidCallback? onShowPostInsight,
    bool? isSelfProfile,
    required TabDataModel tabData,
  }) async {
    final completer = Completer<dynamic>();
    final result = await Utility.showBottomSheet<dynamic>(
      isDismissible: true,
      child: MoreOptionsBottomSheet(
        onPressReport: ({String message = '', String reason = ''}) async {
          try {
            if (onPressReport != null) {
              final isReported =
                  await onPressReport(message: message, reason: reason);
              if (!completer.isCompleted) {
                completer.complete(isReported);
              }
              return isReported;
            }
            return false;
          } catch (e) {
            return false;
          }
        },
        isSelfProfile: isSelfProfile == true,
        onDeletePost: () async {
          if (onDeletePost != null) {
            final isDeleted = await onDeletePost();
            completer.complete(isDeleted);
            return isDeleted;
          }
          return false;
        },
        onEditPost: () async {
          if (onEditPost != null) {
            final postDataString = await onEditPost();
            if (postDataString.isStringEmptyOrNull == false) {
              final postData = TimeLineData.fromMap(
                  jsonDecode(postDataString) as Map<String, dynamic>);
              final reelData =
                  getReelData(postData, loggedInUserId: _loggedInUserId);
              if (!completer.isCompleted) {
                completer.complete(reelData);
              }
            }
            return postDataString;
          }
          return '';
        },
        onShowPostInsight: onShowPostInsight,
      ),
    );
    // If the bottom sheet was dismissed without any action, complete the completer with null
    if (!completer.isCompleted) {
      completer.complete(result);
    }
    return completer.future;
  }

  Future<bool?> _showReportPostDialog(BuildContext context) => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.reportPost,
                  style: IsrStyles.primaryText18
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                16.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.reportPostConfirmation,
                  style: IsrStyles.primaryText14.copyWith(
                    color: '4A4A4A'.toColor(),
                  ),
                ),
                32.responsiveVerticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AppButton(
                      title: IsrTranslationFile.report,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(true),
                      backgroundColor: 'E04755'.toColor(),
                    ),
                    AppButton(
                      title: IsrTranslationFile.cancel,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(false),
                      backgroundColor: 'F6F6F6'.toColor(),
                      textColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Future<bool?> _showDeletePostDialog(BuildContext context) => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.deletePost,
                  style: IsrStyles.primaryText18
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                16.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.deletePostConfirmation,
                  style: IsrStyles.primaryText14.copyWith(
                    color: '4A4A4A'.toColor(),
                  ),
                ),
                32.responsiveVerticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AppButton(
                      title: IsrTranslationFile.delete,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(true),
                      backgroundColor: 'E04755'.toColor(),
                    ),
                    AppButton(
                      title: IsrTranslationFile.cancel,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(false),
                      backgroundColor: 'F6F6F6'.toColor(),
                      textColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Future<String?> _showEditPostDialog(
          BuildContext context, TimeLineData postDataModel) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.editPost,
                  style: IsrStyles.primaryText18
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                16.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.editPostConfirmation,
                  style: IsrStyles.primaryText14.copyWith(
                    color: '4A4A4A'.toColor(),
                  ),
                ),
                32.responsiveVerticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AppButton(
                      title: IsrTranslationFile.yes,
                      width: 102.responsiveDimension,
                      onPress: () async {
                        final postDataString =
                            await _handleEditPost(postDataModel);
                        Navigator.of(context).pop(postDataString ?? '');
                      },
                      backgroundColor: '006CD8'.toColor(),
                    ),
                    AppButton(
                      title: IsrTranslationFile.cancel,
                      width: 102.responsiveDimension,
                      onPress: () => Navigator.of(context).pop(''),
                      backgroundColor: 'F6F6F6'.toColor(),
                      textColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Future<String?> _handleEditPost(TimeLineData postDataModel) async {
    final postDataString = await IsrAppNavigator.goToEditPostView(context,
        postData: postDataModel, onTagProduct: widget.onLinkProduct);
    return postDataString;
  }

  void _logReportEvent(TimeLineData postDataModel, String reportReason,
      TabDataModel tabDataModel) async {
    final postReportEvent = {
      'post_id': postDataModel.id ?? '',
      'post_type': postDataModel.media?.first.mediaType,
      'post_author_id': postDataModel.userId ?? '',
      'feed_type': tabDataModel.postSectionType.title,
      'categories': [],
      'hashtags': postDataModel.tags?.hashtags?.map((e) => '#$e').toList(),
      'report_reason': reportReason
    };

    unawaited(EventQueueProvider.instance.addEvent(
        EventType.postReported.value, postReportEvent.removeEmptyValues()));
  }

  void _logProfileEvent(String profileUserId, String profileUserName) {
    final profileEvent = {
      'profile_user_id': profileUserId,
      'profile_username': profileUserName,
    };

    unawaited(EventQueueProvider.instance.addEvent(
        EventType.profileViewed.value, profileEvent.removeEmptyValues()));
  }

  void _logHashtagEvent(String hashTag) {
    final hashTagEventMap = {'hashtag': hashTag};
    unawaited(EventQueueProvider.instance.addEvent(
        EventType.hashTagClicked.value, hashTagEventMap.removeEmptyValues()));
  }
}
