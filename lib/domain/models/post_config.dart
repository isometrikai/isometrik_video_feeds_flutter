import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class PostConfig {
  const PostConfig({
    this.postUIConfig,
    this.postCallBackConfig,
    this.autoMoveToNextMedia = true,
    this.autoMoveToNextPost = true,
  });

  final PostUIConfig? postUIConfig;
  final PostCallBackConfig? postCallBackConfig;
  final bool autoMoveToNextMedia;
  final bool autoMoveToNextPost;

  PostConfig copyWith({
    PostUIConfig? postUIConfig,
    PostCallBackConfig? postCallBackConfig,
    bool? autoMoveToNextMedia,
    bool? autoMoveToNextPost,
  }) =>
      PostConfig(
        postUIConfig: postUIConfig ?? this.postUIConfig,
        postCallBackConfig: postCallBackConfig ?? this.postCallBackConfig,
        autoMoveToNextMedia: autoMoveToNextMedia ?? this.autoMoveToNextMedia,
        autoMoveToNextPost: autoMoveToNextPost ?? this.autoMoveToNextPost,
      );
}

class PostUIConfig {
  const PostUIConfig({
    this.overlayPadding,
    this.actionIconConfig,
    this.textStyleConfig,
    this.shopUIConfig,
    this.followButtonConfig,
    this.mediaIndicatorConfig,
    this.userProfileConfig,
    this.descriptionConfig,
    this.locationConfig,
    this.mentionConfig,
  });

  final EdgeInsetsGeometry? overlayPadding;
  final ActionIconConfig? actionIconConfig;
  final TextStyleConfig? textStyleConfig;
  final ShopUIConfig? shopUIConfig;
  final FollowButtonConfig? followButtonConfig;
  final MediaIndicatorConfig? mediaIndicatorConfig;
  final UserProfileConfig? userProfileConfig;
  final DescriptionConfig? descriptionConfig;
  final LocationConfig? locationConfig;
  final MentionConfig? mentionConfig;

  PostUIConfig copyWith({
    EdgeInsetsGeometry? overlayPadding,
    ActionIconConfig? actionIconConfig,
    TextStyleConfig? textStyleConfig,
    ShopUIConfig? shopUIConfig,
    FollowButtonConfig? followButtonConfig,
    MediaIndicatorConfig? mediaIndicatorConfig,
    UserProfileConfig? userProfileConfig,
    DescriptionConfig? descriptionConfig,
    LocationConfig? locationConfig,
    MentionConfig? mentionConfig,
  }) =>
      PostUIConfig(
        overlayPadding: overlayPadding ?? this.overlayPadding,
        actionIconConfig: actionIconConfig ?? this.actionIconConfig,
        textStyleConfig: textStyleConfig ?? this.textStyleConfig,
        shopUIConfig: shopUIConfig ?? this.shopUIConfig,
        followButtonConfig: followButtonConfig ?? this.followButtonConfig,
        mediaIndicatorConfig: mediaIndicatorConfig ?? this.mediaIndicatorConfig,
        userProfileConfig: userProfileConfig ?? this.userProfileConfig,
        descriptionConfig: descriptionConfig ?? this.descriptionConfig,
        locationConfig: locationConfig ?? this.locationConfig,
        mentionConfig: mentionConfig ?? this.mentionConfig,
      );
}

/// Configuration for action icons (like, comment, share, save, more)
class ActionIconConfig {
  const ActionIconConfig({
    this.likeIconSelected,
    this.likeIconUnselected,
    this.commentIcon,
    this.shareIcon,
    this.saveIconSelected,
    this.saveIconUnselected,
    this.moreIcon,
    this.muteIcon,
    this.unmuteIcon,
    this.iconSize,
    this.iconShadow,
  });

  /// Icon path for selected/liked state
  final String? likeIconSelected;

  /// Icon path for unselected/unliked state
  final String? likeIconUnselected;

  /// Icon path for comment action
  final String? commentIcon;

  /// Icon path for share action
  final String? shareIcon;

  /// Icon path for selected/saved state
  final String? saveIconSelected;

  /// Icon path for unselected/unsaved state
  final String? saveIconUnselected;

  /// Icon path for more options
  final String? moreIcon;

  /// Icon path for mute state
  final String? muteIcon;

  /// Icon path for unmute state
  final String? unmuteIcon;

  /// Size for action icons (width and height)
  final double? iconSize;

  /// Shadow configuration for action icons
  final List<BoxShadow>? iconShadow;

  ActionIconConfig copyWith({
    String? likeIconSelected,
    String? likeIconUnselected,
    String? commentIcon,
    String? shareIcon,
    String? saveIconSelected,
    String? saveIconUnselected,
    String? moreIcon,
    String? muteIcon,
    String? unmuteIcon,
    double? iconSize,
    List<BoxShadow>? iconShadow,
  }) =>
      ActionIconConfig(
        likeIconSelected: likeIconSelected ?? this.likeIconSelected,
        likeIconUnselected: likeIconUnselected ?? this.likeIconUnselected,
        commentIcon: commentIcon ?? this.commentIcon,
        shareIcon: shareIcon ?? this.shareIcon,
        saveIconSelected: saveIconSelected ?? this.saveIconSelected,
        saveIconUnselected: saveIconUnselected ?? this.saveIconUnselected,
        moreIcon: moreIcon ?? this.moreIcon,
        muteIcon: muteIcon ?? this.muteIcon,
        unmuteIcon: unmuteIcon ?? this.unmuteIcon,
        iconSize: iconSize ?? this.iconSize,
        iconShadow: iconShadow ?? this.iconShadow,
      );
}

/// Configuration for text styles used throughout the post UI
class TextStyleConfig {
  const TextStyleConfig({
    this.actionLabelStyle,
    this.userNameStyle,
    this.descriptionStyle,
    this.locationStyle,
    this.mentionStyle,
    this.hashtagStyle,
    this.mediaCounterStyle,
    this.shopTitleStyle,
    this.shopSubtitleStyle,
    this.commissionTagStyle,
    this.followButtonTextStyle,
    this.followingButtonTextStyle,
  });

  /// Style for action button labels (like count, comment count, etc.)
  final TextStyle? actionLabelStyle;

  /// Style for user name text
  final TextStyle? userNameStyle;

  /// Style for post description text
  final TextStyle? descriptionStyle;

  /// Style for location text
  final TextStyle? locationStyle;

  /// Style for mention text (@username)
  final TextStyle? mentionStyle;

  /// Style for hashtag text (#hashtag)
  final TextStyle? hashtagStyle;

  /// Style for media counter (e.g., "1/3")
  final TextStyle? mediaCounterStyle;

  /// Style for shop title text
  final TextStyle? shopTitleStyle;

  /// Style for shop subtitle text
  final TextStyle? shopSubtitleStyle;

  /// Style for commission tag text
  final TextStyle? commissionTagStyle;

  /// Style for follow button text
  final TextStyle? followButtonTextStyle;

  /// Style for following button text
  final TextStyle? followingButtonTextStyle;

  TextStyleConfig copyWith({
    TextStyle? actionLabelStyle,
    TextStyle? userNameStyle,
    TextStyle? descriptionStyle,
    TextStyle? locationStyle,
    TextStyle? mentionStyle,
    TextStyle? hashtagStyle,
    TextStyle? mediaCounterStyle,
    TextStyle? shopTitleStyle,
    TextStyle? shopSubtitleStyle,
    TextStyle? commissionTagStyle,
    TextStyle? followButtonTextStyle,
    TextStyle? followingButtonTextStyle,
  }) =>
      TextStyleConfig(
        actionLabelStyle: actionLabelStyle ?? this.actionLabelStyle,
        userNameStyle: userNameStyle ?? this.userNameStyle,
        descriptionStyle: descriptionStyle ?? this.descriptionStyle,
        locationStyle: locationStyle ?? this.locationStyle,
        mentionStyle: mentionStyle ?? this.mentionStyle,
        hashtagStyle: hashtagStyle ?? this.hashtagStyle,
        mediaCounterStyle: mediaCounterStyle ?? this.mediaCounterStyle,
        shopTitleStyle: shopTitleStyle ?? this.shopTitleStyle,
        shopSubtitleStyle: shopSubtitleStyle ?? this.shopSubtitleStyle,
        commissionTagStyle: commissionTagStyle ?? this.commissionTagStyle,
        followButtonTextStyle:
            followButtonTextStyle ?? this.followButtonTextStyle,
        followingButtonTextStyle:
            followingButtonTextStyle ?? this.followingButtonTextStyle,
      );
}

/// Configuration for shop/cart UI elements
class ShopUIConfig {
  const ShopUIConfig({
    this.cartIcon,
    this.shopContainerDecoration,
    this.shopContainerPadding,
    this.shopIconSize,
    this.shopIconColor,
  });

  /// Icon path for cart/shop icon
  final String? cartIcon;

  /// Decoration for shop container
  final BoxDecoration? shopContainerDecoration;

  /// Padding for shop container
  final EdgeInsetsGeometry? shopContainerPadding;

  /// Size for shop icon
  final double? shopIconSize;

  /// Color for shop icon
  final Color? shopIconColor;

  ShopUIConfig copyWith({
    String? cartIcon,
    BoxDecoration? shopContainerDecoration,
    EdgeInsetsGeometry? shopContainerPadding,
    double? shopIconSize,
    Color? shopIconColor,
  }) =>
      ShopUIConfig(
        cartIcon: cartIcon ?? this.cartIcon,
        shopContainerDecoration:
            shopContainerDecoration ?? this.shopContainerDecoration,
        shopContainerPadding: shopContainerPadding ?? this.shopContainerPadding,
        shopIconSize: shopIconSize ?? this.shopIconSize,
        shopIconColor: shopIconColor ?? this.shopIconColor,
      );
}

/// Configuration for follow button styling
class FollowButtonConfig {
  const FollowButtonConfig({
    this.followButtonDecoration,
    this.followingButtonDecoration,
    this.followButtonPadding,
    this.followButtonHeight,
    this.followButtonMinWidth,
    this.loadingIndicatorColor,
  });

  /// Decoration for follow button
  final BoxDecoration? followButtonDecoration;

  /// Decoration for following button (outlined style)
  final BoxDecoration? followingButtonDecoration;

  /// Padding for follow button
  final EdgeInsetsGeometry? followButtonPadding;

  /// Height for follow button
  final double? followButtonHeight;

  /// Minimum width for follow button
  final double? followButtonMinWidth;

  /// Color for loading indicator in follow button
  final Color? loadingIndicatorColor;

  FollowButtonConfig copyWith({
    BoxDecoration? followButtonDecoration,
    BoxDecoration? followingButtonDecoration,
    EdgeInsetsGeometry? followButtonPadding,
    double? followButtonHeight,
    double? followButtonMinWidth,
    Color? loadingIndicatorColor,
  }) =>
      FollowButtonConfig(
        followButtonDecoration:
            followButtonDecoration ?? this.followButtonDecoration,
        followingButtonDecoration:
            followingButtonDecoration ?? this.followingButtonDecoration,
        followButtonPadding: followButtonPadding ?? this.followButtonPadding,
        followButtonHeight: followButtonHeight ?? this.followButtonHeight,
        followButtonMinWidth: followButtonMinWidth ?? this.followButtonMinWidth,
        loadingIndicatorColor:
            loadingIndicatorColor ?? this.loadingIndicatorColor,
      );
}

/// Configuration for media progress indicators
class MediaIndicatorConfig {
  const MediaIndicatorConfig({
    this.indicatorHeight,
    this.completedColor,
    this.pendingColor,
    this.progressColor,
    this.indicatorBorderRadius,
    this.indicatorSpacing,
  });

  /// Height of media indicator bars
  final double? indicatorHeight;

  /// Color for completed media segments
  final Color? completedColor;

  /// Color for pending/upcoming media segments
  final Color? pendingColor;

  /// Color for current media progress
  final Color? progressColor;

  /// Border radius for indicator bars
  final BorderRadius? indicatorBorderRadius;

  /// Spacing between indicator bars
  final double? indicatorSpacing;

  MediaIndicatorConfig copyWith({
    double? indicatorHeight,
    Color? completedColor,
    Color? pendingColor,
    Color? progressColor,
    BorderRadius? indicatorBorderRadius,
    double? indicatorSpacing,
  }) =>
      MediaIndicatorConfig(
        indicatorHeight: indicatorHeight ?? this.indicatorHeight,
        completedColor: completedColor ?? this.completedColor,
        pendingColor: pendingColor ?? this.pendingColor,
        progressColor: progressColor ?? this.progressColor,
        indicatorBorderRadius:
            indicatorBorderRadius ?? this.indicatorBorderRadius,
        indicatorSpacing: indicatorSpacing ?? this.indicatorSpacing,
      );
}

/// Configuration for user profile display
class UserProfileConfig {
  const UserProfileConfig({
    this.profileImageSize,
    this.profileImageBorderRadius,
    this.profileImageBorder,
    this.profileImageShadow,
    this.profileImagePlaceholderColor,
  });

  /// Size for profile image (width and height)
  final double? profileImageSize;

  /// Border radius for profile image
  final double? profileImageBorderRadius;

  /// Border for profile image
  final Border? profileImageBorder;

  /// Shadow for profile image
  final List<BoxShadow>? profileImageShadow;

  /// Placeholder color for profile image
  final Color? profileImagePlaceholderColor;

  UserProfileConfig copyWith({
    double? profileImageSize,
    double? profileImageBorderRadius,
    Border? profileImageBorder,
    List<BoxShadow>? profileImageShadow,
    Color? profileImagePlaceholderColor,
  }) =>
      UserProfileConfig(
        profileImageSize: profileImageSize ?? this.profileImageSize,
        profileImageBorderRadius:
            profileImageBorderRadius ?? this.profileImageBorderRadius,
        profileImageBorder: profileImageBorder ?? this.profileImageBorder,
        profileImageShadow: profileImageShadow ?? this.profileImageShadow,
        profileImagePlaceholderColor:
            profileImagePlaceholderColor ?? this.profileImagePlaceholderColor,
      );
}

/// Configuration for description text and expansion
class DescriptionConfig {
  const DescriptionConfig({
    this.maxLengthToShow,
    this.maxLinesToShow,
    this.expandTextStyle,
    this.collapseTextStyle,
    this.textShadows,
  });

  /// Maximum character length to show before truncation
  final int? maxLengthToShow;

  /// Maximum lines to show before truncation
  final int? maxLinesToShow;

  /// Style for "more" expand text
  final TextStyle? expandTextStyle;

  /// Style for "less" collapse text
  final TextStyle? collapseTextStyle;

  /// Text shadows for description text
  final List<Shadow>? textShadows;

  DescriptionConfig copyWith({
    int? maxLengthToShow,
    int? maxLinesToShow,
    TextStyle? expandTextStyle,
    TextStyle? collapseTextStyle,
    List<Shadow>? textShadows,
  }) =>
      DescriptionConfig(
        maxLengthToShow: maxLengthToShow ?? this.maxLengthToShow,
        maxLinesToShow: maxLinesToShow ?? this.maxLinesToShow,
        expandTextStyle: expandTextStyle ?? this.expandTextStyle,
        collapseTextStyle: collapseTextStyle ?? this.collapseTextStyle,
        textShadows: textShadows ?? this.textShadows,
      );
}

/// Configuration for location display
class LocationConfig {
  const LocationConfig({
    this.locationIcon,
    this.locationIconSize,
    this.locationIconColor,
    this.locationIconSpacing,
  });

  /// Icon path for location icon
  final String? locationIcon;

  /// Size for location icon
  final double? locationIconSize;

  /// Color for location icon
  final Color? locationIconColor;

  /// Spacing between location icon and text
  final double? locationIconSpacing;

  LocationConfig copyWith({
    String? locationIcon,
    double? locationIconSize,
    Color? locationIconColor,
    double? locationIconSpacing,
  }) =>
      LocationConfig(
        locationIcon: locationIcon ?? this.locationIcon,
        locationIconSize: locationIconSize ?? this.locationIconSize,
        locationIconColor: locationIconColor ?? this.locationIconColor,
        locationIconSpacing: locationIconSpacing ?? this.locationIconSpacing,
      );
}

/// Configuration for mention display
class MentionConfig {
  const MentionConfig({
    this.mentionIcon,
    this.mentionIconSize,
    this.mentionIconColor,
    this.mentionIconSpacing,
  });

  /// Icon path for mention icon
  final String? mentionIcon;

  /// Size for mention icon
  final double? mentionIconSize;

  /// Color for mention icon
  final Color? mentionIconColor;

  /// Spacing between mention icon and text
  final double? mentionIconSpacing;

  MentionConfig copyWith({
    String? mentionIcon,
    double? mentionIconSize,
    Color? mentionIconColor,
    double? mentionIconSpacing,
  }) =>
      MentionConfig(
        mentionIcon: mentionIcon ?? this.mentionIcon,
        mentionIconSize: mentionIconSize ?? this.mentionIconSize,
        mentionIconColor: mentionIconColor ?? this.mentionIconColor,
        mentionIconSpacing: mentionIconSpacing ?? this.mentionIconSpacing,
      );
}

class PostCallBackConfig {
  const PostCallBackConfig({
    this.onSaveChanged,
    this.onLikeChanged,
    this.onSaveClicked,
    this.onFollowClick,
    this.onShareClicked,
    this.onLikeClick,
    this.onCommentClick,
    this.onProfileClick,
    this.onTagProductClick,
    this.onPostChanged,
  });

  final Function(TimeLineData postData, bool isSaved)? onSaveChanged;
  final Function(TimeLineData postData, bool isLiked)? onLikeChanged;
  // return true if success
  final Future<bool> Function(TimeLineData? postData, bool isSaved)?
      onSaveClicked;
  final Future<bool> Function(TimeLineData? postData, bool isLiked)?
      onLikeClick;
  final Future<bool> Function(TimeLineData? postData, bool isFollow)?
      onFollowClick;

  final Function(TimeLineData postData)? onShareClicked;
  final Function(TimeLineData postData)? onCommentClick;
  final Function(TimeLineData? postData, String userId, bool? isFollowing)?
      onProfileClick;
  final Future<void> Function(TimeLineData postData)? onTagProductClick;
  final Function(TimeLineData postData, int index)? onPostChanged;

  PostCallBackConfig copyWith({
    Function(TimeLineData postData, bool isSaved)? onSaveChanged,
    Function(TimeLineData postData, bool isLiked)? onLikeChanged,
    Future<bool> Function(TimeLineData? postData, bool isLiked)? onLikeClick,
    Future<bool> Function(TimeLineData? postData, bool isLiked)?
        onFollowClicked,
    Future<bool> Function(TimeLineData? postData, bool isSaved)? onSaveClicked,
    Function(TimeLineData postData)? onShareClicked,
    Function(TimeLineData postData)? onCommentClick,
    Function(TimeLineData? postData, String userId, bool? isFollowing)?
        onProfileClick,
    Future<void> Function(TimeLineData postData)? onTagProductClick,
    Function(TimeLineData postData, int index)? onPostChanged,
  }) =>
      PostCallBackConfig(
        onSaveChanged: onSaveChanged ?? this.onSaveChanged,
        onLikeChanged: onLikeChanged ?? this.onLikeChanged,
        onSaveClicked: onSaveClicked ?? this.onSaveClicked,
        onShareClicked: onShareClicked ?? this.onShareClicked,
        onLikeClick: onLikeClick ?? this.onLikeClick,
        onCommentClick: onCommentClick ?? this.onCommentClick,
        onProfileClick: onProfileClick ?? this.onProfileClick,
        onTagProductClick: onTagProductClick ?? this.onTagProductClick,
        onPostChanged: onPostChanged ?? this.onPostChanged,
      );
}
