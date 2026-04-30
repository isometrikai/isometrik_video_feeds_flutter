import 'package:flutter/material.dart';

class SearchScreenConfig {
  const SearchScreenConfig({
    this.searchScreenUIConfig,
  });

  final SearchScreenUIConfig? searchScreenUIConfig;

  SearchScreenConfig copyWith({
    SearchScreenUIConfig? searchScreenUIConfig,
  }) =>
      SearchScreenConfig(
        searchScreenUIConfig: searchScreenUIConfig ?? this.searchScreenUIConfig,
      );
}

/// Main UI configuration for search screen
class SearchScreenUIConfig {
  const SearchScreenUIConfig({
    this.scaffoldConfig,
    this.appBarConfig,
    this.searchBarConfig,
    this.tabNavigationConfig,
    this.postsGridConfig,
    this.postCardConfig,
    this.tagsListConfig,
    this.placesListConfig,
    this.accountsListConfig,
    this.emptyStateConfig,
    this.loadingConfig,
  });

  final SearchScreenScaffoldConfig? scaffoldConfig;
  final SearchAppBarConfig? appBarConfig;
  final SearchBarScreenConfig? searchBarConfig;
  final TabNavigationConfig? tabNavigationConfig;
  final SearchScreenPostsGridConfig? postsGridConfig;
  final SearchScreenPostCardConfig? postCardConfig;
  final TagsListConfig? tagsListConfig;
  final PlacesListConfig? placesListConfig;
  final AccountsListConfig? accountsListConfig;
  final EmptySearchStateConfig? emptyStateConfig;
  final SearchScreenLoadingConfig? loadingConfig;

  SearchScreenUIConfig copyWith({
    SearchScreenScaffoldConfig? scaffoldConfig,
    SearchAppBarConfig? appBarConfig,
    SearchBarScreenConfig? searchBarConfig,
    TabNavigationConfig? tabNavigationConfig,
    SearchScreenPostsGridConfig? postsGridConfig,
    SearchScreenPostCardConfig? postCardConfig,
    TagsListConfig? tagsListConfig,
    PlacesListConfig? placesListConfig,
    AccountsListConfig? accountsListConfig,
    EmptySearchStateConfig? emptyStateConfig,
    SearchScreenLoadingConfig? loadingConfig,
  }) =>
      SearchScreenUIConfig(
        scaffoldConfig: scaffoldConfig ?? this.scaffoldConfig,
        appBarConfig: appBarConfig ?? this.appBarConfig,
        searchBarConfig: searchBarConfig ?? this.searchBarConfig,
        tabNavigationConfig: tabNavigationConfig ?? this.tabNavigationConfig,
        postsGridConfig: postsGridConfig ?? this.postsGridConfig,
        postCardConfig: postCardConfig ?? this.postCardConfig,
        tagsListConfig: tagsListConfig ?? this.tagsListConfig,
        placesListConfig: placesListConfig ?? this.placesListConfig,
        accountsListConfig: accountsListConfig ?? this.accountsListConfig,
        emptyStateConfig: emptyStateConfig ?? this.emptyStateConfig,
        loadingConfig: loadingConfig ?? this.loadingConfig,
      );
}

/// Scaffold configuration
class SearchScreenScaffoldConfig {
  const SearchScreenScaffoldConfig({
    this.backgroundColor,
  });

  final Color? backgroundColor;

  SearchScreenScaffoldConfig copyWith({
    Color? backgroundColor,
  }) =>
      SearchScreenScaffoldConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
      );
}

/// AppBar configuration
class SearchAppBarConfig {
  const SearchAppBarConfig({
    this.backgroundColor,
    this.showDivider,
    this.dividerColor,
    this.showFollowRequestsAction,
  });

  final Color? backgroundColor;
  final bool? showDivider;
  final Color? dividerColor;
  final bool? showFollowRequestsAction;

  SearchAppBarConfig copyWith({
    Color? backgroundColor,
    bool? showDivider,
    Color? dividerColor,
    bool? showFollowRequestsAction,
  }) =>
      SearchAppBarConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        showDivider: showDivider ?? this.showDivider,
        dividerColor: dividerColor ?? this.dividerColor,
        showFollowRequestsAction:
            showFollowRequestsAction ?? this.showFollowRequestsAction,
      );
}

/// Search bar configuration
class SearchBarScreenConfig {
  const SearchBarScreenConfig({
    this.decoration,
    this.backgroundColor,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.hintText,
    this.hintStyle,
    this.textStyle,
    this.prefixIconConfig,
    this.suffixIconConfig,
    this.contentPadding,
  });

  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final IconConfig? prefixIconConfig;
  final IconConfig? suffixIconConfig;
  final EdgeInsets? contentPadding;

  SearchBarScreenConfig copyWith({
    BoxDecoration? decoration,
    Color? backgroundColor,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    String? hintText,
    TextStyle? hintStyle,
    TextStyle? textStyle,
    IconConfig? prefixIconConfig,
    IconConfig? suffixIconConfig,
    EdgeInsets? contentPadding,
  }) =>
      SearchBarScreenConfig(
        decoration: decoration ?? this.decoration,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        hintText: hintText ?? this.hintText,
        hintStyle: hintStyle ?? this.hintStyle,
        textStyle: textStyle ?? this.textStyle,
        prefixIconConfig: prefixIconConfig ?? this.prefixIconConfig,
        suffixIconConfig: suffixIconConfig ?? this.suffixIconConfig,
        contentPadding: contentPadding ?? this.contentPadding,
      );
}

/// Icon configuration
class IconConfig {
  const IconConfig({
    this.icon,
    this.iconData,
    this.color,
    this.size,
  });

  final String? icon;
  final IconData? iconData;
  final Color? color;
  final double? size;

  IconConfig copyWith({
    String? icon,
    IconData? iconData,
    Color? color,
    double? size,
  }) =>
      IconConfig(
        icon: icon ?? this.icon,
        iconData: iconData ?? this.iconData,
        color: color ?? this.color,
        size: size ?? this.size,
      );
}

/// Tab navigation configuration
class TabNavigationConfig {
  const TabNavigationConfig({
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.indicatorColor,
    this.indicatorWidth,
  });

  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? indicatorColor;
  final double? indicatorWidth;

  TabNavigationConfig copyWith({
    double? height,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    TextStyle? selectedTextStyle,
    TextStyle? unselectedTextStyle,
    Color? selectedTextColor,
    Color? unselectedTextColor,
    Color? indicatorColor,
    double? indicatorWidth,
  }) =>
      TabNavigationConfig(
        height: height ?? this.height,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
        unselectedTextStyle: unselectedTextStyle ?? this.unselectedTextStyle,
        selectedTextColor: selectedTextColor ?? this.selectedTextColor,
        unselectedTextColor: unselectedTextColor ?? this.unselectedTextColor,
        indicatorColor: indicatorColor ?? this.indicatorColor,
        indicatorWidth: indicatorWidth ?? this.indicatorWidth,
      );
}

/// Posts grid configuration
class SearchScreenPostsGridConfig {
  const SearchScreenPostsGridConfig({
    this.padding,
    this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
  });

  final EdgeInsets? padding;
  final int? crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;

  SearchScreenPostsGridConfig copyWith({
    EdgeInsets? padding,
    int? crossAxisCount,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? childAspectRatio,
  }) =>
      SearchScreenPostsGridConfig(
        padding: padding ?? this.padding,
        crossAxisCount: crossAxisCount ?? this.crossAxisCount,
        crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
        childAspectRatio: childAspectRatio ?? this.childAspectRatio,
      );
}

/// Post card configuration
class SearchScreenPostCardConfig {
  const SearchScreenPostCardConfig({
    this.decoration,
    this.borderRadius,
    this.backgroundColor,
    this.placeholderConfig,
    this.userProfileOverlayConfig,
    this.shopButtonOverlayConfig,
    this.videoIconConfig,
  });

  final BoxDecoration? decoration;
  final double? borderRadius;
  final Color? backgroundColor;
  final SearchScreenPlaceholderConfig? placeholderConfig;
  final UserProfileOverlayConfig? userProfileOverlayConfig;
  final ShopButtonOverlayConfig? shopButtonOverlayConfig;
  final SearchScreenVideoIconConfig? videoIconConfig;

  SearchScreenPostCardConfig copyWith({
    BoxDecoration? decoration,
    double? borderRadius,
    Color? backgroundColor,
    SearchScreenPlaceholderConfig? placeholderConfig,
    UserProfileOverlayConfig? userProfileOverlayConfig,
    ShopButtonOverlayConfig? shopButtonOverlayConfig,
    SearchScreenVideoIconConfig? videoIconConfig,
  }) =>
      SearchScreenPostCardConfig(
        decoration: decoration ?? this.decoration,
        borderRadius: borderRadius ?? this.borderRadius,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        placeholderConfig: placeholderConfig ?? this.placeholderConfig,
        userProfileOverlayConfig:
            userProfileOverlayConfig ?? this.userProfileOverlayConfig,
        shopButtonOverlayConfig:
            shopButtonOverlayConfig ?? this.shopButtonOverlayConfig,
        videoIconConfig: videoIconConfig ?? this.videoIconConfig,
      );
}

/// Placeholder configuration
class SearchScreenPlaceholderConfig {
  const SearchScreenPlaceholderConfig({
    this.backgroundColor,
    this.icon,
    this.iconColor,
    this.iconSize,
  });

  final Color? backgroundColor;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;

  SearchScreenPlaceholderConfig copyWith({
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
  }) =>
      SearchScreenPlaceholderConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
      );
}

/// User profile overlay configuration
class UserProfileOverlayConfig {
  const UserProfileOverlayConfig({
    this.padding,
    this.avatarSize,
    this.textStyle,
    this.textColor,
  });

  final EdgeInsets? padding;
  final double? avatarSize;
  final TextStyle? textStyle;
  final Color? textColor;

  UserProfileOverlayConfig copyWith({
    EdgeInsets? padding,
    double? avatarSize,
    TextStyle? textStyle,
    Color? textColor,
  }) =>
      UserProfileOverlayConfig(
        padding: padding ?? this.padding,
        avatarSize: avatarSize ?? this.avatarSize,
        textStyle: textStyle ?? this.textStyle,
        textColor: textColor ?? this.textColor,
      );
}

/// Shop button overlay configuration
class ShopButtonOverlayConfig {
  const ShopButtonOverlayConfig({
    this.padding,
    this.decoration,
    this.backgroundColor,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.titleColor,
    this.subtitleStyle,
    this.subtitleColor,
    this.spacing,
  });

  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final String? icon;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final TextStyle? subtitleStyle;
  final Color? subtitleColor;
  final double? spacing;

  ShopButtonOverlayConfig copyWith({
    EdgeInsets? padding,
    BoxDecoration? decoration,
    Color? backgroundColor,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    String? icon,
    Color? iconColor,
    double? iconSize,
    TextStyle? titleStyle,
    Color? titleColor,
    TextStyle? subtitleStyle,
    Color? subtitleColor,
    double? spacing,
  }) =>
      ShopButtonOverlayConfig(
        padding: padding ?? this.padding,
        decoration: decoration ?? this.decoration,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
        titleStyle: titleStyle ?? this.titleStyle,
        titleColor: titleColor ?? this.titleColor,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        subtitleColor: subtitleColor ?? this.subtitleColor,
        spacing: spacing ?? this.spacing,
      );
}

/// Video icon configuration
class SearchScreenVideoIconConfig {
  const SearchScreenVideoIconConfig({
    this.padding,
    this.decoration,
    this.backgroundColor,
    this.borderRadius,
    this.icon,
    this.iconColor,
    this.iconSize,
  });

  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final double? borderRadius;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;

  SearchScreenVideoIconConfig copyWith({
    EdgeInsets? padding,
    BoxDecoration? decoration,
    Color? backgroundColor,
    double? borderRadius,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
  }) =>
      SearchScreenVideoIconConfig(
        padding: padding ?? this.padding,
        decoration: decoration ?? this.decoration,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
      );
}

/// Tags list configuration
class TagsListConfig {
  const TagsListConfig({
    this.itemHeight,
    this.margin,
    this.padding,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.tagTextStyle,
    this.postCountTextStyle,
    this.spacing,
  });

  final double? itemHeight;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final String? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? tagTextStyle;
  final TextStyle? postCountTextStyle;
  final double? spacing;

  TagsListConfig copyWith({
    double? itemHeight,
    EdgeInsets? margin,
    EdgeInsets? padding,
    String? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? tagTextStyle,
    TextStyle? postCountTextStyle,
    double? spacing,
  }) =>
      TagsListConfig(
        itemHeight: itemHeight ?? this.itemHeight,
        margin: margin ?? this.margin,
        padding: padding ?? this.padding,
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        tagTextStyle: tagTextStyle ?? this.tagTextStyle,
        postCountTextStyle: postCountTextStyle ?? this.postCountTextStyle,
        spacing: spacing ?? this.spacing,
      );
}

/// Places list configuration
class PlacesListConfig {
  const PlacesListConfig({
    this.margin,
    this.padding,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.spacing,
  });

  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final String? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double? spacing;

  PlacesListConfig copyWith({
    EdgeInsets? margin,
    EdgeInsets? padding,
    String? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    double? spacing,
  }) =>
      PlacesListConfig(
        margin: margin ?? this.margin,
        padding: padding ?? this.padding,
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        spacing: spacing ?? this.spacing,
      );
}

/// Accounts list configuration
class AccountsListConfig {
  const AccountsListConfig({
    this.itemHeight,
    this.margin,
    this.padding,
    this.avatarSize,
    this.avatarBorderColor,
    this.avatarBorderWidth,
    this.usernameStyle,
    this.fullNameStyle,
    this.followButtonConfig,
    this.spacing,
    this.showPopularUsers,
  });

  final double? itemHeight;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? avatarSize;
  final Color? avatarBorderColor;
  final double? avatarBorderWidth;
  final TextStyle? usernameStyle;
  final TextStyle? fullNameStyle;
  final SearchScreenFollowButtonConfig? followButtonConfig;
  final double? spacing;

  /// When true, the accounts tab will fetch and display popular users
  /// when the search field is empty. Once the user types, normal search
  /// takes over. Defaults to false.
  final bool? showPopularUsers;

  AccountsListConfig copyWith({
    double? itemHeight,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? avatarSize,
    Color? avatarBorderColor,
    double? avatarBorderWidth,
    TextStyle? usernameStyle,
    TextStyle? fullNameStyle,
    SearchScreenFollowButtonConfig? followButtonConfig,
    double? spacing,
    bool? showPopularUsers,
  }) =>
      AccountsListConfig(
        itemHeight: itemHeight ?? this.itemHeight,
        margin: margin ?? this.margin,
        padding: padding ?? this.padding,
        avatarSize: avatarSize ?? this.avatarSize,
        avatarBorderColor: avatarBorderColor ?? this.avatarBorderColor,
        avatarBorderWidth: avatarBorderWidth ?? this.avatarBorderWidth,
        usernameStyle: usernameStyle ?? this.usernameStyle,
        fullNameStyle: fullNameStyle ?? this.fullNameStyle,
        followButtonConfig: followButtonConfig ?? this.followButtonConfig,
        spacing: spacing ?? this.spacing,
        showPopularUsers: showPopularUsers ?? this.showPopularUsers,
      );
}

/// Follow button configuration
class SearchScreenFollowButtonConfig {
  const SearchScreenFollowButtonConfig({
    this.height,
    this.width,
    this.borderRadius,
    this.backgroundColor,
    this.textStyle,
    this.textColor,
    this.text,
    this.requestText,
    this.requestedText,
    this.requestedBackgroundColor,
  });

  final double? height;
  final double? width;
  final double? borderRadius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? text;
  final String? requestText;
  final String? requestedText;
  final Color? requestedBackgroundColor;

  SearchScreenFollowButtonConfig copyWith({
    double? height,
    double? width,
    double? borderRadius,
    Color? backgroundColor,
    TextStyle? textStyle,
    Color? textColor,
    String? text,
    String? requestText,
    String? requestedText,
    Color? requestedBackgroundColor,
  }) =>
      SearchScreenFollowButtonConfig(
        height: height ?? this.height,
        width: width ?? this.width,
        borderRadius: borderRadius ?? this.borderRadius,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textStyle: textStyle ?? this.textStyle,
        textColor: textColor ?? this.textColor,
        text: text ?? this.text,
        requestText: requestText ?? this.requestText,
        requestedText: requestedText ?? this.requestedText,
        requestedBackgroundColor:
            requestedBackgroundColor ?? this.requestedBackgroundColor,
      );
}

/// Empty state configuration
class EmptySearchStateConfig {
  const EmptySearchStateConfig({
    this.icon,
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
    this.spacing,
  });

  final String? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final double? spacing;

  EmptySearchStateConfig copyWith({
    String? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    double? spacing,
  }) =>
      EmptySearchStateConfig(
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        messageStyle: messageStyle ?? this.messageStyle,
        spacing: spacing ?? this.spacing,
      );
}

/// Loading indicator configuration
class SearchScreenLoadingConfig {
  const SearchScreenLoadingConfig({
    this.indicator,
    this.color,
    this.strokeWidth,
    this.padding,
  });

  final Widget? indicator;
  final Color? color;
  final double? strokeWidth;
  final EdgeInsets? padding;

  SearchScreenLoadingConfig copyWith({
    Widget? indicator,
    Color? color,
    double? strokeWidth,
    EdgeInsets? padding,
  }) =>
      SearchScreenLoadingConfig(
        indicator: indicator ?? this.indicator,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        padding: padding ?? this.padding,
      );
}
