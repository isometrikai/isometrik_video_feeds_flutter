import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class LandingView extends StatefulWidget {
  LandingView({
    super.key,
    required this.child,
    required this.title,
  });

  final Widget child;
  final String title;

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  final textEditingController = TextEditingController();
  DateTime? currentBackPressTime;

  var _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<NavItemCubit>().onTap(NavbarType.visibleItems[0]);
    });
  }

  @override
  void dispose() {
    super.dispose();
    kGetIt<LandingBloc>().close();
  }

  Future<bool> _onWillPop() async {
    final currentTab = context.read<NavItemCubit>().state;
    if (currentTab == NavbarType.home) {
      final now = DateTime.now();
      // If this is the first back press or more than 2 seconds have passed
      if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        currentBackPressTime = now;
        Utility.showToastMessage('Press back again to exit');
        return false;
      }
      // If second back press is within 2 seconds
      await SystemNavigator.pop();
      return true;
    } else {
      context.read<NavItemCubit>().onTap(NavbarType.home);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<LandingBloc, LandingState>(
        buildWhen: (previousState, currentState) => currentState is LandingInitialState,
        builder: (context, landingState) {
          _isLoggedIn = landingState is LandingInitialState ? landingState.isLoggedIn == true : _isLoggedIn;
          return BlocBuilder<NavItemCubit, NavbarType>(
            builder: (context, state) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (!didPop) {
                  await _onWillPop();
                }
              },
              child: Scaffold(
                backgroundColor: state == NavbarType.home ? AppColors.white : Theme.of(context).scaffoldBackgroundColor,
                appBar: state == NavbarType.home
                    ? null
                    : CustomAppBar(
                        showTitleWidget: false,
                        backgroundColor: state == NavbarType.home ? AppColors.white : AppColors.appBarColor,
                        height: state == NavbarType.home ? Dimens.zero : Dimens.fifty,
                        leadingWidth: state == NavbarType.account ? Dimens.fourteen : Dimens.eighty,
                        titleText: state == NavbarType.account ? TranslationFile.myAccount : null,
                        titleSpacing: Dimens.ten,
                        leading: state == NavbarType.account
                            ? Dimens.boxHeight(Dimens.zero)
                            : Padding(
                                padding: Dimens.edgeInsets(left: Dimens.twenty),
                                child: const AppImage.svg(
                                  AssetConstants.icAppLogo,
                                ),
                              ),
                        onTap: state == NavbarType.account
                            ? () {
                                context.read<NavItemCubit>().onTap(NavbarType.home);
                              }
                            : null,
                        showActions: state != NavbarType.account,
                      ),
                body: Column(
                  children: [
                    Expanded(child: widget.child),
                  ],
                ),
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (state != NavbarType.home) ...[
                      Divider(
                        height: Dimens.one,
                        color: AppColors.colorF0EDF6,
                      ),
                      Dimens.boxHeight(Dimens.five),
                    ],
                    Visibility(
                      visible: true,
                      child: BottomNavigationBar(
                        backgroundColor: state == NavbarType.home ? AppColors.grey : AppColors.white,
                        currentIndex: NavbarType.visibleItems.indexOf(state),
                        selectedItemColor: state == NavbarType.home ? AppColors.white : AppColors.black,
                        unselectedItemColor: state == NavbarType.home ? AppColors.primaryTextColor : AppColors.black,
                        selectedLabelStyle: state == NavbarType.home ? Styles.white12 : Styles.primaryText12,
                        unselectedLabelStyle: state == NavbarType.home ? Styles.white12 : Styles.primaryText12,
                        onTap: (index) async {
                          InjectionUtils.getBloc<LandingBloc>()
                              .add(LandingNavigationEvent(navbarType: NavbarType.visibleItems[index]));
                        },
                        items: NavbarType.visibleItems
                            .map(
                              (e) => BottomNavigationBarItem(
                                icon: AppImage.svg(
                                  state == e ? e.outlineIcon : e.filledIcon,
                                  height: Dimens.twentyFour,
                                  width: Dimens.twentyFour,
                                  color: state == NavbarType.home ? AppColors.white : null,
                                ),
                                label: e.label,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
