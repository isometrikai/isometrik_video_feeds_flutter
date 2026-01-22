import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class TabConfig {
  const TabConfig({
    this.tabCallBackConfig,
    this.tabUIConfig,
    this.autoMoveToNextPost = true,
  });
  final TabCallBackConfig? tabCallBackConfig;
  final TabUIConfig? tabUIConfig;
  final bool autoMoveToNextPost;

  TabConfig copyWith({
    TabCallBackConfig? tabCallBackConfig,
    TabUIConfig? tabUIConfig,
    bool? autoMoveToNextPost,
  }) =>
      TabConfig(
        tabCallBackConfig: tabCallBackConfig ?? this.tabCallBackConfig,
        tabUIConfig: tabUIConfig ?? this.tabUIConfig,
        autoMoveToNextPost: autoMoveToNextPost ?? this.autoMoveToNextPost,
      );
}

class TabUIConfig {
  const TabUIConfig({
    this.tabBarConfig,
    this.backButtonConfig,
    this.loadingViewConfig,
    this.statusBarConfig,
  });

  final TabBarConfig? tabBarConfig;
  final BackButtonConfig? backButtonConfig;
  final LoadingViewConfig? loadingViewConfig;
  final StatusBarConfig? statusBarConfig;

  TabUIConfig copyWith({
    TabBarConfig? tabBarConfig,
    BackButtonConfig? backButtonConfig,
    LoadingViewConfig? loadingViewConfig,
    StatusBarConfig? statusBarConfig,
  }) =>
      TabUIConfig(
        tabBarConfig: tabBarConfig ?? this.tabBarConfig,
        backButtonConfig: backButtonConfig ?? this.backButtonConfig,
        loadingViewConfig: loadingViewConfig ?? this.loadingViewConfig,
        statusBarConfig: statusBarConfig ?? this.statusBarConfig,
      );
}

/// Configuration for the tab bar
class TabBarConfig {
  const TabBarConfig({
    this.containerGradient,
    this.containerPadding,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
    this.indicatorWeight,
    this.indicatorSize,
    this.dividerColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.tabPadding,
    this.labelPadding,
    this.isScrollable,
    this.tabAlignment,
    this.splashColor,
    this.highlightColor,
    this.leftWidget,
    this.rightWidget,
  });

  /// Gradient for the tab bar container background
  final LinearGradient? containerGradient;

  /// Padding for the tab bar container
  final EdgeInsetsGeometry? containerPadding;

  /// Color for selected tab label
  final Color? labelColor;

  /// Color for unselected tab label
  final Color? unselectedLabelColor;

  /// Color for the tab indicator
  final Color? indicatorColor;

  /// Weight/thickness of the tab indicator
  final double? indicatorWeight;

  /// Size of the tab indicator
  final TabBarIndicatorSize? indicatorSize;

  /// Color for the divider between tabs
  final Color? dividerColor;

  /// Style for selected tab label
  final TextStyle? labelStyle;

  /// Style for unselected tab label
  final TextStyle? unselectedLabelStyle;

  /// Padding for the TabBar widget
  final EdgeInsetsGeometry? tabPadding;

  /// Padding for individual tab labels
  final EdgeInsetsGeometry? labelPadding;

  /// Whether tabs are scrollable
  final bool? isScrollable;

  /// Alignment of tabs
  final TabAlignment? tabAlignment;

  /// Splash color for tab taps
  final Color? splashColor;

  /// Highlight color for tab taps
  final Color? highlightColor;

  /// Widget to display on the left side of the tab bar (e.g., back button, logo)
  final Widget? leftWidget;

  /// Widget to display on the right side of the tab bar (e.g., search icon, menu icon)
  final Widget? rightWidget;

  TabBarConfig copyWith({
    LinearGradient? containerGradient,
    EdgeInsetsGeometry? containerPadding,
    Color? labelColor,
    Color? unselectedLabelColor,
    Color? indicatorColor,
    double? indicatorWeight,
    TabBarIndicatorSize? indicatorSize,
    Color? dividerColor,
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    EdgeInsetsGeometry? tabPadding,
    EdgeInsetsGeometry? labelPadding,
    bool? isScrollable,
    TabAlignment? tabAlignment,
    Color? splashColor,
    Color? highlightColor,
    Widget? leftWidget,
    Widget? rightWidget,
  }) =>
      TabBarConfig(
        containerGradient: containerGradient ?? this.containerGradient,
        containerPadding: containerPadding ?? this.containerPadding,
        labelColor: labelColor ?? this.labelColor,
        unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
        indicatorColor: indicatorColor ?? this.indicatorColor,
        indicatorWeight: indicatorWeight ?? this.indicatorWeight,
        indicatorSize: indicatorSize ?? this.indicatorSize,
        dividerColor: dividerColor ?? this.dividerColor,
        labelStyle: labelStyle ?? this.labelStyle,
        unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
        tabPadding: tabPadding ?? this.tabPadding,
        labelPadding: labelPadding ?? this.labelPadding,
        isScrollable: isScrollable ?? this.isScrollable,
        tabAlignment: tabAlignment ?? this.tabAlignment,
        splashColor: splashColor ?? this.splashColor,
        highlightColor: highlightColor ?? this.highlightColor,
        leftWidget: leftWidget ?? this.leftWidget,
        rightWidget: rightWidget ?? this.rightWidget,
      );
}

/// Configuration for the back button
class BackButtonConfig {
  const BackButtonConfig({
    this.buttonDecoration,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.buttonPosition,
    this.topOffset,
    this.leftOffset,
  });

  /// Decoration for the back button container
  final BoxDecoration? buttonDecoration;

  /// Icon widget for the back button (if null, uses default Icons.arrow_back)
  final Widget? icon;

  /// Color for the back button icon
  final Color? iconColor;

  /// Size for the back button icon
  final double? iconSize;

  /// Position configuration for the back button
  final Alignment? buttonPosition;

  /// Top offset from safe area
  final double? topOffset;

  /// Left offset from screen edge
  final double? leftOffset;

  BackButtonConfig copyWith({
    BoxDecoration? buttonDecoration,
    Widget? icon,
    Color? iconColor,
    double? iconSize,
    Alignment? buttonPosition,
    double? topOffset,
    double? leftOffset,
  }) =>
      BackButtonConfig(
        buttonDecoration: buttonDecoration ?? this.buttonDecoration,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
        buttonPosition: buttonPosition ?? this.buttonPosition,
        topOffset: topOffset ?? this.topOffset,
        leftOffset: leftOffset ?? this.leftOffset,
      );
}

/// Configuration for the loading view
class LoadingViewConfig {
  const LoadingViewConfig({
    this.backgroundColor,
    this.loadingWidget,
  });

  /// Background color for the loading view
  final Color? backgroundColor;

  /// Custom loading widget (if null, uses default PostShimmerView)
  final Widget? loadingWidget;

  LoadingViewConfig copyWith({
    Color? backgroundColor,
    Widget? loadingWidget,
  }) =>
      LoadingViewConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        loadingWidget: loadingWidget ?? this.loadingWidget,
      );
}

/// Configuration for status bar styling
class StatusBarConfig {
  const StatusBarConfig({
    this.statusBarColor,
    this.statusBarBrightness,
    this.statusBarIconBrightness,
  });

  /// Status bar background color
  final Color? statusBarColor;

  /// Status bar brightness (iOS)
  final Brightness? statusBarBrightness;

  /// Status bar icon brightness (Android)
  final Brightness? statusBarIconBrightness;

  StatusBarConfig copyWith({
    Color? statusBarColor,
    Brightness? statusBarBrightness,
    Brightness? statusBarIconBrightness,
  }) =>
      StatusBarConfig(
        statusBarColor: statusBarColor ?? this.statusBarColor,
        statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
        statusBarIconBrightness:
            statusBarIconBrightness ?? this.statusBarIconBrightness,
      );
}

class TabCallBackConfig {
  const TabCallBackConfig({
    this.onChangeOfTab,
    this.onReelsLoaded,
    this.getEmptyScreen,
  });
  final Function(TabDataModel tandate)? onChangeOfTab;
  final Function(TabDataModel tandate, List<TimeLineData> reelsDataList)?
      onReelsLoaded;
  final Widget Function(TabDataModel tandate)? getEmptyScreen;

  TabCallBackConfig copyWith({
    Function(TabDataModel tandate)? onChangeOfTab,
    Function(TabDataModel tandate, List<TimeLineData> reelsDataList)?
        onReelsLoaded,
    Widget Function(TabDataModel tandate)? getEmptyScreen,
  }) =>
      TabCallBackConfig(
        onChangeOfTab: onChangeOfTab ?? this.onChangeOfTab,
        onReelsLoaded: onReelsLoaded ?? this.onReelsLoaded,
        getEmptyScreen: getEmptyScreen ?? this.getEmptyScreen,
      );
}
