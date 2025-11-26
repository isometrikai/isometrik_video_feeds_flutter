import 'dart:async';
import 'dart:convert';

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
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;

class IsmPostView extends StatefulWidget {
  const IsmPostView({
    super.key,
    required this.tabDataModelList,
    this.currentIndex = 0,
    this.allowImplicitScrolling = false,
    this.onPageChanged,
    this.onTabChanged,
    this.onTapPlace,
    this.onTagProduct,
  });

  final List<TabDataModel> tabDataModelList;
  final num? currentIndex;
  final bool? allowImplicitScrolling;
  final Function(int, String)? onPageChanged;
  final Function(int)? onTabChanged;
  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)? onTagProduct;

  /// Optional callback to override default place navigation
  /// If not provided, SDK will navigate to PlaceDetailsView automatically
  /// Parameters: placeId, placeName, latitude, longitude
  final Function(String placeId, String placeName, double lat, double long)? onTapPlace;

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

    _refreshControllers = List.generate(_tabDataModelList.length, (index) => RefreshController());
    _socialPostBloc = context.getOrCreateBloc();
    if (_socialPostBloc.isClosed) {
      isrConfigureInjection();
      _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
    }

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
        widget.onTabChanged?.call(newIndex);
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
          create: (_) => _socialPostBloc
            ..add(StartPost(
                postSections: widget.tabDataModelList
                    .map((_) => PostTabAssistData(
                        postSectionType: _.postSectionType, postList: _.reelsDataList))
                    .toList())), // ✅ Trigger initial load
        ),
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
          listenWhen: (previousState, currentState) => currentState is SocialPostLoadedState,
          listener: (context, state) {
            // ✅ Update _socialPostBloc reference if needed
            debugPrint('ism_post_view: listener called with state: $state');
            if (state is SocialPostLoadedState) {
              state.postsByTab.forEach((sectionType, posts) {
                _tabDataModelList
                    .where((_) => _.postSectionType == sectionType)
                    .firstOrNull
                    ?.let((tabData) => {tabData.reelsDataList = posts.toList()});
              });
            }
          },
          buildWhen: (previousState, currentState) =>
              currentState is SocialPostLoadedState || currentState is PostLoadingState,
          builder: (context, state) {
            final newUserId = state is SocialPostLoadedState ? state.userId : '';
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
                        length: _tabDataModelList.isListEmptyOrNull ? 0 : _tabDataModelList.length,
                        initialIndex: _currentIndex,
                        child: Stack(
                          children: [
                            TabBarView(
                              controller: _postTabController,
                              children: _tabDataModelList
                                  .map((tabData) =>
                                      _buildTabBarView(tabData, _tabDataModelList.indexOf(tabData)))
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
        overlayPadding: tabData.overlayPadding,
        videoCacheManager: _loggedInUserId.isNotEmpty ? _videoCacheManager : null,
        onTapPlaceHolder: () {
          if ((_postTabController?.length ?? 0) > 1) {
            _tabsVisibilityNotifier.value = true;
            final trendingTabIndex = _tabDataModelList
                .indexWhere((tabData) => tabData.postSectionType == PostSectionType.trending);
            if (trendingTabIndex != -1) {
              _postTabController?.animateTo(trendingTabIndex);
            }
          }
        },
        loggedInUserId: _loggedInUserId,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        onPageChanged: widget.onPageChanged,
        reelsDataList: tabData.reelsDataList.map((_) => _getReelData(_, tabData)).toList(),
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
        onTapCartIcon: (postId) {
          if (tabData.onTapCartIcon != null) {
            final reelData = tabData.reelsDataList.firstWhere((element) => element.id == postId);
            final productIds = <String>[];
            final socialProductList = reelData.tags?.products ?? <SocialProductData>[];
            for (final productItem in socialProductList) {
              productIds.add(productItem.productId ?? '');
            }
            tabData.onTapCartIcon?.call(productIds, postId, reelData.userId ?? '');
          } else {}
        },
      );

  ReelsData _getReelData(
    TimeLineData postData,
    TabDataModel tabData,
  ) =>
      ReelsData(
        postSetting: PostSetting(
          isProfilePicVisible: true,
          isCreatePostButtonVisible: false,
          isCommentButtonVisible: postData.settings?.commentsEnabled == true,
          isSaveButtonVisible: postData.settings?.saveEnabled == true,
          isLikeButtonVisible: true,
          isShareButtonVisible: true,
          isMoreButtonVisible: true,
          isFollowButtonVisible: postData.user?.id != _loggedInUserId,
          isUnFollowButtonVisible: postData.user?.id != _loggedInUserId,
        ),
        mentions: postData.tags != null && postData.tags?.mentions.isListEmptyOrNull == false
            ? (postData.tags?.mentions?.map(_getMentionMetaData).toList() ?? [])
            : [],
        tagDataList: postData.tags != null && postData.tags?.hashtags.isListEmptyOrNull == false
            ? postData.tags?.hashtags?.map(_getMentionMetaData).toList()
            : null,
        placeDataList: postData.tags != null && postData.tags?.places.isListEmptyOrNull == false
            ? postData.tags?.places?.map(_getPlaceMetaData).toList()
            : null,
        onTapPlace: (placeList) {
          if (placeList.isListEmptyOrNull) return;
          if (placeList.length == 1) {
            _goToPlaceDetailsView(
                tabData.postSectionType, placeList.first, TagType.place, tabData.onTapUserProfile);
          } else {
            // _showPlaceList(placeList, postSectionType);
          }
        },
        onTapMentionTag: (mentionList) async {
          if (mentionList.isListEmptyOrNull) return [];
          if (mentionList.length == 1) {
            final mention = mentionList.first;
            if (mention.tag.isStringEmptyOrNull == false) {
              _redirectToHashtag(mention.tag, tabData.postSectionType, tabData.onTapUserProfile);
              return null;
            } else {
              tabData.onTapUserProfile?.call(mention.userId);
            }
          } else {
            return _showMentionList(mentionList, tabData.postSectionType, postData);
          }
          return mentionList;
        },
        postId: postData.id,
        onCreatePost: () async => await _handleCreatePost(tabData),
        tags: postData.tags,
        mediaMetaDataList: postData.media?.map(_getMediaMetaData).toList() ?? [],
        userId: postData.user?.id ?? '',
        userName: postData.user?.username ?? '',
        profilePhoto: postData.user?.avatarUrl ?? '',
        firstName: postData.user?.displayName?.split(' ').firstOrNull ?? '',
        lastName:
            postData.user?.displayName?.split(' ').takeIf((_) => _.length > 1)?.lastOrNull ?? '',
        likesCount: postData.engagementMetrics?.likeTypes?.love?.toInt() ?? 0,
        commentCount: postData.engagementMetrics?.comments?.toInt() ?? 0,
        isFollow: postData.isFollowing == true,
        isLiked: postData.isLiked,
        isSavedPost: false,
        isVerifiedUser: false,
        productCount: postData.tags?.products?.length ?? 0,
        description: postData.caption ?? '',
        onTapUserProfile: (isSelfProfile) {
          tabData.onTapUserProfile?.call(postData.user?.id);
        },
        onTapComment: (totalCommentsCount) async {
          final result = await _handleCommentAction(
              postData.id ?? '', totalCommentsCount, tabData.postSectionType);
          return result;
        },
        onTapShare: (tabData.onShareClick == null)
            ? null
            : () {
                tabData.onShareClick?.call(postData);
              },
        onPressMoreButton: () async {
          final result = await _handleMoreOptions(postData, tabData);
          return result;
        },
        onPressLike: (isLiked) async => _handleLikeAction(isLiked, postData),
        onPressSave: (isSavedPost) async {
          try {
            if (tabData.onPressSave != null) {
              return tabData.onPressSave?.call(isSavedPost, postData) ?? isSavedPost;
            }
            final completer = Completer<bool>();
            _socialPostBloc.add(SavePostEvent(
              postId: postData.id ?? '',
              isSaved: isSavedPost,
              onComplete: (success) {
                completer.complete(success);
              },
            ));
            return await completer.future;
          } catch (e) {
            return false;
          }
        },
        onPressFollow: (userId, isFollow) async {
          try {
            final completer = Completer<bool>();
            _socialPostBloc.add(FollowUserEvent(
              followingId: userId,
              onComplete: (success) {
                completer.complete(success);
              },
              followAction: isFollow ? FollowAction.unfollow : FollowAction.follow,
            ));
            return await completer.future;
          } catch (e) {
            return false;
          }
        },
      );

  void _goToPlaceDetailsView(
    PostSectionType postSectionType,
    PlaceMetaData placeMetaData,
    TagType place,
    Function(String)? onTapProfilePicture,
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
        onTapProfilePicture: (userId) {
          if (onTapProfilePicture != null) {
            onTapProfilePicture.call(userId);
          }
        },
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
      final timeLineReelDataList =
          timeLinePostList.map((post) => _getReelData(post, tabData)).toList();
      return timeLineReelDataList;
    } catch (e) {
      debugPrint('Error handling load more: $e');
      return [];
    }
  }

  // Interaction handlers
  Future<ReelsData?> _handleCreatePost(TabDataModel tabData) async {
    final completer = Completer<ReelsData>();
    final postDataModelString = await IsrAppNavigator.goToCreatePostView(context);
    if (postDataModelString.isStringEmptyOrNull == false) {
      final postDataModel =
          TimeLineData.fromMap(jsonDecode(postDataModelString!) as Map<String, dynamic>);
      final reelsData = _getReelData(postDataModel, tabData);
      completer.complete(reelsData);
    }
    return completer.future;
  }

  MediaMetaData _getMediaMetaData(MediaData mediaData) => MediaMetaData(
        mediaType: mediaData.mediaType == 'image' ? 0 : 1,
        mediaUrl: mediaData.url ?? '',
        thumbnailUrl: mediaData.previewUrl ?? '',
      );

  MentionMetaData _getMentionMetaData(MentionData mentionData) => MentionMetaData(
        userId: mentionData.userId,
        username: mentionData.username,
        name: mentionData.name,
        avatarUrl: mentionData.avatarUrl,
        tag: mentionData.tag,
        textPosition: mentionData.textPosition != null
            ? MentionPosition(
                start: mentionData.textPosition?.start,
                end: mentionData.textPosition?.end,
              )
            : null,
        mediaPosition: mentionData.mediaPosition != null
            ? MediaPosition(
                position: mentionData.mediaPosition?.position,
                x: mentionData.mediaPosition?.x,
                y: mentionData.mediaPosition?.y,
              )
            : null,
      );

  PlaceMetaData _getPlaceMetaData(TaggedPlace placeData) => PlaceMetaData(
        address: placeData.address,
        city: placeData.city,
        coordinates: placeData.coordinates,
        country: placeData.country,
        description: placeData.placeData?.description,
        placeId: placeData.placeId,
        placeName: placeData.placeName,
        placeType: placeData.placeType,
        postalCode: placeData.postalCode,
        state: placeData.state,
      );

  Widget _buildTabBar() => ValueListenableBuilder<bool>(
      valueListenable: _tabsVisibilityNotifier,
      builder: (context, value, child) => value == true
          ? Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + IsrDimens.twenty),
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
                        labelColor: _tabDataModelList[_currentIndex].reelsDataList.isListEmptyOrNull
                            ? IsrColors.black
                            : IsrColors.white,
                        unselectedLabelColor:
                            _tabDataModelList[_currentIndex].reelsDataList.isListEmptyOrNull
                                ? IsrColors.black
                                : IsrColors.white.changeOpacity(0.6),
                        indicatorColor:
                            _tabDataModelList[_currentIndex].reelsDataList.isListEmptyOrNull
                                ? IsrColors.black
                                : IsrColors.white,
                        indicatorWeight: 3,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.label,
                        padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
                        labelPadding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.eight),
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
        widget.tabDataModelList[0].postSectionType == PostSectionType.following &&
        widget.tabDataModelList[0].reelsDataList.isListEmptyOrNull;
    return isFollowingPostEmpty;
  }

  Future<int> _handleCommentAction(
      String postId, int totalCommentsCount, PostSectionType postSectionType) async {
    final completer = Completer<int>();

    final result = await Utility.showBottomSheet<int>(
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _socialPostBloc),
          BlocProvider.value(value: context.getOrCreateBloc<CommentActionCubit>()),
          BlocProvider.value(value: context.getOrCreateBloc<SearchUserBloc>()),
        ],
        child: CommentsBottomSheet(
          postId: postId,
          totalCommentsCount: totalCommentsCount,
          onTapProfile: (userId) {
            context.pop(totalCommentsCount);
          },
          onTapHasTag: (hashTag) {
            context.pop(totalCommentsCount);
            _redirectToHashtag(hashTag, postSectionType, null);
          },
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
    Function(String)? onTapProfilePicture,
  ) {
    _goToPostListingView(postSectionType, tag ?? '', TagType.hashtag, onTapProfilePicture);
  }

  void _goToPostListingView(
    PostSectionType postTabType,
    String tagValue,
    TagType tagType,
    Function(String)? onTapProfilePicture,
  ) async {
    // ✅ Navigation now works because we wrap PostListingView with BlocProvider during navigation
    IsrAppNavigator.navigateToPostListing(
      context,
      tagValue: tagValue,
      tagType: tagType,
      onTapProfilePicture: onTapProfilePicture,
    );
  }

  Future<List<MentionMetaData>> _showMentionList(
    List<MentionMetaData> mentionList,
    PostSectionType postSectionType,
    TimeLineData postData,
  ) async {
    final updatedMentionList = await Utility.showBottomSheet<List<MentionMetaData>>(
      isScrollControlled: true,
      child: MentionListBottomSheet(
        initialMentionList: [],
        postData: postData,
        myUserId: '',
        onTapUserProfile: (userId) {
          context.pop();
          _tabDataModelList[_currentIndex].onTapUserProfile?.call(userId);
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
  Future<dynamic> _handleMoreOptions(TimeLineData postDataModel, TabDataModel tabData) async {
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
                onComplete: (success) {
                  if (success) {
                    Utility.showInSnackBar(IsrTranslationFile.postReportedSuccessfully, context,
                        isSuccessIcon: true);
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
                    Utility.showToastMessage(IsrTranslationFile.postDeletedSuccessfully);
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
          final postDataString = await _showEditPostDialog(context, postDataModel);
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
    tabData.onDeletePostSuccess?.call(postId, tabData.reelsDataList.isEmpty);
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
    await Utility.showBottomSheet(
      isDismissible: true,
      child: MoreOptionsBottomSheet(
        onPressReport: ({String message = '', String reason = ''}) async {
          try {
            if (onPressReport != null) {
              final isReported = await onPressReport(message: message, reason: reason);
              completer.complete(isReported);
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
              final postData =
                  TimeLineData.fromMap(jsonDecode(postDataString) as Map<String, dynamic>);
              final reelData = _getReelData(postData, tabData);
              completer.complete(reelData);
            }
            return postDataString;
          }
          return '';
        },
        onShowPostInsight: onShowPostInsight,
      ),
    );
    return completer.future;
  }

  Future<bool?> _showReportPostDialog(BuildContext context) => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.reportPost,
                  style: IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w700),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.deletePost,
                  style: IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w700),
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

  Future<String?> _showEditPostDialog(BuildContext context, TimeLineData postDataModel) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.editPost,
                  style: IsrStyles.primaryText18.copyWith(fontWeight: FontWeight.w700),
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
                        final postDataString = await _handleEditPost(postDataModel);
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
        postData: postDataModel, onTagProduct: widget.onTagProduct);
    return postDataString;
  }
}
