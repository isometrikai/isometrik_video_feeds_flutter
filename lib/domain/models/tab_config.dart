import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class TabConfig {


  const TabConfig({
    this.tabCallBackConfig,
    this.tabUIConfig,
  });
  final TabCallBackConfig? tabCallBackConfig;
  final TabUIConfig? tabUIConfig;


  TabConfig copyWith({
    TabCallBackConfig? tabCallBackConfig,
    TabUIConfig? tabUIConfig,
  }) => TabConfig(
      tabCallBackConfig: tabCallBackConfig ?? this.tabCallBackConfig,
      tabUIConfig: tabUIConfig ?? this.tabUIConfig,
    );
}

class TabUIConfig {
  const TabUIConfig();


  TabUIConfig copyWith() => const TabUIConfig();
}

class TabCallBackConfig {


  const TabCallBackConfig({
    this.onChangeOfTab,
    this.onReelsLoaded,
    this.getEmptyScreen,
  });
  final Function(TabDataModel tandate)? onChangeOfTab;
  final Function(TabDataModel tandate, List<TimeLineData> reelsDataList)? onReelsLoaded;
  final Widget Function(TabDataModel tandate)? getEmptyScreen;


  TabCallBackConfig copyWith({
    Function(TabDataModel tandate)? onChangeOfTab,
    Function(TabDataModel tandate, List<TimeLineData> reelsDataList)? onReelsLoaded,
    Widget Function(TabDataModel tandate)? getEmptyScreen,
  }) => TabCallBackConfig(
      onChangeOfTab: onChangeOfTab ?? this.onChangeOfTab,
      onReelsLoaded: onReelsLoaded ?? this.onReelsLoaded,
      getEmptyScreen: getEmptyScreen ?? this.getEmptyScreen,
    );
}