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

class IsrPostView extends StatefulWidget {
  const IsrPostView({
    super.key,
    required this.tabDataModelList,
  });

  final List<TabDataModel> tabDataModelList;

  @override
  State<IsrPostView> createState() => _PostViewState();
}

class _PostViewState extends State<IsrPostView> with TickerProviderStateMixin {
  TabController? _postTabController;
  late List<RefreshController> _refreshControllers;

  UserInfoClass? _userInfoClass;

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
        child: Scaffold(
          backgroundColor: Colors.black12,
          body: BlocProvider<PostBloc>(
            create: (context) => IsmInjectionUtils.getBloc<PostBloc>(),
            child: BlocConsumer<PostBloc, PostState>(
              listener: (context, state) {
                if (state is UserInformationLoaded) {
                  IsmInjectionUtils.getBloc<PostBloc>()
                      .add(FollowingPostsLoadedEvent(widget.tabDataModelList.first.postList));
                }
              },
              buildWhen: (previousState, currentState) => currentState is UserInformationLoaded,
              builder: (context, state) {
                _userInfoClass = state is UserInformationLoaded ? state.userInfoClass : null;
                return state is PostInitial
                    ? state.isLoading == true
                        ? Center(child: IsrVideoReelUtility.loaderWidget())
                        : const SizedBox.shrink()
                    : DefaultTabController(
                        length: 2,
                        child: Stack(
                          children: [
                            TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: _postTabController,
                              children: widget.tabDataModelList
                                  .map((tabData) => _buildTabBarView(tabData, widget.tabDataModelList.indexOf(tabData)))
                                  .toList(),
                            ),
                            if (widget.tabDataModelList.length > 1) _buildTabBar(),
                          ],
                        ),
                      );
              },
            ),
          ),
        ),
      );

  Widget _buildTabBar() => Container(
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
      );

  void _onStartInit() async {
    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showToastMessage('sdk not initialized');
      return;
    }
    _postTabController = TabController(length: widget.tabDataModelList.length, vsync: this);
    _refreshControllers = List.generate(widget.tabDataModelList.length, (index) => RefreshController());
    var postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    if (postBloc.isClosed) {
      isrConfigureInjection();
      postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    }
    debugPrint('PostBloc2....${postBloc.isClosed}');
    _postTabController?.addListener(() {
      postBloc.add(FollowingPostsLoadedEvent(widget.tabDataModelList[_postTabController!.index].postList));
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

  Widget _buildTabBarView(TabDataModel tabData, int index) => SmartRefresher(
        controller: _refreshControllers[index],
        physics: const ClampingScrollPhysics(),
        enablePullDown: false,
        onRefresh: () async {
          debugPrint('onRefresh......');
          // await Future.delayed(const Duration(seconds: 1)); // Simulate a delay
          // Call refreshComplete() when done
          if (tabData.onRefresh != null) {
            await tabData.onRefresh!();
          }
          _refreshControllers[index].refreshCompleted();
          // InjectionUtils.getBloc<PostBloc>().add(GetFollowingPostEvent(
          //   isLoading: false,
          //   isPagination: false,
          //   isRefresh: true,
          // ));
        },
        child: FollowingPostWidget(
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
              _postTabController?.animateTo(1);
            }
          },
        ),
      );
}
