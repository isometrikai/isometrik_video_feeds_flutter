import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/domain/models/social_config.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsmCustomAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const IsmCustomAppBarWidget({
    super.key,
    this.themeConfig,
    this.statusBarColor,
    this.statusBarIconBrightness,
    this.statusBarBrightness,
    this.navigationBarColor,
    this.navigationBarIconBrightness,
    this.backgroundColor,
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

  /// Optional theme; falls back to `SocialConfig.themeConfig` when null.
  final ThemeConfig? themeConfig;

  /// Overrides [ThemeConfig.statusBarColor] when set.
  final Color? statusBarColor;

  /// Overrides [ThemeConfig.statusBarIconBrightness] when set.
  final Brightness? statusBarIconBrightness;

  /// Overrides [ThemeConfig.statusBarBrightness] when set.
  final Brightness? statusBarBrightness;

  /// Overrides [ThemeConfig.navigationBarColor] when set.
  final Color? navigationBarColor;

  /// Overrides [ThemeConfig.navigationBarIconBrightness] when set.
  final Brightness? navigationBarIconBrightness;

  final Color? backgroundColor;
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

  ThemeConfig get _themeConfig =>
      themeConfig ?? IsrVideoReelConfig.socialConfig.themeConfig ?? const ThemeConfig();

  Color get _appBarBackground => backgroundColor ?? IsrColors.appBarColor;

  Color get _appBarForeground =>
      iconColor ??
      titleColor ??
      titleStyle?.color ??
      IsrColors.appBarIconTextColor;

  SystemUiOverlayStyle get _systemOverlayStyle {
    final base = IsrSystemUi.overlay(
      themeConfig: _themeConfig,
      background: _appBarBackground,
    );
    return base.copyWith(
      statusBarColor: statusBarColor,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
      systemNavigationBarColor: navigationBarColor,
      systemNavigationBarIconBrightness: navigationBarIconBrightness,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  Size get preferredSize =>
      Size(IsrDimens.percentWidth(1), height ?? IsrDimens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final foregroundIconTheme = IconThemeData(color: _appBarForeground);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _appBarBackground,
      foregroundColor: _appBarForeground,
      iconTheme: foregroundIconTheme,
      actionsIconTheme: foregroundIconTheme,
      systemOverlayStyle: _systemOverlayStyle,
      leadingWidth: isBackButtonVisible == false
          ? 20.responsiveDimension
          : leadingWidth ?? 40.responsiveDimension,
      titleSpacing: titleSpacing ?? 0,
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
                              : AssetConstants.icArrowBack,
                          color: _appBarForeground,
                        ),
                      ),
                    )
                  : 0.responsiveVerticalSpace)
          : 0.responsiveVerticalSpace,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      titleTextStyle: titleStyle ??
          Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                color: titleColor ?? IsrColors.appBarIconTextColor,
              ),
      toolbarTextStyle: Theme.of(context).appBarTheme.toolbarTextStyle,
      title: titleText == null
          ? showTitleWidget == true
              ? titleWidget != null
                  ? titleWidget
                  : AppImage.svg(
                      AssetConstants.icAppLogo,
                      width: 68.responsiveDimension,
                      height: 44.responsiveDimension,
                    )
              : const SizedBox.shrink()
          : Text(
              titleText!,
              style: titleStyle ??
                  TextStyle(
                    color: titleColor ?? IsrColors.appBarIconTextColor,
                  ),
            ),
      actions:
          showActions == false || actions.isListEmptyOrNull ? null : actions,
      bottom: showDivider == true
          ? PreferredSize(
              preferredSize: Size(
                100.percentWidth,
                1.responsiveDimension,
              ),
              child: Container(
                width: 100.percentWidth,
                height: dividerThickNess ?? 1.responsiveDimension,
                color: dividerColor ?? IsrColors.colorEFEFEF,
              ),
            )
          : bottom ?? null,
    );
  }
}
