import 'package:flutter/material.dart';

class TagDetailsConfig {
  const TagDetailsConfig({
    this.tagDetailsUIConfig,
  });

  final TagDetailsUIConfig? tagDetailsUIConfig;

  TagDetailsConfig copyWith({
    TagDetailsUIConfig? tagDetailsUIConfig,
  }) =>
      TagDetailsConfig(
        tagDetailsUIConfig: tagDetailsUIConfig ?? this.tagDetailsUIConfig,
      );
}

/// Main UI configuration for tag details screen
class TagDetailsUIConfig {
  const TagDetailsUIConfig({
    this.scaffoldConfig,
    this.backButtonConfig,
    this.tagProfileConfig,
    this.postsGridConfig,
    this.postCardConfig,
    this.emptyStateConfig,
    this.errorStateConfig,
    this.loadingConfig,
  });

  final ScaffoldConfig? scaffoldConfig;
  final BackButtonTagConfig? backButtonConfig;
  final TagProfileConfig? tagProfileConfig;
  final PostsGridConfig? postsGridConfig;
  final PostCardConfig? postCardConfig;
  final EmptyTagStateConfig? emptyStateConfig;
  final ErrorStateConfig? errorStateConfig;
  final LoadingConfig? loadingConfig;

  TagDetailsUIConfig copyWith({
    ScaffoldConfig? scaffoldConfig,
    BackButtonTagConfig? backButtonConfig,
    TagProfileConfig? tagProfileConfig,
    PostsGridConfig? postsGridConfig,
    PostCardConfig? postCardConfig,
    EmptyTagStateConfig? emptyStateConfig,
    ErrorStateConfig? errorStateConfig,
    LoadingConfig? loadingConfig,
  }) =>
      TagDetailsUIConfig(
        scaffoldConfig: scaffoldConfig ?? this.scaffoldConfig,
        backButtonConfig: backButtonConfig ?? this.backButtonConfig,
        tagProfileConfig: tagProfileConfig ?? this.tagProfileConfig,
        postsGridConfig: postsGridConfig ?? this.postsGridConfig,
        postCardConfig: postCardConfig ?? this.postCardConfig,
        emptyStateConfig: emptyStateConfig ?? this.emptyStateConfig,
        errorStateConfig: errorStateConfig ?? this.errorStateConfig,
        loadingConfig: loadingConfig ?? this.loadingConfig,
      );
}

/// Scaffold configuration
class ScaffoldConfig {
  const ScaffoldConfig({
    this.backgroundColor,
  });

  final Color? backgroundColor;

  ScaffoldConfig copyWith({
    Color? backgroundColor,
  }) =>
      ScaffoldConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
      );
}

/// Back button configuration
class BackButtonTagConfig {
  const BackButtonTagConfig({
    this.topOffset,
    this.leftOffset,
    this.width,
    this.height,
    this.decoration,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.shadow,
  });

  final double? topOffset;
  final double? leftOffset;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;
  final List<BoxShadow>? shadow;

  BackButtonTagConfig copyWith({
    double? topOffset,
    double? leftOffset,
    double? width,
    double? height,
    BoxDecoration? decoration,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
    List<BoxShadow>? shadow,
  }) =>
      BackButtonTagConfig(
        topOffset: topOffset ?? this.topOffset,
        leftOffset: leftOffset ?? this.leftOffset,
        width: width ?? this.width,
        height: height ?? this.height,
        decoration: decoration ?? this.decoration,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
        shadow: shadow ?? this.shadow,
      );
}

/// Tag profile section configuration
class TagProfileConfig {
  const TagProfileConfig({
    this.padding,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.tagTextStyle,
    this.postCountTextStyle,
    this.spacing,
  });

  final EdgeInsets? padding;
  final String? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? tagTextStyle;
  final TextStyle? postCountTextStyle;
  final double? spacing;

  TagProfileConfig copyWith({
    EdgeInsets? padding,
    String? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? tagTextStyle,
    TextStyle? postCountTextStyle,
    double? spacing,
  }) =>
      TagProfileConfig(
        padding: padding ?? this.padding,
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        tagTextStyle: tagTextStyle ?? this.tagTextStyle,
        postCountTextStyle: postCountTextStyle ?? this.postCountTextStyle,
        spacing: spacing ?? this.spacing,
      );
}

/// Posts grid configuration
class PostsGridConfig {
  const PostsGridConfig({
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

  PostsGridConfig copyWith({
    EdgeInsets? padding,
    int? crossAxisCount,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? childAspectRatio,
  }) =>
      PostsGridConfig(
        padding: padding ?? this.padding,
        crossAxisCount: crossAxisCount ?? this.crossAxisCount,
        crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
        childAspectRatio: childAspectRatio ?? this.childAspectRatio,
      );
}

/// Post card configuration
class PostCardConfig {
  const PostCardConfig({
    this.decoration,
    this.borderRadius,
    this.backgroundColor,
    this.placeholderConfig,
    this.productsOverlayConfig,
    this.videoIconConfig,
  });

  final BoxDecoration? decoration;
  final double? borderRadius;
  final Color? backgroundColor;
  final PlaceholderConfig? placeholderConfig;
  final ProductsOverlayConfig? productsOverlayConfig;
  final VideoIconConfig? videoIconConfig;

  PostCardConfig copyWith({
    BoxDecoration? decoration,
    double? borderRadius,
    Color? backgroundColor,
    PlaceholderConfig? placeholderConfig,
    ProductsOverlayConfig? productsOverlayConfig,
    VideoIconConfig? videoIconConfig,
  }) =>
      PostCardConfig(
        decoration: decoration ?? this.decoration,
        borderRadius: borderRadius ?? this.borderRadius,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        placeholderConfig: placeholderConfig ?? this.placeholderConfig,
        productsOverlayConfig:
            productsOverlayConfig ?? this.productsOverlayConfig,
        videoIconConfig: videoIconConfig ?? this.videoIconConfig,
      );
}

/// Placeholder configuration for empty post images
class PlaceholderConfig {
  const PlaceholderConfig({
    this.backgroundColor,
    this.icon,
    this.iconColor,
    this.iconSize,
  });

  final Color? backgroundColor;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;

  PlaceholderConfig copyWith({
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
  }) =>
      PlaceholderConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
      );
}

/// Products overlay configuration
class ProductsOverlayConfig {
  const ProductsOverlayConfig({
    this.padding,
    this.decoration,
    this.backgroundColor,
    this.borderRadius,
    this.textStyle,
  });

  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final double? borderRadius;
  final TextStyle? textStyle;

  ProductsOverlayConfig copyWith({
    EdgeInsets? padding,
    BoxDecoration? decoration,
    Color? backgroundColor,
    double? borderRadius,
    TextStyle? textStyle,
  }) =>
      ProductsOverlayConfig(
        padding: padding ?? this.padding,
        decoration: decoration ?? this.decoration,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        textStyle: textStyle ?? this.textStyle,
      );
}

/// Video icon configuration
class VideoIconConfig {
  const VideoIconConfig({
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

  VideoIconConfig copyWith({
    EdgeInsets? padding,
    BoxDecoration? decoration,
    Color? backgroundColor,
    double? borderRadius,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
  }) =>
      VideoIconConfig(
        padding: padding ?? this.padding,
        decoration: decoration ?? this.decoration,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        iconSize: iconSize ?? this.iconSize,
      );
}

/// Empty state configuration
class EmptyTagStateConfig {
  const EmptyTagStateConfig({
    this.icon,
    this.iconSize,
    this.iconColor,
    this.messageStyle,
    this.descriptionStyle,
    this.spacing,
  });

  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? messageStyle;
  final TextStyle? descriptionStyle;
  final double? spacing;

  EmptyTagStateConfig copyWith({
    IconData? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? messageStyle,
    TextStyle? descriptionStyle,
    double? spacing,
  }) =>
      EmptyTagStateConfig(
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        messageStyle: messageStyle ?? this.messageStyle,
        descriptionStyle: descriptionStyle ?? this.descriptionStyle,
        spacing: spacing ?? this.spacing,
      );
}

/// Error state configuration
class ErrorStateConfig {
  const ErrorStateConfig({
    this.icon,
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.errorTextStyle,
    this.retryButtonConfig,
    this.spacing,
  });

  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? errorTextStyle;
  final RetryButtonConfig? retryButtonConfig;
  final double? spacing;

  ErrorStateConfig copyWith({
    IconData? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? errorTextStyle,
    RetryButtonConfig? retryButtonConfig,
    double? spacing,
  }) =>
      ErrorStateConfig(
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        errorTextStyle: errorTextStyle ?? this.errorTextStyle,
        retryButtonConfig: retryButtonConfig ?? this.retryButtonConfig,
        spacing: spacing ?? this.spacing,
      );
}

/// Retry button configuration
class RetryButtonConfig {
  const RetryButtonConfig({
    this.text,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
  });

  final String? text;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final EdgeInsets? padding;

  RetryButtonConfig copyWith({
    String? text,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
    EdgeInsets? padding,
  }) =>
      RetryButtonConfig(
        text: text ?? this.text,
        textStyle: textStyle ?? this.textStyle,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        foregroundColor: foregroundColor ?? this.foregroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
      );
}

/// Loading indicator configuration
class LoadingConfig {
  const LoadingConfig({
    this.indicator,
    this.color,
    this.strokeWidth,
    this.padding,
  });

  final Widget? indicator;
  final Color? color;
  final double? strokeWidth;
  final EdgeInsets? padding;

  LoadingConfig copyWith({
    Widget? indicator,
    Color? color,
    double? strokeWidth,
    EdgeInsets? padding,
  }) =>
      LoadingConfig(
        indicator: indicator ?? this.indicator,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        padding: padding ?? this.padding,
      );
}
