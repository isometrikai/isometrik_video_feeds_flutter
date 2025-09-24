import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IsmPostView extends StatefulWidget {
  const IsmPostView({
    super.key,
    required this.tabDataModelList,
    this.currentIndex = 0,
    this.allowImplicitScrolling = false,
    this.onPageChanged,
  });

  final List<TabDataModel> tabDataModelList;
  final num? currentIndex;
  final bool? allowImplicitScrolling;
  final Function(int, String)? onPageChanged;

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

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() async {
    _tabDataModelList = widget.tabDataModelList;
    _currentIndex = widget.currentIndex?.toInt() ?? 0;
    if (_currentIndex >= _tabDataModelList.length) {
      _currentIndex = 0;
    }
    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showToastMessage('sdk not initialized');
      return;
    }
    // Initialize TabController with initialIndex = _currentIndex
    _postTabController = TabController(
      length: _tabDataModelList.length,
      vsync: this,
      initialIndex: _currentIndex,
    );

    _refreshControllers = List.generate(_tabDataModelList.length, (index) => RefreshController());
    var postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    if (postBloc.isClosed) {
      isrConfigureInjection();
      postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    }

    _tabsVisibilityNotifier.value = _tabDataModelList.length > 1;

    if (_isFollowingPostsEmpty()) {
      // _tabsVisibilityNotifier.value = false;
    }
    _postTabController?.addListener(() {
      if (!mounted) return;
      final newIndex = _postTabController?.index ?? 0;
      if (_currentIndex != newIndex) {
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

    if (_tabDataModelList.isListEmptyOrNull == false) {
      var tabData = _tabDataModelList[_currentIndex];
      final reelsDataList = tabData.reelsDataList;
      final listOfUrls = <String>[];
      for (var reelsData in reelsDataList) {
        listOfUrls.add(reelsData.mediaMetaDataList.first.mediaUrl);
        if (reelsData.mediaMetaDataList.first.thumbnailUrl.isStringEmptyOrNull == false) {
          listOfUrls.add(reelsData.mediaMetaDataList.first.thumbnailUrl);
        }
      }
    }
    postBloc.add(const StartPost());
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: IsrColors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        child: BlocProvider<PostBloc>(
          create: (context) => IsmInjectionUtils.getBloc<PostBloc>(),
          child: BlocConsumer<PostBloc, PostState>(
            listener: (context, state) {
              if (state is UserInformationLoaded) {
                // IsmInjectionUtils.getBloc<PostBloc>().add(PostsLoadedEvent(
                //     [],
                //     _tabDataModelList[_currentIndex].postList));
              }
            },
            buildWhen: (previousState, currentState) => currentState is UserInformationLoaded,
            builder: (context, state) {
              final newUserId = state is UserInformationLoaded ? state.userId : '';
              if (newUserId.isNotEmpty && _loggedInUserId.isEmpty) {
                // Initialize video cache manager when user logs in
                _videoCacheManager = VideoCacheManager();
              } else if (newUserId.isEmpty && _loggedInUserId.isNotEmpty) {
                // Clean up video cache manager when user logs out
                _videoCacheManager?.clearControllers();
                _videoCacheManager = null;
              }
              _loggedInUserId = newUserId;
              return state is PostInitial
                  ? state.isLoading == true
                      ? Center(child: IsrVideoReelUtility.loaderWidget())
                      : const SizedBox.shrink()
                  : DefaultTabController(
                      length: _tabDataModelList.isListEmptyOrNull ? 0 : _tabDataModelList.length,
                      initialIndex: _currentIndex,
                      child: Stack(
                        children: [
                          TabBarView(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: _postTabController,
                            children: _tabDataModelList
                                .map((tabData) =>
                                    _buildTabBarView(tabData, _tabDataModelList.indexOf(tabData)))
                                .toList(),
                          ),
                          _buildTabBar(),
                        ],
                      ),
                    );
            },
          ),
        ),
      );

  Widget _buildTabBar() => ValueListenableBuilder<bool>(
      valueListenable: _tabsVisibilityNotifier,
      builder: (context, value, child) => value == true
          ? Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + IsrDimens.twenty,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: IsrDimens.getScreenWidth(context) * 0.7,
                    child: Theme(
                      data: ThemeData(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: TabBar(
                        controller: _postTabController,
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
                        indicatorWeight: 2,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelPadding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: IsrDimens.eight,
                        ),
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
    // // Clean up video cache manager first if we have a user
    // if (_loggedInUserId.isNotEmpty && _videoCacheManager != null) {
    //   try {
    //     // Create a local reference to the cache manager and clear the field
    //     final cacheManager = _videoCacheManager;
    //     _videoCacheManager = null;
    //
    //     // Clean up in the background to avoid blocking
    //     Future.microtask(() async {
    //       try {
    //         // First pause any playing videos
    //         if (_currentIndex < _tabDataModelList.length) {
    //           final currentTabData = _tabDataModelList[_currentIndex];
    //           for (var post in currentTabData.reelsDataList) {
    //             for (var media in post.mediaMetaDataList) {
    //               if (media.mediaType == 1 && media.mediaUrl.isNotEmpty) {
    //                 final controller =
    //                     cacheManager?.getCachedController(media.mediaUrl);
    //                 if (controller?.value.isPlaying == true) {
    //                   await controller?.pause();
    //                 }
    //               }
    //             }
    //           }
    //         }
    //         // Then clear all controllers
    //         // cacheManager?.clearControllers();
    //       } catch (e) {
    //         debugPrint('Error during video cleanup: $e');
    //       }
    //     });
    //   } catch (e) {
    //     debugPrint('Error during cleanup setup: $e');
    //   }
    // }

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

  Widget _buildTabBarView(TabDataModel tabData, int index) => PostItemWidget(
        key: ValueKey(_getUniqueKey(tabData, index)),
        videoCacheManager: _loggedInUserId.isNotEmpty ? _videoCacheManager : null,
        onTapPlaceHolder: () {
          if ((_postTabController?.length ?? 0) > 1) {
            _tabsVisibilityNotifier.value = true;
            _currentIndex++;
            _postTabController?.animateTo(1);
          }
        },
        loggedInUserId: _loggedInUserId,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        onPageChanged: widget.onPageChanged,
        reelsDataList: _tabDataModelList[index].reelsDataList,
        onLoadMore: _tabDataModelList[index].onLoadMore,
        onRefresh: () async {
          var result = false;
          result = await _tabDataModelList[index].onRefresh?.call() ?? false;
          // Increment refresh count to force rebuild
          if (result) {
            setState(() {
              _refreshCounts[index] = (_refreshCounts[index] ?? 0) + 1;
            });
          }
          return result;
        },
        startingPostIndex: _tabDataModelList[index].startingPostIndex,
        postSectionType: _tabDataModelList[index].postSectionType,
      );

  bool _isFollowingPostsEmpty() {
    final isFollowingPostEmpty = widget.tabDataModelList.length > 1 &&
        widget.tabDataModelList[0].postSectionType == PostSectionType.following &&
        widget.tabDataModelList[0].reelsDataList.isListEmptyOrNull;
    return isFollowingPostEmpty;
  }
}
