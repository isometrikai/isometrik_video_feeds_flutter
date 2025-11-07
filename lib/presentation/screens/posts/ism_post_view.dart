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
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IsmPostView extends StatefulWidget {
  const IsmPostView({
    super.key,
    required this.tabDataModelList,
    this.currentIndex = 0,
    this.allowImplicitScrolling = false,
    this.onPageChanged,
    this.onTabChanged,
  });

  final List<TabDataModel> tabDataModelList;
  final num? currentIndex;
  final bool? allowImplicitScrolling;
  final Function(int, String)? onPageChanged;
  final Function(int)? onTabChanged;

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
  final _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
  var _isBottomSheetOpen = false;

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
    var postBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
    if (postBloc.isClosed) {
      isrConfigureInjection();
      postBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
    }

    _tabsVisibilityNotifier.value = _tabDataModelList.length > 1;

    if (_isFollowingPostsEmpty()) {
      // _tabsVisibilityNotifier.value = false;
    }
    _postTabController?.addListener(() {
      if (!mounted) return;
      final newIndex = _postTabController?.index ?? 0;
      if (_currentIndex != newIndex) {
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
      }
    });
    postBloc.add(const StartPost());
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: IsrColors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        child: BlocProvider<SocialPostBloc>(
          create: (context) => IsmInjectionUtils.getBloc<SocialPostBloc>(),
          child: BlocConsumer<SocialPostBloc, SocialPostState>(
            listenWhen: (previousState, currentState) =>
                currentState is SocialPostLoadedState,
            listener: (context, state) {
              if (state is SocialPostLoadedState) {
                for (var i = 0; i < _tabDataModelList.length; i++) {
                  if (_tabDataModelList[i].reelsDataList.isListEmptyOrNull) {
                    if (_tabDataModelList[i].postSectionType ==
                        PostSectionType.following) {
                      final postList = state.timeLinePosts;
                      final reelDataList = postList
                          .map((post) =>
                              _getReelData(post, PostSectionType.following))
                          .toList();
                      _tabDataModelList[i].reelsDataList = reelDataList;
                    }
                    if (_tabDataModelList[i].postSectionType ==
                        PostSectionType.forYou) {
                      final postList = state.forYouPosts;
                      final reelDataList = postList
                          .map((post) =>
                              _getReelData(post, PostSectionType.forYou))
                          .toList();
                      _tabDataModelList[i].reelsDataList = reelDataList;
                    }
                    if (_tabDataModelList[i].postSectionType ==
                        PostSectionType.trending) {
                      final postList = state.trendingPosts;
                      final reelDataList = postList
                          .map((post) =>
                              _getReelData(post, PostSectionType.trending))
                          .toList();
                      _tabDataModelList[i].reelsDataList = reelDataList;
                    }
                  }
                }
              }
            },
            buildWhen: (previousState, currentState) =>
                currentState is SocialPostLoadedState,
            builder: (context, state) {
              final newUserId =
                  state is SocialPostLoadedState ? state.userId : '';
              if (newUserId.isNotEmpty && _loggedInUserId.isEmpty) {
                // Initialize video cache manager when user logs in
                _videoCacheManager = VideoCacheManager();
              } else if (newUserId.isEmpty && _loggedInUserId.isNotEmpty) {
                // Clean up video cache manager when user logs out
                _videoCacheManager?.clearCache();
                _videoCacheManager = null;
              }
              _loggedInUserId = newUserId;
              return state is PostLoadingState
                  ? state.isLoading == true
                      ? Center(child: Utility.loaderWidget())
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
                              _buildTabBar(),
                            ],
                          ),
                        )
                      : const SizedBox.shrink();
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
            _postTabController?.animateTo(1);
          }
        },
        loggedInUserId: _loggedInUserId,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        onPageChanged: widget.onPageChanged,
        reelsDataList: tabData.reelsDataList,
        onLoadMore: () async => await _handleLoadMore(
            tabData.postSectionType ?? PostSectionType.trending),
        onRefresh: () async {
          var result = false;
          result = await tabData.onRefresh?.call() ?? false;
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
            final reelData = tabData.reelsDataList
                .firstWhere((element) => element.postId == postId);
            final productIds = <String>[];
            final socialProductList =
                reelData.tags?.products ?? <SocialProductData>[];
            for (final productItem in socialProductList) {
              productIds.add(productItem.productId ?? '');
            }
            tabData.onTapCartIcon
                ?.call(productIds, postId, reelData.userId ?? '');
          } else {}
        },
      );

  ReelsData _getReelData(
          TimeLineData postData, PostSectionType postSectionType) =>
      ReelsData(
        postSetting: PostSetting(
          isProfilePicVisible: true,
          isCreatePostButtonVisible: true,
          isCommentButtonVisible: postData.settings?.commentsEnabled == true,
          isSaveButtonVisible: true,
          isLikeButtonVisible: true,
          isShareButtonVisible: true,
          isMoreButtonVisible: true,
          isFollowButtonVisible: true,
          isUnFollowButtonVisible: true,
        ),
        mentions: postData.tags != null &&
                postData.tags?.mentions.isListEmptyOrNull == false
            ? (postData.tags?.mentions?.map(_getMentionMetaData).toList() ?? [])
            : [],
        tagDataList: postData.tags != null &&
                postData.tags?.hashtags.isListEmptyOrNull == false
            ? postData.tags?.hashtags?.map(_getMentionMetaData).toList()
            : null,
        placeDataList: postData.tags != null &&
                postData.tags?.places.isListEmptyOrNull == false
            ? postData.tags?.places?.map(_getPlaceMetaData).toList()
            : null,
        onTapMentionTag: (mentionList) async {
          if (mentionList.isListEmptyOrNull) return [];
          if (mentionList.length == 1) {
            final mention = mentionList.first;
            if (mention.tag.isStringEmptyOrNull == false) {
              _redirectToHashtag(mention.tag, postSectionType, postData);
              return null;
            } else {
              /// TODO need to check here
              // await _redirectToProfile(mention.userId ?? '', postSectionType);
              // _resumePostList(postTabType);
            }
          } else {
            return _showMentionList(mentionList, postSectionType, postData);
          }
          return mentionList;
        },
        postId: postData.id,
        onCreatePost: () async => await _handleCreatePost(postSectionType),
        tags: postData.tags,
        mediaMetaDataList:
            postData.media?.map(_getMediaMetaData).toList() ?? [],
        // actionWidget: _buildActionButtons(postData),
        // footerWidget: _buildFooter(postData),
        userId: postData.user?.id ?? '',
        userName: postData.user?.username ?? '',
        profilePhoto: postData.user?.avatarUrl ?? '',
        firstName: '',
        lastName: '',
        likesCount: postData.engagementMetrics?.likeTypes?.love?.toInt() ?? 0,
        commentCount: postData.engagementMetrics?.comments?.toInt() ?? 0,
        isFollow: postData.isFollowing == true,
        isLiked: postData.isLiked,
        isSavedPost: false,
        isVerifiedUser: false,
        productCount: postData.tags?.products?.length ?? 0,
        description: postData.caption ?? '',
        onTapUserProfile: (isSelfProfile) {
          debugPrint('onTapUserProfile: $isSelfProfile');
        },
        onTapComment: (totalCommentsCount) async {
          final result =
              await _handleCommentAction(postData.id ?? '', totalCommentsCount);
          return result;
        },
        onPressMoreButton: () async {
          // final result = await _handleMoreOptions(postData);
          return null;
        },
        onPressLike: (isLiked) async => _handleLikeAction(isLiked, postData),
        onDoubleTap: (isLiked) async => _handleLikeAction(isLiked, postData),
        onPressSave: (isSavedPost) async {
          try {
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
              followAction:
                  isFollow ? FollowAction.unfollow : FollowAction.follow,
            ));
            return await completer.future;
          } catch (e) {
            return false;
          }
        },
        // onTapCartIcon: () {
        //   _handleCartAction(postData);
        // },
      );

  /// Handles the more options menu for a post
  // Future<dynamic> _handleMoreOptions(TimeLineData postDataModel) async {
  //   try {
  //     return await _showMoreOptionsDialog(
  //       onPressReport: ({String message = '', String reason = ''}) async {
  //         final result = await _showReportPostDialog(context);
  //
  //         if (result == true) {
  //           final completer = Completer<bool>();
  //           _socialPostBloc.add(
  //             ReportPostEvent(
  //               postId: postDataModel.id ?? '',
  //               message: message,
  //               reason: reason,
  //               onComplete: (success) {
  //                 if (success) {
  //                   Utility.showInSnackBar(TranslationFile.postReportedSuccessfully, context,
  //                       isSuccessIcon: true);
  //                 }
  //                 completer.complete(success);
  //               },
  //             ),
  //           );
  //           return await completer.future;
  //         } else {
  //           return false;
  //         }
  //       },
  //       onDeletePost: () async {
  //         final result = await _showDeletePostDialog(context);
  //         if (result == true) {
  //           final completer = Completer<bool>();
  //           _socialPostBloc.add(
  //             DeletePostEvent(
  //               postId: postDataModel.id ?? '',
  //               onComplete: (success) {
  //                 if (success) {
  //                   Utility.showToastMessage(TranslationFile.postDeletedSuccessfully);
  //                   _removePostFromList(postDataModel.id ?? '');
  //                 }
  //                 completer.complete(success);
  //               },
  //             ),
  //           );
  //           return await completer.future;
  //         }
  //         return false;
  //       },
  //       isSelfProfile: postDataModel.user?.id == _myUserId,
  //       onEditPost: () async {
  //         final postDataString = await _showEditPostDialog(context, postDataModel);
  //         return postDataString ?? '';
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('Error handling more options: $e');
  //     return false;
  //   }
  // }

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
  Future<List<ReelsData>> _handleLoadMore(
      PostSectionType postSectionType) async {
    try {
      final completer = Completer<List<TimeLineData>>();
      _socialPostBloc.add(GetMorePostEvent(
        isLoading: false,
        isPagination: true,
        isRefresh: false,
        postSectionType: postSectionType,
        memberUserId: '',
        onComplete: completer.complete,
      ));
      final timeLinePostList = await completer.future;
      if (timeLinePostList.isEmpty) return [];
      final timeLineReelDataList = timeLinePostList
          .map((post) => _getReelData(post, postSectionType))
          .toList();
      return timeLineReelDataList;
    } catch (e) {
      debugPrint('Error handling load more: $e');
      return [];
    }
  }

  // Interaction handlers
  Future<ReelsData?> _handleCreatePost(PostSectionType postSectionType) async {
    final completer = Completer<ReelsData>();
    final postDataModelString =
        await IsmInjectionUtils.getRouteManagement().goToCreatePostView();
    if (postDataModelString.isStringEmptyOrNull == false) {
      final postDataModel = TimeLineData.fromMap(
          jsonDecode(postDataModelString!) as Map<String, dynamic>);
      final reelsData = _getReelData(postDataModel, postSectionType);
      completer.complete(reelsData);
    }
    return completer.future;
  }

  MediaMetaData _getMediaMetaData(MediaData mediaData) => MediaMetaData(
        mediaType: mediaData.mediaType == 'image' ? 0 : 1,
        mediaUrl: mediaData.url ?? '',
        thumbnailUrl: mediaData.previewUrl ?? '',
      );

  MentionMetaData _getMentionMetaData(MentionData mentionData) =>
      MentionMetaData(
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
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + IsrDimens.twenty),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Theme(
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
                ],
              ),
            )
          : const SizedBox.shrink());

  @override
  void dispose() {
    // Then dispose other controllers
    _postTabController?.dispose();
    for (var controller in _refreshControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // Track refresh count for each tab to force rebuild on refresh
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

  /// Handles comment action
  Future<int> _handleCommentAction(
      String postId, int totalCommentsCount) async {
    final completer = Completer<int>();

    final result = await Utility.showBottomSheet<int>(
      child: CommentsBottomSheet(
        postId: postId,
        totalCommentsCount: totalCommentsCount,
        onTapProfile: (userId) {
          context.pop(totalCommentsCount);

          /// TODO complete this
          // _socialPostBloc.add(
          //   RedirectToProfileViewEvent(
          //     userId: userId,
          //     onComplete: (isCompleted) {
          //       if (isCompleted) {
          //         _startingTrendingPostIndex = _pageIndex;
          //         _socialPostBloc.add(
          //           SocialPostInitialEvent(
          //             isFromNavigation: widget.isFromNavigation,
          //             // postDataList: widget.postDataList,
          //             postDataList: [],
          //             postTabType: widget.postTabType,
          //             memberUserId: widget.memberUserId,
          //             postId: widget.postId,
          //           ),
          //         );
          //       }
          //     },
          //   ),
          // );
        },
        onTapHasTag: (hashTag) {
          /// TODO complete this
          // InjectionUtils.getRouteManagement()
          //     .goToPostListingScreen(tagValue: hashTag, tagType: TagType.hashtag);
        },
      ),
      isDarkBG: true,
      backgroundColor: Colors.black,
    );
    completer.complete(result ?? 0);

    return completer.future;
  }

  void _redirectToHashtag(
      String? tag, PostSectionType postSectionType, TimeLineData postData) {
    _goToPostListingView(postSectionType, tag ?? '', TagType.hashtag);
  }

  void _showPlaceList(
      List<PlaceMetaData> placeList, PostTabType postTabType) async {
    await Utility.showBottomSheet(child: Container());
  }

  void _goToPostListingView(
      PostSectionType postTabType, String tagValue, TagType tagType) async {
    await IsmInjectionUtils.getRouteManagement()
        .goToPostListingScreen(tagValue: tagValue, tagType: tagType);
    // _resumePostList(postTabType);
  }

  Future<List<MentionMetaData>> _showMentionList(
    List<MentionMetaData> mentionList,
    PostSectionType postSectionType,
    TimeLineData postData,
  ) async {
    _isBottomSheetOpen = true;
    final updatedMentionList =
        await Utility.showBottomSheet<List<MentionMetaData>>(
      isScrollControlled: true,
      child: _MentionListBottomSheet(
        initialMentionList: mentionList,
        postData: postData,
        myUserId: '',

        /// TODO here need to pass loggedIN user id
        socialPostBloc: _socialPostBloc,
        onTapUserProfile: (userId) {
          /// TODO need to check
          // _redirectToProfile(userId, postSectionType);
        },
      ),
    );
    _isBottomSheetOpen = false;
    return updatedMentionList ?? mentionList;
  }
}

class _MentionListBottomSheet extends StatefulWidget {
  const _MentionListBottomSheet({
    required this.initialMentionList,
    required this.postData,
    required this.myUserId,
    required this.socialPostBloc,
    required this.onTapUserProfile,
  });

  final List<MentionMetaData> initialMentionList;
  final TimeLineData postData;
  final String myUserId;
  final SocialPostBloc socialPostBloc;
  final Function(String) onTapUserProfile;

  @override
  State<_MentionListBottomSheet> createState() =>
      _MentionListBottomSheetState();
}

class _MentionListBottomSheetState extends State<_MentionListBottomSheet> {
  late List<MentionMetaData> _mentionList;
  final List<SocialUserData> _socialUserList = [];
  late SocialPostBloc _socialPostBloc;

  @override
  void initState() {
    super.initState();
    _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
    _mentionList = List.from(widget.initialMentionList);
    _socialPostBloc.add(GetMentionedUserEvent(
        postId: widget.postData.id ?? '',
        onComplete: (mentionedList) {
          if (mounted && mentionedList.isNotEmpty) {
            setState(() {
              _socialUserList.clear();
              _socialUserList.addAll(mentionedList);
            });
          }
        }));
    // If no mentions initially, dismiss the bottom sheet immediately
    if (_mentionList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop(_mentionList); // Return empty list
        }
      });
    }
  }

  void _removeMentionFromList(String userId) {
    // If this is the last mention, dismiss immediately without updating UI
    if (_mentionList.length == 1 && _mentionList.first.userId == userId) {
      context.pop(_mentionList); // Return empty list
      return;
    }

    setState(() {
      _mentionList.removeWhere((mention) => mention.userId == userId);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            context.pop(_mentionList);
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: IsrColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(IsrDimens.twenty),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.sixteen,
                  vertical: IsrDimens.twenty,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      IsrTranslationFile.inThisSocialPost,
                      style: IsrStyles.primaryText18.copyWith(
                        fontWeight: FontWeight.w600,
                        color: IsrColors.black,
                      ),
                    ),
                    TapHandler(
                      onTap: () {
                        context.pop(_mentionList);
                      },
                      child: Container(
                        padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
                        child: Icon(
                          Icons.close,
                          color: IsrColors.black,
                          size: IsrDimens.twentyFour,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // User List
              Flexible(
                child: _mentionList.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
                          child: Text(
                            'No mentions found',
                            style: IsrStyles.primaryText14.copyWith(
                              color: IsrColors.grey,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _mentionList.length,
                        itemBuilder: (context, index) {
                          final mentionedData = _mentionList[index];
                          final socialUserData = _socialUserList
                              .firstWhere(
                                  (_) =>
                                      _.id?.takeIfNotEmpty() != null &&
                                      _.id == mentionedData.userId,
                                  orElse: SocialUserData.new)
                              .takeIf((_) => _.id?.takeIfNotEmpty() != null);
                          return _buildProfileItem(
                              mentionedData, socialUserData, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfileItem(MentionMetaData mentionedData,
          SocialUserData? socialUserData, int index) =>
      TapHandler(
        onTap: () {
          widget.onTapUserProfile(mentionedData.userId ?? '');
          context.pop(_mentionList);
        },
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.sixteen,
            vertical: IsrDimens.twelve,
          ),
          decoration: BoxDecoration(
            border: index < _mentionList.length - 1
                ? const Border(
                    bottom: BorderSide(
                      color: IsrColors.colorDBDBDB,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Profile Picture
              Container(
                width: IsrDimens.forty,
                height: IsrDimens.forty,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: IsrColors.colorDBDBDB,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: AppImage.network(
                    socialUserData?.avatarUrl?.takeIfNotEmpty() ??
                        mentionedData.avatarUrl ??
                        '',
                    height: IsrDimens.forty,
                    width: IsrDimens.forty,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              IsrDimens.boxWidth(IsrDimens.twelve),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        socialUserData?.displayName?.takeIfNotEmpty() ??
                            mentionedData.name?.takeIfNotEmpty() ??
                            mentionedData.username ??
                            'Unknown User',
                        style: IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: IsrColors.black,
                        ),
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.four),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        socialUserData?.username?.takeIfNotEmpty() ??
                            mentionedData.username ??
                            '',
                        style: IsrStyles.primaryText12.copyWith(
                          color: '767676'.toColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              10.responsiveHorizontalSpace,
              // Action Button
              _buildFollowFollowingButton(
                mentionedData,
                socialUserData?.isFollowing ?? false,
                widget.postData.id ?? '',
              ),
            ],
          ),
        ),
      );

  Widget _buildFollowFollowingButton(
    MentionMetaData mentionedData,
    bool isFollow,
    String postId,
  ) {
    final userId = mentionedData.userId ?? '';
    var isLoading = false;
    var isFollowing = isFollow;

    return StatefulBuilder(
      builder: (context, setState) => userId == widget.myUserId
          ? AppButton(
              height: 36.responsiveDimension,
              width: 95.responsiveDimension,
              type: ButtonType.secondary,
              borderRadius: 40.responsiveDimension,
              title: IsrTranslationFile.remove,
              isLoading: isLoading,
              textStyle: IsrStyles.primaryText12.copyWith(
                fontWeight: FontWeight.w600,
              ),
              onPress: isLoading == true
                  ? null
                  : () {
                      isLoading = true;
                      setState.call(() {});
                      widget.socialPostBloc.add(RemoveMentionEvent(
                        postId:
                            postId, // This should be the actual post ID, not user ID
                        onComplete: (isSuccess) {
                          isLoading = false;
                          if (isSuccess) {
                            // Remove the mention from the list
                            _removeMentionFromList(userId);
                          }
                          setState.call(() {});
                        },
                      ));
                    },
            )
          : AppButton(
              onPress: isLoading == true
                  ? null
                  : () {
                      isLoading = true;
                      setState.call(() {});
                      widget.socialPostBloc.add(FollowUserEvent(
                          followingId: userId,
                          onComplete: (isSuccess) {
                            isLoading = false;
                            if (isSuccess) {
                              isFollowing = !isFollowing;
                            }
                            setState.call(() {});
                          },
                          followAction: isFollowing
                              ? FollowAction.unfollow
                              : FollowAction.follow));
                    },
              height: 36.responsiveDimension,
              width: 95.responsiveDimension,
              borderRadius: 40.responsiveDimension,
              borderColor:
                  isFollowing ? IsrColors.appColor : IsrColors.transparent,
              backgroundColor:
                  isFollowing ? IsrColors.white : IsrColors.appColor,
              title: isFollowing
                  ? IsrTranslationFile.following
                  : IsrTranslationFile.follow,
              isLoading: isLoading,
              textStyle: IsrStyles.primaryText12.copyWith(
                color: isFollowing ? IsrColors.appColor : IsrColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
