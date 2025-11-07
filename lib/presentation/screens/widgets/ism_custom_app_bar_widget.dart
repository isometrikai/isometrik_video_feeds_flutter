import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsmCustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const IsmCustomAppBarWidget({
    super.key,
    this.statusBarColor = IsrColors.appBarColor,
    this.statusBarIconBrightness = Brightness.dark,
    this.statusBarBrightness = Brightness.light,
    this.navigationBarColor = IsrColors.navigationBar,
    this.navigationBarIconBrightness = Brightness.dark,
    this.backgroundColor = IsrColors.appBarColor,
    this.height,
    this.titleText,
    this.titleColor,
    this.titleStyle,
    this.actions,
    this.onTap,
    this.iconColor,
    this.isCrossIcon = false,
    this.showIcon = true,
    this.leading,
    this.leadingWidth,
    this.titleSpacing,
    this.centerTitle = false,
    this.showDivider = false,
    this.dividerThickNess,
    this.dividerColor,
    this.isBackButtonVisible = true,
    this.titleWidget,
    this.showActions = false,
    this.bottom,
    this.pageRouteName,
    this.showTitleWidget = true,
  });

  final Color statusBarColor;
  final Brightness statusBarIconBrightness;
  final Brightness statusBarBrightness;
  final Color navigationBarColor;
  final Brightness navigationBarIconBrightness;
  final Color backgroundColor;
  final double? height;
  final String? titleText;
  final Color? titleColor;
  final List<Widget>? actions;
  final TextStyle? titleStyle;
  final Color? iconColor;
  final void Function()? onTap;
  final bool isCrossIcon;
  final Widget? leading;
  final bool showIcon;
  final double? leadingWidth;
  final double? titleSpacing;
  final bool centerTitle;
  final bool showDivider;
  final double? dividerThickNess;
  final Color? dividerColor;
  final bool isBackButtonVisible;
  final Widget? titleWidget;
  final bool? showActions;
  final PreferredSize? bottom;
  final String? pageRouteName;
  final bool? showTitleWidget;

  @override
  Size get preferredSize => Size(IsrDimens.percentWidth(1), height ?? IsrDimens.appBarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: statusBarColor,
          statusBarIconBrightness: statusBarIconBrightness,
          statusBarBrightness: statusBarBrightness,
          systemNavigationBarColor: navigationBarColor,
          systemNavigationBarIconBrightness: navigationBarIconBrightness,
        ),
        leadingWidth: isBackButtonVisible == false ? IsrDimens.twenty : leadingWidth,
        titleSpacing: titleSpacing ?? IsrDimens.zero,
        toolbarHeight: height,
        leading: isBackButtonVisible
            ? leading ??
                (showIcon
                    ? TapHandler(
                        onTap: onTap ?? context.pop,
                        child: UnconstrainedBox(
                          child: AppImage.svg(
                            isCrossIcon
                                ? AssetConstants.icCrossIcon
                                : AssetConstants.icLeftArrowIcon,
                            color: iconColor ?? titleColor ?? IsrColors.black,
                          ),
                        ),
                      )
                    : null)
            : IsrDimens.boxHeight(IsrDimens.zero),
        automaticallyImplyLeading: false,
        centerTitle: centerTitle,
        titleTextStyle: titleStyle ?? Theme.of(context).appBarTheme.titleTextStyle,
        toolbarTextStyle: Theme.of(context).appBarTheme.toolbarTextStyle,
        title: titleText == null
            ? showTitleWidget ?? false
                ? TapHandler(
                    onTap: () {
                      context.pop();
                    },
                    child: AppImage.svg(
                      AssetConstants.icAppBarIcon,
                      width: IsrDimens.sixtyFour,
                      height: IsrDimens.sixteen,
                    ),
                  )
                : titleWidget
            : Text(
                titleText!,
              ),
        actions: showActions == false || actions.isListEmptyOrNull ? null : actions,
        bottom: showDivider == true
            ? PreferredSize(
                preferredSize: Size(
                  IsrDimens.percentWidth(1),
                  IsrDimens.one,
                ),
                child: Container(
                  width: IsrDimens.percentWidth(1),
                  height: dividerThickNess ?? IsrDimens.one,
                  color: dividerColor ?? IsrColors.colorEFEFEF,
                ),
              )
            : bottom,
      );
}
