import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class PostConfig {
  const PostConfig({
    this.postUIConfig,
    this.postCallBackConfig,
    this.postFeedUIConfig,
    this.autoMoveToNextMedia = true,
    this.autoMoveToNextPost = true,
    this.isCaptionRequired = false,
    this.showViewCount = false,
    this.enableDubWithAudio = false,
    this.dubWithAudioConfig,
    this.canDownload = false,
    this.downloadWatermark,
    this.enablePlaybackSpeed = false,
    this.enableVideoProgressBar = false,
  });

  final PostUIConfig? postUIConfig;
  final PostCallBackConfig? postCallBackConfig;

  /// Styling for scrollable post-card tabs ([FeedLayoutType.postFeed] on [TabDataModel]).
  final PostFeedUIConfig? postFeedUIConfig;

  final bool autoMoveToNextMedia;
  final bool autoMoveToNextPost;
  final bool isCaptionRequired;
  final bool showViewCount;

  final bool enableDubWithAudio;
  final DubWithAudioConfig? dubWithAudioConfig;

  /// When true, viewers can download reels from the more-options sheet when
  /// `settings.download_enabled` is true (API default: true).
  final bool canDownload;

  /// Optional host watermark applied to downloaded images and videos.
  final ReelDownloadWatermarkConfig? downloadWatermark;

  /// When true, viewers can change video playback speed (YouTube-style:
  /// 0.5x–2x). Defaults to false so host apps opt in explicitly.
  final bool enablePlaybackSpeed;

  /// When true, reels show a YouTube-style progress bar with start/end times
  /// and scrubbing (tap or drag). Defaults to false so host apps opt in.
  final bool enableVideoProgressBar;

  /// UI config for post-card tabs. Defaults to [PostFeedUIConfig.instagram] when null.
  PostFeedUIConfig get resolvedPostFeedUIConfig =>
      postFeedUIConfig ?? PostFeedUIConfig.instagram;

  PostConfig copyWith({
    PostUIConfig? postUIConfig,
    PostCallBackConfig? postCallBackConfig,
    PostFeedUIConfig? postFeedUIConfig,
    bool? autoMoveToNextMedia,
    bool? autoMoveToNextPost,
    bool? isCaptionRequired,
    bool? showViewCount,
    bool? enableDubWithAudio,
    DubWithAudioConfig? dubWithAudioConfig,
    bool? canDownload,
    ReelDownloadWatermarkConfig? downloadWatermark,
    bool? enablePlaybackSpeed,
    bool? enableVideoProgressBar,
  }) =>
      PostConfig(
        postUIConfig: postUIConfig ?? this.postUIConfig,
        postCallBackConfig: postCallBackConfig ?? this.postCallBackConfig,
        postFeedUIConfig: postFeedUIConfig ?? this.postFeedUIConfig,
        autoMoveToNextMedia: autoMoveToNextMedia ?? this.autoMoveToNextMedia,
        autoMoveToNextPost: autoMoveToNextPost ?? this.autoMoveToNextPost,
        isCaptionRequired: isCaptionRequired ?? this.isCaptionRequired,
        showViewCount: showViewCount ?? this.showViewCount,
        enableDubWithAudio: enableDubWithAudio ?? this.enableDubWithAudio,
        dubWithAudioConfig: dubWithAudioConfig ?? this.dubWithAudioConfig,
        canDownload: canDownload ?? this.canDownload,
        downloadWatermark: downloadWatermark ?? this.downloadWatermark,
        enablePlaybackSpeed:
            enablePlaybackSpeed ?? this.enablePlaybackSpeed,
        enableVideoProgressBar:
            enableVideoProgressBar ?? this.enableVideoProgressBar,
      );
}

/// Builds the action row for scrollable post-card feed tabs.
typedef PostFeedActionWidgetBuilder = Widget Function(
  ReelsData reelsData,
  PostFeedActionBuildContext actionContext,
);

/// Context passed to [PostFeedActionWidgetBuilder] for custom action UIs.
class PostFeedActionBuildContext {
  const PostFeedActionBuildContext({
    required this.currentMediaIndex,
    required this.mediaCount,
    required this.postSectionType,
  });

  final int currentMediaIndex;
  final int mediaCount;
  final PostSectionType postSectionType;
}

/// Post card layout for scrollable post-card feed tabs.
enum PostFeedCardStyle {
  /// Profile row and follow button overlaid on media with a top gradient.
  overlayHeader,

  /// Classic feed: header above media, carousel dots under media, compact follow chip.
  instagram,
}

/// UI tokens for the scrollable post-card feed layout.
class PostFeedUIConfig {
  const PostFeedUIConfig({
    this.title,
    this.titleTextStyle,
    this.actionWidget,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.dividerColor = const Color(0xFFEFEFEF),
    this.headerTextColor = const Color(0xFF262626),
    this.secondaryTextColor = const Color(0xFF8E8E8E),
    this.actionIconColor = const Color(0xFF262626),
    this.mediaAspectRatio = 1.0,
    this.mediaFrameHeight,
    this.mediaFrameWidth,
    this.showCarouselPageBadge = true,
    this.showCarouselDots = true,
    this.postSpacing = 12.0,
    this.showHeader = true,
    this.defaultVideoMuted = false,
    this.enableVideoTapControls = true,
    this.cardStyle = PostFeedCardStyle.overlayHeader,
    this.showActionCounts = false,
    this.showPostTimestamp = false,
    this.showPostDividers = false,
    this.headerSubtitle,
    this.videoMediaAspectRatio = 3 / 4,
    this.imageMediaAspectRatio = 3 / 4,
    this.landscapeMediaAspectRatio = 1.91,
    this.actionIconGapCompact = 10,
    this.actionIconGapWithCount = 16,
  });

  /// Instagram-style post feed: header above media, counts, timestamps, dividers.
  ///
  /// Default styling for post-card feed tabs when [PostConfig.postFeedUIConfig] is null.
  static const instagram = PostFeedUIConfig(
    cardStyle: PostFeedCardStyle.instagram,
    showHeader: false,
    showActionCounts: true,
    showPostTimestamp: true,
    showPostDividers: true,
    postSpacing: 0,
  );

  /// Header title for post-card feed tabs. Falls back to the active tab title when null or empty.
  final String? title;

  /// Optional override for the header title text style.
  final TextStyle? titleTextStyle;

  /// Custom action row below media. When null, SDK default actions are shown.
  final PostFeedActionWidgetBuilder? actionWidget;

  final Color backgroundColor;
  final Color dividerColor;
  final Color headerTextColor;
  final Color secondaryTextColor;
  final Color actionIconColor;
  final double mediaAspectRatio;

  /// When set, all post media (image/video) uses a fixed-height frame.
  /// This keeps every post visually consistent regardless of media dimensions.
  final double? mediaFrameHeight;

  /// Optional fixed width. When null, media spans the full available width (edge to edge).
  final double? mediaFrameWidth;

  final bool showCarouselPageBadge;
  final bool showCarouselDots;
  final double postSpacing;

  /// When false, the post-feed header row is hidden.
  final bool showHeader;

  /// When true, videos start muted (sound off). Defaults to false (sound on).
  final bool defaultVideoMuted;

  /// When true, tap toggles play/pause and a mute control is shown on video.
  final bool enableVideoTapControls;

  /// [PostFeedCardStyle.instagram] places the user row above media (Instagram-style).
  final PostFeedCardStyle cardStyle;

  /// Shows like/comment counts beside action icons (common with [PostFeedCardStyle.instagram]).
  final bool showActionCounts;

  /// Shows relative publish time under the caption (e.g. "2 days ago").
  final bool showPostTimestamp;

  /// Thin dividers between posts instead of only [postSpacing] gaps.
  final bool showPostDividers;

  /// Optional subtitle under the username in the post header (e.g. "Suggested for you").
  final String? headerSubtitle;

  /// Aspect ratio (width / height) for video media in [PostFeedCardStyle.instagram] (default 3:4).
  final double videoMediaAspectRatio;

  /// Aspect ratio (width / height) for image media in [PostFeedCardStyle.instagram] (default 3:4).
  /// Taller than 1:1 so portrait photos are not heavily cropped like a square frame.
  final double imageMediaAspectRatio;

  /// Aspect ratio (width / height) for landscape images (Instagram-style wide frame).
  final double landscapeMediaAspectRatio;

  /// Horizontal gap between action icons when neither adjacent action shows a count.
  final double actionIconGapCompact;

  /// Horizontal gap between action icons when at least one adjacent action shows a count.
  final double actionIconGapWithCount;
}


class PostUIConfig {
  const PostUIConfig({
    this.overlayPadding,
    this.actionIconConfig,
    this.textStyleConfig,
    this.shopUIConfig,
    this.postLinkUIConfig,
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
  final PostLinkUIConfig? postLinkUIConfig;
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
    PostLinkUIConfig? postLinkUIConfig,
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
        postLinkUIConfig: postLinkUIConfig ?? this.postLinkUIConfig,
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
    this.urlStyle,
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

  /// Style for URL links in post description text
  final TextStyle? urlStyle;

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
    TextStyle? urlStyle,
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
        urlStyle: urlStyle ?? this.urlStyle,
        mediaCounterStyle: mediaCounterStyle ?? this.mediaCounterStyle,
        shopTitleStyle: shopTitleStyle ?? this.shopTitleStyle,
        shopSubtitleStyle: shopSubtitleStyle ?? this.shopSubtitleStyle,
        commissionTagStyle: commissionTagStyle ?? this.commissionTagStyle,
        followButtonTextStyle: followButtonTextStyle ?? this.followButtonTextStyle,
        followingButtonTextStyle: followingButtonTextStyle ?? this.followingButtonTextStyle,
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
        shopContainerDecoration: shopContainerDecoration ?? this.shopContainerDecoration,
        shopContainerPadding: shopContainerPadding ?? this.shopContainerPadding,
        shopIconSize: shopIconSize ?? this.shopIconSize,
        shopIconColor: shopIconColor ?? this.shopIconColor,
      );
}

/// CTA chip for `tags.links` on reels (Instagram-style).
class PostLinkUIConfig {
  const PostLinkUIConfig({
    this.containerDecoration,
    this.containerPadding,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.textStyle,
  });

  final BoxDecoration? containerDecoration;
  final EdgeInsetsGeometry? containerPadding;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? textStyle;

  PostLinkUIConfig copyWith({
    BoxDecoration? containerDecoration,
    EdgeInsetsGeometry? containerPadding,
    IconData? icon,
    double? iconSize,
    Color? iconColor,
    TextStyle? textStyle,
  }) =>
      PostLinkUIConfig(
        containerDecoration:
            containerDecoration ?? this.containerDecoration,
        containerPadding: containerPadding ?? this.containerPadding,
        icon: icon ?? this.icon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        textStyle: textStyle ?? this.textStyle,
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
        followButtonDecoration: followButtonDecoration ?? this.followButtonDecoration,
        followingButtonDecoration: followingButtonDecoration ?? this.followingButtonDecoration,
        followButtonPadding: followButtonPadding ?? this.followButtonPadding,
        followButtonHeight: followButtonHeight ?? this.followButtonHeight,
        followButtonMinWidth: followButtonMinWidth ?? this.followButtonMinWidth,
        loadingIndicatorColor: loadingIndicatorColor ?? this.loadingIndicatorColor,
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
        indicatorBorderRadius: indicatorBorderRadius ?? this.indicatorBorderRadius,
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
        profileImageBorderRadius: profileImageBorderRadius ?? this.profileImageBorderRadius,
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
    this.lessText,
    this.moreText,
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

  /// Text for 'less'
  final String? lessText;

  /// Text for 'more'
  final String? moreText;

  DescriptionConfig copyWith({
    int? maxLengthToShow,
    int? maxLinesToShow,
    TextStyle? expandTextStyle,
    TextStyle? collapseTextStyle,
    List<Shadow>? textShadows,
    String? lessText,
    String? moreText,
  }) =>
      DescriptionConfig(
        maxLengthToShow: maxLengthToShow ?? this.maxLengthToShow,
        maxLinesToShow: maxLinesToShow ?? this.maxLinesToShow,
        expandTextStyle: expandTextStyle ?? this.expandTextStyle,
        collapseTextStyle: collapseTextStyle ?? this.collapseTextStyle,
        textShadows: textShadows ?? this.textShadows,
        lessText: lessText ?? this.lessText,
        moreText: moreText ?? this.moreText,
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
    this.onPostLinkClick,
    this.onPostChanged,
    this.onLikeCountClicked,
    this.onViewCountClicked,
    this.onPaidPostUnlock,
    this.onDubWithAudio,
    this.onUseThisSound,
  });

  final Function(TimeLineData postData, bool isSaved)? onSaveChanged;
  final Function(TimeLineData postData, bool isLiked)? onLikeChanged;
  // return true if success
  final Future<bool> Function(TimeLineData? postData, bool isSaved)? onSaveClicked;
  final Future<bool> Function(TimeLineData? postData, bool isLiked)? onLikeClick;
  final Future<bool> Function(TimeLineData? postData, bool isFollow)? onFollowClick;

  final Future<OnShareRequest?> Function(TimeLineData postData)? onShareClicked;
  final Function(TimeLineData postData)? onCommentClick;
  final Function(TimeLineData? postData, String userId, bool? isFollowing)? onProfileClick;
  final Future<void> Function(TimeLineData postData)? onTagProductClick;
  final Future<void> Function(TimeLineData postData, PostLinkData link)?
      onPostLinkClick;
  final Function(TimeLineData postData, int index)? onPostChanged;
  final Future<void> Function(TimeLineData postData)? onLikeCountClicked;
  final Future<void> Function(TimeLineData postData)? onViewCountClicked;

  /// Host app handles purchase / coin flow when the user taps unlock on a paid post.
  final Future<void> Function(TimeLineData postData)? onPaidPostUnlock;

  final Future<void> Function(TimeLineData postData)? onDubWithAudio;

  /// Tapped the audio pill on a post; lets the host app open create-post with
  /// the sound preselected. When null the SDK falls back to a built-in flow
  /// (camera + media edit with the sound preselected).
  final Future<void> Function(TimeLineData postData, PostSoundInfo sound)?
      onUseThisSound;

  PostCallBackConfig copyWith({
    Function(TimeLineData postData, bool isSaved)? onSaveChanged,
    Function(TimeLineData postData, bool isLiked)? onLikeChanged,
    Future<bool> Function(TimeLineData? postData, bool isLiked)? onLikeClick,
    Future<bool> Function(TimeLineData? postData, bool isFollow)? onFollowClick,
    Future<bool> Function(TimeLineData? postData, bool isSaved)? onSaveClicked,
    Future<OnShareRequest?> Function(TimeLineData postData)? onShareClicked,
    Function(TimeLineData postData)? onCommentClick,
    Function(TimeLineData? postData, String userId, bool? isFollowing)? onProfileClick,
    Future<void> Function(TimeLineData postData)? onTagProductClick,
    Future<void> Function(TimeLineData postData, PostLinkData link)?
        onPostLinkClick,
    Function(TimeLineData postData, int index)? onPostChanged,
    Future<void> Function(TimeLineData postData)? onLikeCountClicked,
    Future<void> Function(TimeLineData postData)? onViewCountClicked,
    Future<void> Function(TimeLineData postData)? onPaidPostUnlock,
    Future<void> Function(TimeLineData postData)? onDubWithAudio,
    Future<void> Function(TimeLineData postData, PostSoundInfo sound)?
        onUseThisSound,
  }) =>
      PostCallBackConfig(
        onSaveChanged: onSaveChanged ?? this.onSaveChanged,
        onLikeChanged: onLikeChanged ?? this.onLikeChanged,
        onSaveClicked: onSaveClicked ?? this.onSaveClicked,
        onFollowClick: onFollowClick ?? this.onFollowClick,
        onShareClicked: onShareClicked ?? this.onShareClicked,
        onLikeClick: onLikeClick ?? this.onLikeClick,
        onCommentClick: onCommentClick ?? this.onCommentClick,
        onProfileClick: onProfileClick ?? this.onProfileClick,
        onTagProductClick: onTagProductClick ?? this.onTagProductClick,
        onPostLinkClick: onPostLinkClick ?? this.onPostLinkClick,
        onPostChanged: onPostChanged ?? this.onPostChanged,
        onLikeCountClicked: onLikeCountClicked ?? this.onLikeCountClicked,
        onViewCountClicked: onViewCountClicked ?? this.onViewCountClicked,
        onPaidPostUnlock: onPaidPostUnlock ?? this.onPaidPostUnlock,
        onDubWithAudio: onDubWithAudio ?? this.onDubWithAudio,
        onUseThisSound: onUseThisSound ?? this.onUseThisSound,
      );
}
