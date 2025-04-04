import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IsrPostView extends StatefulWidget {
  const IsrPostView({
    super.key,
    // this.followingPosts,
    // this.trendingPosts,
    required this.tabDataModelList,
  });

  // final List<PostDataModel>? followingPosts;
  // final List<PostDataModel>? trendingPosts;
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
                              // children: [
                              //   SmartRefresher(
                              //     controller: _followingRefreshController,
                              //     physics: const ClampingScrollPhysics(),
                              //     onRefresh: () async {
                              //       // InjectionUtils.getBloc<PostBloc>().add(GetFollowingPostEvent(
                              //       //   isLoading: false,
                              //       //   isPagination: false,
                              //       //   isRefresh: true,
                              //       // ));
                              //     },
                              //     child: const FollowingPostWidget(),
                              //   ),
                              //   // SmartRefresher(
                              //   //   controller: _trendingRefreshController,
                              //   //   physics: const ClampingScrollPhysics(),
                              //   //   onRefresh: () async {
                              //   //     // InjectionUtils.getBloc<PostBloc>().add(GetTrendingPostEvent(
                              //   //     //   isLoading: false,
                              //   //     //   isPagination: false,
                              //   //     //   isRefresh: true,
                              //   //     // ));
                              //   //   },
                              //   //   child: const TrendingPostWidget(),
                              //   // ),
                              // ],
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
                  unselectedLabelColor: IsrColors.white.applyOpacity(0.6),
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
    final postBloc = IsmInjectionUtils.getBloc<PostBloc>();
    _postTabController?.addListener(() {
      IsmInjectionUtils.getBloc<PostBloc>()
          .add(FollowingPostsLoadedEvent(widget.tabDataModelList[_postTabController!.index].postList));
      // postBloc.add(FollowingPostsLoadedEvent(widget.followingPosts!));
      // if (_postTabController?.index == 0) {
      //   postBloc.add(FollowingPostsLoadedEvent(widget.tabDataModelList?[_postTabController!.index].postList));
      //   // Following tab selected
      //   // postBloc.add(FollowingPostsLoadedEvent(widget.followingPosts!));
      // } else {
      //   postBloc.add(TrendingPostsLoadedEvent(widget.tabDataModelList?[_postTabController!.index].postList));
      //   // Trending tab selected
      //   // postBloc.add(TrendingPostsLoadedEvent(widget.trendingPosts!));
      // }
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
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1)); // Simulate a delay
          // Call refreshComplete() when done
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
        ),
      );
}
