import 'package:flutter/material.dart';

class BlockedUsersConfig {
  const BlockedUsersConfig({
    this.blockedUsersUIConfig,
  });

  final BlockedUsersUIConfig? blockedUsersUIConfig;

  BlockedUsersConfig copyWith({
    BlockedUsersUIConfig? blockedUsersUIConfig,
  }) =>
      BlockedUsersConfig(
        blockedUsersUIConfig:
            blockedUsersUIConfig ?? this.blockedUsersUIConfig,
      );
}

class BlockedUsersUIConfig {
  const BlockedUsersUIConfig({
    this.scaffoldConfig,
    this.appBarConfig,
    this.searchBarConfig,
    this.userCardConfig,
    this.unblockButtonConfig,
    this.emptyStateConfig,
  });

  final BlockedUsersScaffoldConfig? scaffoldConfig;
  final BlockedUsersAppBarConfig? appBarConfig;
  final BlockedUsersSearchBarConfig? searchBarConfig;
  final BlockedUsersCardConfig? userCardConfig;
  final BlockedUsersUnblockButtonConfig? unblockButtonConfig;
  final BlockedUsersEmptyStateConfig? emptyStateConfig;

  BlockedUsersUIConfig copyWith({
    BlockedUsersScaffoldConfig? scaffoldConfig,
    BlockedUsersAppBarConfig? appBarConfig,
    BlockedUsersSearchBarConfig? searchBarConfig,
    BlockedUsersCardConfig? userCardConfig,
    BlockedUsersUnblockButtonConfig? unblockButtonConfig,
    BlockedUsersEmptyStateConfig? emptyStateConfig,
  }) =>
      BlockedUsersUIConfig(
        scaffoldConfig: scaffoldConfig ?? this.scaffoldConfig,
        appBarConfig: appBarConfig ?? this.appBarConfig,
        searchBarConfig: searchBarConfig ?? this.searchBarConfig,
        userCardConfig: userCardConfig ?? this.userCardConfig,
        unblockButtonConfig: unblockButtonConfig ?? this.unblockButtonConfig,
        emptyStateConfig: emptyStateConfig ?? this.emptyStateConfig,
      );
}

class BlockedUsersScaffoldConfig {
  const BlockedUsersScaffoldConfig({this.backgroundColor});

  final Color? backgroundColor;

  BlockedUsersScaffoldConfig copyWith({Color? backgroundColor}) =>
      BlockedUsersScaffoldConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
      );
}

class BlockedUsersAppBarConfig {
  const BlockedUsersAppBarConfig({
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.showDivider,
    this.dividerColor,
  });

  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;
  final bool? showDivider;
  final Color? dividerColor;

  BlockedUsersAppBarConfig copyWith({
    Color? backgroundColor,
    Color? titleColor,
    Color? iconColor,
    bool? showDivider,
    Color? dividerColor,
  }) =>
      BlockedUsersAppBarConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        titleColor: titleColor ?? this.titleColor,
        iconColor: iconColor ?? this.iconColor,
        showDivider: showDivider ?? this.showDivider,
        dividerColor: dividerColor ?? this.dividerColor,
      );
}

class BlockedUsersSearchBarConfig {
  const BlockedUsersSearchBarConfig({
    this.backgroundColor,
    this.borderRadius,
    this.borderColor,
    this.hintText,
    this.hintStyle,
    this.textStyle,
    this.contentPadding,
  });

  final Color? backgroundColor;
  final double? borderRadius;
  final Color? borderColor;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final EdgeInsets? contentPadding;

  BlockedUsersSearchBarConfig copyWith({
    Color? backgroundColor,
    double? borderRadius,
    Color? borderColor,
    String? hintText,
    TextStyle? hintStyle,
    TextStyle? textStyle,
    EdgeInsets? contentPadding,
  }) =>
      BlockedUsersSearchBarConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        borderColor: borderColor ?? this.borderColor,
        hintText: hintText ?? this.hintText,
        hintStyle: hintStyle ?? this.hintStyle,
        textStyle: textStyle ?? this.textStyle,
        contentPadding: contentPadding ?? this.contentPadding,
      );
}

class BlockedUsersCardConfig {
  const BlockedUsersCardConfig({
    this.avatarSize,
    this.usernameStyle,
    this.fullNameStyle,
    this.padding,
    this.dividerColor,
  });

  final double? avatarSize;
  final TextStyle? usernameStyle;
  final TextStyle? fullNameStyle;
  final EdgeInsets? padding;
  final Color? dividerColor;

  BlockedUsersCardConfig copyWith({
    double? avatarSize,
    TextStyle? usernameStyle,
    TextStyle? fullNameStyle,
    EdgeInsets? padding,
    Color? dividerColor,
  }) =>
      BlockedUsersCardConfig(
        avatarSize: avatarSize ?? this.avatarSize,
        usernameStyle: usernameStyle ?? this.usernameStyle,
        fullNameStyle: fullNameStyle ?? this.fullNameStyle,
        padding: padding ?? this.padding,
        dividerColor: dividerColor ?? this.dividerColor,
      );
}

class BlockedUsersUnblockButtonConfig {
  const BlockedUsersUnblockButtonConfig({
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.text,
  });

  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final String? text;

  BlockedUsersUnblockButtonConfig copyWith({
    double? width,
    double? height,
    double? borderRadius,
    Color? backgroundColor,
    Color? textColor,
    TextStyle? textStyle,
    String? text,
  }) =>
      BlockedUsersUnblockButtonConfig(
        width: width ?? this.width,
        height: height ?? this.height,
        borderRadius: borderRadius ?? this.borderRadius,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textColor: textColor ?? this.textColor,
        textStyle: textStyle ?? this.textStyle,
        text: text ?? this.text,
      );
}

class BlockedUsersEmptyStateConfig {
  const BlockedUsersEmptyStateConfig({
    this.titleStyle,
    this.messageStyle,
    this.icon,
    this.iconSize,
    this.iconColor,
  });

  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;

  BlockedUsersEmptyStateConfig copyWith({
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    IconData? icon,
    double? iconSize,
    Color? iconColor,
  }) =>
      BlockedUsersEmptyStateConfig(
        titleStyle: titleStyle ?? this.titleStyle,
        messageStyle: messageStyle ?? this.messageStyle,
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
      );
}
