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
      final newIndex = _postTabController?.index ?? 0;
      if (_isFollowingPostsEmpty()) {
        // _tabsVisibilityNotifier.value = false;
        _postTabController?.animateTo(0);
        return;
      }
      _currentIndex = newIndex;
      // postBloc.add(PostsLoadedEvent([],
      //     _tabDataModelList[_currentIndex].postList));
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
              _loggedInUserId = state is UserInformationLoaded ? state.userId : '';
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
                        labelColor: _isFollowingPostsEmpty() ? IsrColors.black : IsrColors.white,
                        unselectedLabelColor: _isFollowingPostsEmpty()
                            ? IsrColors.black
                            : IsrColors.white.changeOpacity(0.6),
                        indicatorColor:
                            _isFollowingPostsEmpty() ? IsrColors.black : IsrColors.white,
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
    _postTabController?.dispose();
    // Dispose each RefreshController
    for (var controller in _refreshControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTabBarView(TabDataModel tabData, int index) => PostItemWidget(
        key: ValueKey(tabData.reelsDataList.length),
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
        onRefresh: _tabDataModelList[index].onRefresh,
        startingPostIndex: _tabDataModelList[index].startingPostIndex,
      );

  // bool _isFollowingPostsEmpty() =>
  //     _currentIndex == 0 &&
  //     _tabDataModelList[_currentIndex].postSectionType == PostSectionType.following &&
  //     _tabDataModelList[_currentIndex].postList.isListEmptyOrNull;

  bool _isFollowingPostsEmpty() => false;
}
