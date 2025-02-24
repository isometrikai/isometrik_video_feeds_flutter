import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IsrPostView extends StatefulWidget {
  const IsrPostView({super.key});

  @override
  State<IsrPostView> createState() => _PostViewState();
}

class _PostViewState extends State<IsrPostView> with TickerProviderStateMixin {
  TabController? _postTabController;
  UserInfoClass? _userInfoClass;
  final _followingRefreshController = RefreshController(
    initialRefresh: false,
    initialLoadStatus: LoadStatus.idle,
  );
  final _trendingRefreshController = RefreshController(
    initialRefresh: false,
    initialLoadStatus: LoadStatus.idle,
  );

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
          body: BlocBuilder<PostBloc, PostState>(
            buildWhen: (previousState, currentState) =>
                currentState is UserInformationLoaded || currentState is PostDataLoadedState,
            builder: (context, state) {
              _userInfoClass = state is UserInformationLoaded ? state.userInfoClass : null;
              return state is PostInitial
                  ? state.isLoading == true
                      ? Center(child: IsrVideoReelUtility.loaderWidget())
                      : const SizedBox.shrink()
                  : state is UserInformationLoaded || state is PostDataLoadedState
                      ? DefaultTabController(
                          length: 2,
                          child: Stack(
                            children: [
                              TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                controller: _postTabController,
                                children: [
                                  SmartRefresher(
                                    controller: _followingRefreshController,
                                    physics: const ClampingScrollPhysics(),
                                    onRefresh: () async {},
                                    child: const FollowingPostWidget(),
                                  ),
                                  SmartRefresher(
                                    controller: _trendingRefreshController,
                                    physics: const ClampingScrollPhysics(),
                                    onRefresh: () async {},
                                    child: const TrendingPostWidget(),
                                  ),
                                ],
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
                  tabs: [
                    const Tab(
                      child: Text(
                        IsrTranslationFile.following,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Tab(
                      child: Text(
                        IsrTranslationFile.trending,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _onStartInit() {
    if (!IsrVideoReelConfig.isSdkInitialize) {
      IsrVideoReelUtility.showToastMessage('sdk not initialized');
      return;
    }
    final postBloc = InjectionUtils.getBloc<PostBloc>();
    _postTabController = TabController(length: 2, vsync: this);
    postBloc.add(const StartPost());
  }
}
