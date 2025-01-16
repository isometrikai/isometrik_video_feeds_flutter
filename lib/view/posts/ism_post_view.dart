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
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => isrGetIt<PostBloc>(),
        child: AnnotatedRegion(
          value: const SystemUiOverlayStyle(
            statusBarColor: IsrColors.transparent,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.black12,
            body: BlocBuilder<PostBloc, PostState>(
              buildWhen: (previousState, currentState) => currentState is UserInformationLoaded,
              builder: (context, state) {
                _userInfoClass = state is UserInformationLoaded ? state.userInfoClass : null;
                return state is PostInitial
                    ? state.isLoading == true
                        ? Center(child: IsmVideoReelUtility.loaderWidget())
                        : const SizedBox.shrink()
                    : state is UserInformationLoaded
                        ? DefaultTabController(
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
                                    width: IsrDimens.getScreenWidth(context),
                                    margin: IsrDimens.edgeInsets(top: IsrDimens.fifty),
                                    padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.fifteen),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: IsrDimens.percentWidth(.45),
                                          height: IsrDimens.sixty,
                                          child: Theme(
                                            data: ThemeData(
                                              splashColor: IsrColors.transparent,
                                              highlightColor: IsrColors.transparent,
                                            ),
                                            child: TabBar(
                                              dividerColor: IsrColors.transparent,
                                              controller: _postTabController,
                                              indicatorColor: IsrColors.primaryTextColor,
                                              labelPadding: IsrDimens.edgeInsetsAll(IsrDimens.zero),
                                              indicatorPadding: IsrDimens.edgeInsetsAll(IsrDimens.zero),
                                              indicatorSize: TabBarIndicatorSize.label,
                                              indicator: UnderlineTabIndicator(
                                                borderSide: BorderSide(
                                                  width: IsrDimens.two,
                                                  color: IsrColors.white,
                                                ),
                                                insets: IsrDimens.edgeInsets(
                                                  bottom: IsrDimens.ten,
                                                ),
                                              ),
                                              unselectedLabelColor: IsrColors.white.applyOpacity(0.6),
                                              labelColor: IsrColors.white,
                                              padding: IsrDimens.edgeInsetsAll(IsrDimens.zero),
                                              automaticIndicatorColorAdjustment: true,
                                              unselectedLabelStyle:
                                                  IsrStyles.white16.copyWith(fontWeight: FontWeight.w600),
                                              labelStyle: IsrStyles.primaryText16.copyWith(fontWeight: FontWeight.w600),
                                              tabs: [
                                                SizedBox(
                                                  height: IsrDimens.thirty,
                                                  child: Tab(
                                                    iconMargin: IsrDimens.edgeInsetsAll(IsrDimens.zero),
                                                    child: Padding(
                                                      padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.five),
                                                      child: const Text(
                                                        IsrTranslationFile.following,
                                                        softWrap: false,
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.visible,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: IsrDimens.thirty,
                                                  child: Tab(
                                                    iconMargin: IsrDimens.edgeInsetsAll(IsrDimens.zero),
                                                    child: Padding(
                                                      padding: IsrDimens.edgeInsetsAll(IsrDimens.five),
                                                      child: const Text(
                                                        IsrTranslationFile.trending,
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
                                                        isrGetIt<PostBloc>().add(CameraEvent());
                                                      },
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.add_circle_outline),
                                              ),
                                              AppImage.network(
                                                _userInfoClass?.profilePic ?? '',
                                                isProfileImage: true,
                                                name: '${_userInfoClass?.firstName} ${_userInfoClass?.lastName}',
                                                height: IsrDimens.thirty,
                                                width: IsrDimens.thirty,
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
                          )
                        : const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

  void _onStartInit() {
    if (!IsmVideoReelConfig.isSdkInitialize) {
      IsmVideoReelUtility.showToastMessage('sdk not initialized');
      return;
    }
    _postBloc = isrGetIt<PostBloc>();
    _postTabController = TabController(length: 2, vsync: this);
    _postBloc?.add(const StartPost());
  }
}
