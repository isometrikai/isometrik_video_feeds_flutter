import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/export.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IsmPostView extends StatefulWidget {
  const IsmPostView({super.key});

  @override
  State<IsmPostView> createState() => _PostViewState();
}

class _PostViewState extends State<IsmPostView> with TickerProviderStateMixin {
  PostBloc? _postBloc;
  TabController? _postTabController;
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
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => kGetIt<PostBloc>()),
        ],
        child: BlocProvider(
          create: (context) => kGetIt<PostBloc>(),
          child: AnnotatedRegion(
            value: const SystemUiOverlayStyle(
              statusBarColor: AppColors.transparent,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
            child: BlocListener<PostBloc, PostState>(
              listener: (context, state) {},
              child: DefaultTabController(
                length: 2,
                child: Scaffold(
                  backgroundColor: Colors.black,
                  body: Stack(
                    children: [
                      TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _postTabController,
                        children: [
                          SmartRefresher(
                            controller: _followingRefreshController,
                            physics: const ClampingScrollPhysics(),
                            onRefresh: () async {},
                            child: FollowingPostWidget(),
                          ),
                          SmartRefresher(
                            controller: _trendingRefreshController,
                            physics: const ClampingScrollPhysics(),
                            onRefresh: () async {},
                            child: TrendingPostWidget(),
                          ),
                        ],
                      ),
                      Container(
                        width: Dimens.getScreenWidth(context),
                        margin: Dimens.edgeInsets(top: Dimens.fifty),
                        padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.fifteen),
                        child: Row(
                          children: [
                            SizedBox(
                              width: Dimens.percentWidth(.45),
                              height: Dimens.sixty,
                              child: Theme(
                                data: ThemeData(
                                  splashColor: AppColors.transparent,
                                  highlightColor: AppColors.transparent,
                                ),
                                child: TabBar(
                                  dividerColor: AppColors.transparent,
                                  controller: _postTabController,
                                  indicatorColor: AppColors.primaryTextColor,
                                  labelPadding: Dimens.edgeInsetsAll(Dimens.zero),
                                  indicatorPadding: Dimens.edgeInsetsAll(Dimens.zero),
                                  indicatorSize: TabBarIndicatorSize.label,
                                  indicator: UnderlineTabIndicator(
                                    borderSide: BorderSide(
                                      width: Dimens.two,
                                      color: AppColors.white,
                                    ),
                                    insets: Dimens.edgeInsets(
                                      bottom: Dimens.ten,
                                    ),
                                  ),
                                  unselectedLabelColor: AppColors.white.applyOpacity(0.6),
                                  labelColor: AppColors.white,
                                  padding: Dimens.edgeInsetsAll(Dimens.zero),
                                  automaticIndicatorColorAdjustment: true,
                                  unselectedLabelStyle: Styles.white16.copyWith(fontWeight: FontWeight.w600),
                                  labelStyle: Styles.primaryText16.copyWith(fontWeight: FontWeight.w600),
                                  tabs: [
                                    SizedBox(
                                      height: Dimens.thirty,
                                      child: Tab(
                                        iconMargin: Dimens.edgeInsetsAll(Dimens.zero),
                                        child: Padding(
                                          padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.five),
                                          child: const Text(
                                            TranslationFile.following,
                                            softWrap: false,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: Dimens.thirty,
                                      child: Tab(
                                        iconMargin: Dimens.edgeInsetsAll(Dimens.zero),
                                        child: Padding(
                                          padding: Dimens.edgeInsetsAll(Dimens.five),
                                          child: const Text(
                                            TranslationFile.trending,
                                            softWrap: false,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      IsmVideoReelUtility.showBottomSheet(
                                        CreatePostBottomSheet(
                                          onCreateNewPost: () {
                                            kGetIt<PostBloc>().add(CameraEvent());
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  AppImage.network(
                                    _postBloc?.getProfileImageUrl() ?? '',
                                    isProfileImage: true,
                                    name: _postBloc?.getProfileName() ?? '',
                                    height: Dimens.thirty,
                                    width: Dimens.thirty,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  void _onStartInit() {
    if (!IsmVideoReelConfig.isSdkInitialize) {
      IsmVideoReelUtility.showToastMessage('sdk not initialized');
      return;
    }
    ;
    _postBloc = kGetIt<PostBloc>();
    _postBloc?.add(const StartPost());
    _postBloc?.add(GetFollowingPostEvent(isLoading: false));
    _postTabController = TabController(length: 2, vsync: this);
  }
}
