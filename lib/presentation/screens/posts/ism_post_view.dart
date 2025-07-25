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
  final Function(int)? onPageChanged;

  @override
  State<IsmPostView> createState() => _PostViewState();
}

class _PostViewState extends State<IsmPostView> with TickerProviderStateMixin {
  TabController? _postTabController;
  late List<RefreshController> _refreshControllers;
  var _currentIndex = 1;
  var _loggedInUserId = '';
  final ValueNotifier<bool> _tabsVisibilityNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _onStartInit();
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
                IsmInjectionUtils.getBloc<PostBloc>()
                    .add(PostsLoadedEvent(widget.tabDataModelList[_currentIndex].postList));
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
                      length: 2,
                      initialIndex: _currentIndex,
                      child: Stack(
                        children: [
                          TabBarView(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: _postTabController,
                            children: widget.tabDataModelList
                                .map((tabData) => _buildTabBarView(tabData, widget.tabDataModelList.indexOf(tabData)))
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
                        labelColor: IsrColors.white,
                        unselectedLabelColor: IsrColors.white.changeOpacity(0.6),
                        indicatorColor: IsrColors.white,
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
                        tabs: widget.tabDataModelList
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

  void _onStartInit() async {
    _currentIndex = widget.currentIndex?.toInt() ?? 0;
    if (_currentIndex >= widget.tabDataModelList.length) {
      _currentIndex = 0;
    }
    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showToastMessage('sdk not initialized');
      return;
    }
    // Initialize TabController with initialIndex = _currentIndex
    _postTabController = TabController(
      length: widget.tabDataModelList.length,
      vsync: this,
      initialIndex: _currentIndex,
    );

    _refreshControllers = List.generate(widget.tabDataModelList.length, (index) => RefreshController());
    var postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    if (postBloc.isClosed) {
      isrConfigureInjection();
      postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    }

    _tabsVisibilityNotifier.value = widget.tabDataModelList.length > 1;

    if (_currentIndex == 0 &&
        widget.tabDataModelList[_currentIndex].postSectionType == PostSectionType.following &&
        widget.tabDataModelList[_currentIndex].postList.isListEmptyOrNull) {
      _tabsVisibilityNotifier.value = false;
    }
    _postTabController?.addListener(() {
      final newIndex = _postTabController?.index ?? 0;
      if (_currentIndex == 0 &&
          widget.tabDataModelList[_currentIndex].postSectionType == PostSectionType.following &&
          widget.tabDataModelList[_currentIndex].postList.isListEmptyOrNull) {
        _tabsVisibilityNotifier.value = false;
        _postTabController?.animateTo(0);
        return;
      }
      _currentIndex = newIndex;
      postBloc.add(PostsLoadedEvent(widget.tabDataModelList[_currentIndex].postList));
    });
    postBloc.add(const StartPost());
  }

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
        onPressSave: tabData.onPressSave,
        onTapMore: tabData.onTapMore,
        onPressLike: tabData.onPressLike,
        onPressFollow: tabData.onPressFollow,
        onCreatePost: tabData.onCreatePost,
        onLoadMore: tabData.onLoadMore,
        onTapCartIcon: tabData.onTapCartIcon,
        onRefresh: tabData.onRefresh,
        placeHolderWidget: tabData.placeHolderWidget,
        postSectionType: tabData.postSectionType,
        onTapPlaceHolder: () {
          if ((_postTabController?.length ?? 0) > 1) {
            _tabsVisibilityNotifier.value = true;
            _currentIndex++;
            _postTabController?.animateTo(1);
          }
        },
        onTapComment: tabData.onTapComment,
        onTapShare: tabData.onTapShare,
        isCreatePostButtonVisible: tabData.isCreatePostButtonVisible,
        startingPostIndex: tabData.startingPostIndex,
        onTapUserProfilePic: (userId) {
          if (tabData.onTapUserProfile == null) return;
          tabData.onTapUserProfile!(userId);
        },
        loggedInUserId: _loggedInUserId,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        onPageChanged: widget.onPageChanged,
      );
}
